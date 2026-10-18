using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Domain.Notifications;
using SomineApi.Domain.Reminders;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Hubs;
using SomineApi.WebApi.Options;

namespace SomineApi.WebApi.Reminders;

/// <summary>
/// Vakti gelen hatırlatıcılar için <c>notifications</c> tablosuna kayıt düşer ve SignalR ile yayınlar.
/// </summary>
/// <remarks>
/// Mobildeki yerel bildirim (OS banner'ı) yerine geçmez, onu tamamlar: banner kaçırılsa bile
/// hatırlatıcı uygulama içi bildirim listesinde iz bırakır.
/// </remarks>
public sealed class ReminderNotificationBackgroundService : BackgroundService
{
    private static readonly JsonSerializerOptions DataSerializerOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    private const int MaxTitleLength = 200;

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IUserRealtimeEventPublisher _realtimeEventPublisher;
    private readonly IOptions<ReminderNotificationOptions> _options;
    private readonly TimeProvider _timeProvider;
    private readonly ILogger<ReminderNotificationBackgroundService> _logger;

    public ReminderNotificationBackgroundService(
        IServiceScopeFactory scopeFactory,
        IUserRealtimeEventPublisher realtimeEventPublisher,
        IOptions<ReminderNotificationOptions> options,
        TimeProvider timeProvider,
        ILogger<ReminderNotificationBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _realtimeEventPublisher = realtimeEventPublisher;
        _options = options;
        _timeProvider = timeProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var options = _options.Value;

        if (!options.Enabled)
        {
            _logger.LogInformation("Reminder notifications are disabled; background sweep will not run.");
            return;
        }

        _logger.LogInformation(
            "Reminder notification sweep started. PollInterval={PollInterval} CatchUpWindow={CatchUpWindow} DefaultTimeZone={DefaultTimeZone}",
            options.EffectivePollInterval, options.EffectiveCatchUpWindow, options.DefaultTimeZoneId);

        using var timer = new PeriodicTimer(options.EffectivePollInterval, _timeProvider);

        while (await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                await RunOnceAsync(_timeProvider.GetUtcNow(), stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Reminder notification sweep failed.");
            }
        }
    }

    /// <summary>
    /// Tek bir tarama turu. Doğrudan çağrılabilir (test edilebilirlik için public).
    /// </summary>
    /// <returns>Üretilen bildirim sayısı.</returns>
    public async Task<int> RunOnceAsync(DateTimeOffset nowUtc, CancellationToken cancellationToken = default)
    {
        var options = _options.Value;
        using var scope = _scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();

        var candidates = await LoadCandidatesAsync(dbContext, options, nowUtc, cancellationToken);
        if (candidates.Count == 0) return 0;

        var published = new List<(Guid UserId, Guid NotificationId)>();
        var catchUpWindow = options.EffectiveCatchUpWindow;
        var now = nowUtc.UtcDateTime;

        foreach (var candidate in candidates)
        {
            cancellationToken.ThrowIfCancellationRequested();

            var timeZone = ReminderTimeZones.Resolve(candidate.TimeZoneId, options.DefaultTimeZoneId);
            var schedule = new ReminderSchedule(
                candidate.ReminderDate,
                candidate.ReminderHour,
                candidate.ReminderMinute,
                candidate.RepeatType,
                candidate.CustomRepeatDays,
                candidate.CustomRepeatMinutes);

            var due = ReminderScheduleCalculator.GetDueOccurrenceUtc(schedule, nowUtc, timeZone);
            if (due is null) continue;

            var dueUtc = due.Value.UtcDateTime;

            // Çok eski (ıskalanmış) tetiklemeler için bildirim üretme.
            if (dueUtc < now - catchUpWindow) continue;

            var lastTriggered = candidate.LastTriggered.HasValue
                ? DateTime.SpecifyKind(candidate.LastTriggered.Value, DateTimeKind.Utc)
                : (DateTime?)null;

            if (lastTriggered.HasValue && lastTriggered.Value >= dueUtc) continue;

            var notificationId = await TryTriggerAsync(dbContext, candidate, dueUtc, now, cancellationToken);
            if (notificationId.HasValue)
            {
                published.Add((candidate.UserId, notificationId.Value));
            }
        }

        foreach (var (userId, notificationId) in published)
        {
            try
            {
                await _realtimeEventPublisher.PublishNotificationsChangedAsync(userId, "created", notificationId, cancellationToken);
            }
            catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
            {
                throw;
            }
            catch (Exception ex)
            {
                // Bildirim kalıcı olarak yazıldı; yalnız canlı yayın başarısız oldu.
                _logger.LogWarning(ex, "Failed to publish reminder notification event. NotificationId={NotificationId}", notificationId);
            }
        }

        if (published.Count > 0)
        {
            _logger.LogInformation("Created {Count} reminder notification(s).", published.Count);
        }

        return published.Count;
    }

