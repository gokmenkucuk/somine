using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SomineApi.Infrastructure.Data;

namespace SomineApi.WebApi.ImageCache;

/// <summary>
/// Mevcut item'ların harici OG görsellerini sunucuya kopyalar (en yeniden eskiye, küçük partiler).
/// <c>ImageCache:BackfillOnStartup=true</c> ile açılışta bir kez çalışır. Tekrar çalışması güvenlidir:
/// kopyalanmış (og_image_source_url dolu) ve kalıcı hatalı (og_image_cache_failed_at dolu) item'lar atlanır.
/// Geçici hatalar işaretlenmez; bir sonraki çalıştırmada yeniden denenir.
/// </summary>
public sealed class OgImageBackfillService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly OgImageCacheProcessor _processor;
    private readonly OgImageUrlPolicy _policy;
    private readonly IOptions<ImageCacheOptions> _options;
    private readonly ILogger<OgImageBackfillService> _logger;

    public OgImageBackfillService(
        IServiceScopeFactory scopeFactory,
        OgImageCacheProcessor processor,
        OgImageUrlPolicy policy,
        IOptions<ImageCacheOptions> options,
        ILogger<OgImageBackfillService> logger)
    {
        _scopeFactory = scopeFactory;
        _processor = processor;
        _policy = policy;
        _options = options;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var options = _options.Value;
        if (!options.Enabled || !options.BackfillOnStartup)
            return;

        try
        {
            await Task.Delay(options.BackfillStartupDelay, stoppingToken);
            await RunAsync(stoppingToken);
        }
        catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
        {
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "OG image backfill aborted.");
        }
    }

    public async Task<OgImageBackfillSummary> RunAsync(CancellationToken cancellationToken)
    {
        var options = _options.Value;
        var batchSize = Math.Clamp(options.BackfillBatchSize, 1, 500);
        var summary = new OgImageBackfillSummary();

        // Keyset imleci (created_at azalan). Aynı created_at'e sahip item'lar için o anki
        // zaman damgasında işlenmiş id'ler tutulur; geçici hatalılar sonsuz döngüye girmez.
        DateTime? cursor = null;
        var idsAtCursor = new HashSet<Guid>();

        _logger.LogInformation("OG image backfill started.");
        while (true)
        {
            List<(Guid Id, DateTime CreatedAt, string? OgImageUrl)> batch;
            using (var scope = _scopeFactory.CreateScope())
            {
                var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
                var query = dbContext.Items.AsNoTracking().Where(i =>
                    i.OgImageUrl != null &&
                    i.OgImageSourceUrl == null &&
                    i.OgImageCacheFailedAt == null &&
                    (i.OgImageUrl.StartsWith("http://") || i.OgImageUrl.StartsWith("https://")));

                if (cursor is { } c)
                {
                    var excluded = idsAtCursor.ToList();
                    query = query.Where(i => i.CreatedAt < c || (i.CreatedAt == c && !excluded.Contains(i.Id)));
                }

                batch = (await query
                        .OrderByDescending(i => i.CreatedAt)
                        .Take(batchSize)
                        .Select(i => new { i.Id, i.CreatedAt, i.OgImageUrl })
                        .ToListAsync(cancellationToken))
                    .Select(i => (i.Id, i.CreatedAt, i.OgImageUrl))
                    .ToList();
            }

            if (batch.Count == 0)
                break;

            foreach (var (id, createdAt, ogImageUrl) in batch)
            {
                if (cursor != createdAt)
                {
                    cursor = createdAt;
                    idsAtCursor.Clear();
                }
                idsAtCursor.Add(id);

                if (!_policy.IsExternal(ogImageUrl))
                {
                    summary.Skipped++;
                    continue;
                }

                var outcome = await _processor.ProcessAsync(id, cancellationToken);
                summary.Record(outcome);

                if (options.BackfillItemDelay > TimeSpan.Zero)
                    await Task.Delay(options.BackfillItemDelay, cancellationToken);
            }
        }

        _logger.LogInformation(
            "OG image backfill finished. Cached={Cached} Reused={Reused} Failed={Failed} Transient={Transient} Skipped={Skipped}",
            summary.Cached, summary.Reused, summary.MarkedFailed, summary.TransientFailures, summary.Skipped);
        return summary;
    }
}

public sealed class OgImageBackfillSummary
{
    public int Cached { get; set; }
    public int Reused { get; set; }
    public int MarkedFailed { get; set; }
    public int TransientFailures { get; set; }
    public int Skipped { get; set; }

    public void Record(OgImageCacheOutcome outcome)
    {
        switch (outcome)
        {
            case OgImageCacheOutcome.Cached: Cached++; break;
            case OgImageCacheOutcome.Reused: Reused++; break;
            case OgImageCacheOutcome.MarkedFailed: MarkedFailed++; break;
            case OgImageCacheOutcome.TransientFailure: TransientFailures++; break;
            default: Skipped++; break;
        }
    }
}
