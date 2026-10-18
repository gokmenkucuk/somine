using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SomineApi.Infrastructure.Data;

namespace SomineApi.WebApi.Maintenance;

public sealed class LogRetentionOptions
{
    public const string SectionName = "LogRetention";

    public bool Enabled { get; set; } = true;

    /// <summary>
    /// IP ve cihaz bilgisi taşıyan kayıtların (istek/hata logları, kapanmış oturumlar)
    /// saklanma süresi. Gizlilik politikası 30 gün diyor; değiştirirsen politikayı da güncelle.
    /// </summary>
    public int RetentionDays { get; set; } = 30;

    public TimeSpan Interval { get; set; } = TimeSpan.FromHours(6);

    public int BatchSize { get; set; } = 5000;
}

/// <summary>
/// Saklama süresi dolan istek/hata loglarını ve süresi dolmuş ya da iptal edilmiş oturumları
/// siler. Büyük tabloları kilitlememek için küçük partiler halinde çalışır.
/// </summary>
public sealed class LogRetentionService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IOptions<LogRetentionOptions> _options;
    private readonly TimeProvider _timeProvider;
    private readonly ILogger<LogRetentionService> _logger;

    public LogRetentionService(
        IServiceScopeFactory scopeFactory,
        IOptions<LogRetentionOptions> options,
        TimeProvider timeProvider,
        ILogger<LogRetentionService> logger)
    {
        _scopeFactory = scopeFactory;
        _options = options;
        _timeProvider = timeProvider;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!_options.Value.Enabled) return;

        // Açılışı yavaşlatmamak için ilk temizlik biraz sonra.
        await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await RunOnceAsync(stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                return;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Log retention run failed.");
            }

            await Task.Delay(_options.Value.Interval, stoppingToken);
        }
    }

    public async Task<(int Requests, int Exceptions, int Sessions)> RunOnceAsync(CancellationToken cancellationToken)
    {
        var options = _options.Value;
        var cutoff = _timeProvider.GetUtcNow().UtcDateTime.AddDays(-options.RetentionDays);
        using var scope = _scopeFactory.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();

        var exceptions = await DeleteInBatchesAsync(
            () => db.ExceptionLogs.Where(e => e.CreatedAt < cutoff).Select(e => e.Id),
            ids => db.ExceptionLogs.Where(e => ids.Contains(e.Id)).ExecuteDeleteAsync(cancellationToken),
            options.BatchSize, cancellationToken);

        // Hâlâ bir hata kaydının işaret ettiği istek logu silinmez (FK).
        var requests = await DeleteInBatchesAsync(
            () => db.RequestLogs
                .Where(r => r.CreatedAt < cutoff && !db.ExceptionLogs.Any(e => e.RequestLogId == r.Id))
                .Select(r => r.Id),
            ids => db.RequestLogs.Where(r => ids.Contains(r.Id)).ExecuteDeleteAsync(cancellationToken),
            options.BatchSize, cancellationToken);

        var sessions = await DeleteInBatchesAsync(
            () => db.AuthSessions
                .Where(s => (s.RevokedAt != null && s.RevokedAt < cutoff) || s.ExpiresAt < cutoff)
                .Select(s => s.Id),
            ids => db.AuthSessions.Where(s => ids.Contains(s.Id)).ExecuteDeleteAsync(cancellationToken),
            options.BatchSize, cancellationToken);

        if (requests + exceptions + sessions > 0)
        {
            _logger.LogInformation(
                "Log retention removed {Requests} request logs, {Exceptions} exception logs and {Sessions} closed sessions older than {Days} days.",
                requests, exceptions, sessions, options.RetentionDays);
        }

        return (requests, exceptions, sessions);
    }

    private static async Task<int> DeleteInBatchesAsync(
        Func<IQueryable<Guid>> idsQuery,
        Func<List<Guid>, Task<int>> deleteBatch,
        int batchSize,
        CancellationToken cancellationToken)
    {
        var total = 0;
        while (true)
        {
            var ids = await idsQuery().Take(batchSize).ToListAsync(cancellationToken);
            if (ids.Count == 0) return total;
            total += await deleteBatch(ids);
            if (ids.Count < batchSize) return total;
        }
    }
}