    private static async Task<List<ReminderCandidate>> LoadCandidatesAsync(
        SomineDbContext dbContext,
        ReminderNotificationOptions options,
        DateTimeOffset nowUtc,
        CancellationToken cancellationToken)
    {
        // Zaman dilimi farkı azami ±14 saat olabildiği için tarih sınırlarını bir gün geniş tutuyoruz.
        var maxDate = DateOnly.FromDateTime(nowUtc.UtcDateTime.AddDays(1));
        var minDate = DateOnly.FromDateTime(nowUtc.UtcDateTime.AddDays(-1) - options.EffectiveCatchUpWindow);

        // Items üzerindeki global query filter (soft-delete) sayesinde silinmiş içeriklerin
        // hatırlatıcıları kendiliğinden elenir.
        var query =
            from reminder in dbContext.Reminders.AsNoTracking()
            join item in dbContext.Items on reminder.ItemId equals item.Id
            join user in dbContext.Users on item.UserId equals user.Id
            where reminder.IsActive
                && reminder.ReminderDate <= maxDate
                && (reminder.RepeatType != RepeatFrequency.None
                    || (reminder.LastTriggered == null && reminder.ReminderDate >= minDate))
            orderby reminder.ReminderDate
            select new ReminderCandidate(
                reminder.Id,
                reminder.ItemId,
                item.UserId,
                user.TimeZoneId,
                reminder.ReminderDate,
                reminder.ReminderHour,
                reminder.ReminderMinute,
                reminder.RepeatType,
                reminder.CustomRepeatDays,
                reminder.CustomRepeatMinutes,
                reminder.LastTriggered,
                item.OgTitle,
                item.Note,
                item.Url);

        return await query.Take(options.EffectiveBatchSize).ToListAsync(cancellationToken);
    }

    /// <summary>
    /// Hatırlatıcıyı tek bir işlem (transaction) içinde sahiplenir ve bildirimi yazar.
    /// Sahiplenme <c>ExecuteUpdateAsync</c> ile koşullu yapıldığı için aynı slot için ikinci bir
    /// bildirim üretilemez (birden çok instance çalışsa bile).
    /// </summary>
    private async Task<Guid?> TryTriggerAsync(
        SomineDbContext dbContext,
        ReminderCandidate candidate,
        DateTime dueUtc,
        DateTime nowUtc,
        CancellationToken cancellationToken)
    {
        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        var claimed = await dbContext.Reminders
            .Where(r => r.Id == candidate.ReminderId
                && r.IsActive
                && (r.LastTriggered == null || r.LastTriggered < dueUtc))
            .ExecuteUpdateAsync(setters => setters.SetProperty(r => r.LastTriggered, nowUtc), cancellationToken);

        if (claimed == 0)
        {
            await transaction.RollbackAsync(cancellationToken);
            return null;
        }

        var title = BuildNotificationTitle(candidate.OgTitle, candidate.Note, candidate.Url);
        var payload = JsonSerializer.Serialize(
            new ReminderNotificationData(candidate.ItemId, candidate.ReminderId, dueUtc),
            DataSerializerOptions);

        var notification = new Notification
        {
            Id = Guid.NewGuid(),
            UserId = candidate.UserId,
            Type = NotificationTypes.Reminder,
            Title = title,
            Message = "Kaydettiğin bu içerik için kurduğun hatırlatıcının vakti geldi.",
            Data = JsonDocument.Parse(payload),
            IsRead = false,
            CreatedAt = nowUtc
        };

        dbContext.Notifications.Add(notification);
        await dbContext.SaveChangesAsync(cancellationToken);
        await transaction.CommitAsync(cancellationToken);

        return notification.Id;
    }

    /// <summary>
    /// Bildirim başlığı: OG başlığı → not → URL sırasıyla ilk dolu olanın ilk satırı.
    /// </summary>
    public static string BuildNotificationTitle(string? ogTitle, string? note, string? url)
    {
        foreach (var source in new[] { ogTitle, note, url })
        {
            if (string.IsNullOrWhiteSpace(source)) continue;

            var firstLine = source
                .ReplaceLineEndings("\n")
                .Split('\n', StringSplitOptions.RemoveEmptyEntries)
                .FirstOrDefault(line => !string.IsNullOrWhiteSpace(line))
                ?.Trim();

            if (string.IsNullOrEmpty(firstLine)) continue;

            return firstLine.Length <= MaxTitleLength
                ? firstLine
                : string.Concat(firstLine.AsSpan(0, MaxTitleLength - 1).TrimEnd(), "…");
        }

        return "Hatırlatıcı";
    }

    /// <summary>Mobil istemcinin bildirimden içeriğe gidebilmesi için taşınan yük.</summary>
    private sealed record ReminderNotificationData(Guid ItemId, Guid ReminderId, DateTime TriggeredForUtc);

    private sealed record ReminderCandidate(
        Guid ReminderId,
        Guid ItemId,
        Guid UserId,
        string? TimeZoneId,
        DateOnly ReminderDate,
        int ReminderHour,
        int ReminderMinute,
        RepeatFrequency RepeatType,
        int? CustomRepeatDays,
        int? CustomRepeatMinutes,
        DateTime? LastTriggered,
        string? OgTitle,
        string? Note,
        string? Url);
}
