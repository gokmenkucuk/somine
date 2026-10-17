using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Options;

namespace SomineApi.WebApi.Moderation;

/// <summary>
/// Kuyruktaki her yeni şikâyet için moderatöre (<see cref="ModerationOptions.ReportEmail"/>) bir e-posta yollar:
/// kim kimi neden şikâyet etti, koleksiyondaki linkler ve inceleme sonrası çalıştırılacak SQL.
/// App Store 1.2 şikâyetlere 24 saat içinde bakılmasını istiyor; uyarı bunun için.
/// </summary>
public sealed class ReportAlertBackgroundService : BackgroundService
{
    // E-postayı okunur tutmak için koleksiyondan en fazla bu kadar içerik listelenir.
    internal const int MaxListedItems = 30;

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IReportAlertQueue _queue;
    private readonly IReportAlertSender _sender;
    private readonly IOptions<ModerationOptions> _options;
    private readonly ILogger<ReportAlertBackgroundService> _logger;

    public ReportAlertBackgroundService(
        IServiceScopeFactory scopeFactory,
        IReportAlertQueue queue,
        IReportAlertSender sender,
        IOptions<ModerationOptions> options,
        ILogger<ReportAlertBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _queue = queue;
        _sender = sender;
        _options = options;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (await _queue.WaitToReadAsync(stoppingToken))
        {
            while (_queue.TryRead(out var reportId))
            {
                if (!_options.Value.IsConfigured)
                {
                    _logger.LogWarning("Moderation email is not configured; alert for report {ReportId} was not sent.", reportId);
                    continue;
                }

                try
                {
                    var email = await BuildEmailAsync(reportId, stoppingToken);
                    if (email != null)
                    {
                        await _sender.SendAsync(email, stoppingToken);
                    }
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    throw;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to send email alert for report {ReportId}.", reportId);
                }
            }
        }
    }

    private async Task<ReportAlertEmail?> BuildEmailAsync(Guid reportId, CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();

        var report = await dbContext.ContentReports
            .AsNoTracking()
            .Where(r => r.Id == reportId)
            .Select(r => new
            {
                r.Id,
                r.ShareId,
                r.CategoryId,
                r.Reason,
                r.Note,
                r.CreatedAt,
                Reporter = new { r.Reporter.Id, r.Reporter.Username, r.Reporter.DisplayName, r.Reporter.Email },
                Reported = new { r.ReportedUser.Id, r.ReportedUser.Username, r.ReportedUser.DisplayName, r.ReportedUser.Email }
            })
            .FirstOrDefaultAsync(cancellationToken);

        if (report == null)
        {
            return null;
        }

        var categoryName = report.CategoryId == null
            ? null
            : await dbContext.Categories
                .AsNoTracking()
                .Where(c => c.Id == report.CategoryId)
                .Select(c => c.Name)
                .FirstOrDefaultAsync(cancellationToken);

        var items = report.CategoryId == null
            ? []
            : await dbContext.Items
                .AsNoTracking()
                .Where(i => i.CategoryId == report.CategoryId)
                .OrderByDescending(i => i.CreatedAt)
                .Take(MaxListedItems + 1)
                .Select(i => new { i.OgTitle, i.Url, i.Note })
                .ToListAsync(cancellationToken);

        var previousReports = await dbContext.ContentReports
            .AsNoTracking()
            .CountAsync(r => r.ReportedUserId == report.Reported.Id && r.Id != report.Id, cancellationToken);

        static string Person(Guid id, string? username, string? displayName, string? email)
        {
            var name = string.Join(" ", new[] { displayName, username == null ? null : "@" + username }
                .Where(part => !string.IsNullOrWhiteSpace(part)));
            return $"{(name.Length == 0 ? "(adsız)" : name)} <{email ?? "e-posta yok"}> · {id}";
        }

        var text = new StringBuilder();
        text.AppendLine("SoMine'da yeni bir içerik şikâyeti var. App Store kuralı gereği 24 saat içinde incelenmeli.");
        text.AppendLine();
        text.AppendLine($"Sebep:          {ReasonLabel(report.Reason)}");
        if (!string.IsNullOrWhiteSpace(report.Note))
        {
            text.AppendLine($"Not:            {report.Note}");
        }

        text.AppendLine($"Tarih (UTC):    {report.CreatedAt:yyyy-MM-dd HH:mm}");
        text.AppendLine($"Şikâyet eden:   {Person(report.Reporter.Id, report.Reporter.Username, report.Reporter.DisplayName, report.Reporter.Email)}");
        text.AppendLine($"Şikâyet edilen: {Person(report.Reported.Id, report.Reported.Username, report.Reported.DisplayName, report.Reported.Email)}");
        text.AppendLine($"Bu kişi hakkında önceki şikâyet sayısı: {previousReports}");
        text.AppendLine($"Koleksiyon:     {categoryName ?? "(silinmiş)"}");
        text.AppendLine();

        if (items.Count == 0)
        {
            text.AppendLine("Koleksiyonda içerik yok ya da koleksiyon silinmiş.");
        }
        else
        {
            text.AppendLine("Koleksiyondaki içerikler (en yeniler):");
            foreach (var item in items.Take(MaxListedItems))
            {
                var title = string.IsNullOrWhiteSpace(item.OgTitle) ? null : item.OgTitle.Trim();
                var body = item.Url ?? (string.IsNullOrWhiteSpace(item.Note) ? "(boş)" : Shorten(item.Note.Trim(), 200));
                text.AppendLine(title == null ? $"- {body}" : $"- {Shorten(title, 120)}\n  {body}");
            }

            if (items.Count > MaxListedItems)
            {
                text.AppendLine("- … ve daha fazlası");
            }
        }

        text.AppendLine();
        text.AppendLine("Şikâyet eden kişi göndereni engellemiş olabilir; paylaşım onun kitaplığından zaten kalkmış olabilir.");
        text.AppendLine();
        text.AppendLine("İnceleme sonrası (prod veritabanında):");
        if (report.ShareId != null)
        {
            text.AppendLine("  -- İçerik uygunsuzsa paylaşımı kaldır:");
            text.AppendLine($"  UPDATE collection_shares SET status = 'Rejected', rejected_at = NOW() WHERE id = '{report.ShareId}';");
        }

        text.AppendLine("  -- Şikâyeti kapat ('ActionTaken', 'Dismissed' ya da 'Reviewed'):");
        text.AppendLine($"  UPDATE content_reports SET status = 'ActionTaken' WHERE id = '{report.Id}';");
        text.AppendLine();
        text.AppendLine($"Şikâyet kimliği: {report.Id}");

        var subject = $"[SoMine Şikayet] {ReasonLabel(report.Reason)}: {report.Reported.Username ?? report.Reported.DisplayName ?? "kullanıcı"}";
        return new ReportAlertEmail(_options.Value.ReportEmail, subject, text.ToString());
    }

    private static string ReasonLabel(ReportReason reason) => reason switch
    {
        ReportReason.Spam => "Spam",
        ReportReason.Inappropriate => "Uygunsuz içerik",
        ReportReason.Harassment => "Taciz",
        _ => "Diğer"
    };

    private static string Shorten(string value, int max) => value.Length <= max ? value : value[..max] + "…";
}
