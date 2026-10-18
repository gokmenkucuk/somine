using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
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

        var model = new ReportAlertModel(
            report.Id,
            report.Reason,
            report.Note,
            report.CreatedAt,
            new ReportAlertPerson(report.Reporter.Id, report.Reporter.DisplayName, report.Reporter.Username, report.Reporter.Email),
            new ReportAlertPerson(report.Reported.Id, report.Reported.DisplayName, report.Reported.Username, report.Reported.Email),
            previousReports,
            categoryName,
            items.Take(MaxListedItems).Select(i => new ReportAlertItem(i.OgTitle, i.Url, i.Note)).ToList(),
            items.Count > MaxListedItems,
            report.ShareId);

        return new ReportAlertEmail(
            _options.Value.ReportEmail,
            ReportAlertEmailTemplate.Subject(model),
            ReportAlertEmailTemplate.Text(model),
            ReportAlertEmailTemplate.Html(model));
    }
}
