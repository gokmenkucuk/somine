using Microsoft.EntityFrameworkCore;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Hubs;

namespace SomineApi.WebApi.ImageCache;

public enum OgImageCacheOutcome
{
    Skipped,
    Cached,
    Reused,
    MarkedFailed,
    TransientFailure
}

/// <summary>
/// Tek bir item'ın harici OG görselini sunucuya kopyalar ve item'ı günceller.
/// Hem kuyruk tüketicisi hem backfill tarafından kullanılır.
/// </summary>
public sealed class OgImageCacheProcessor
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly OgImageUrlPolicy _policy;
    private readonly IUserRealtimeEventPublisher _realtimeEventPublisher;
    private readonly TimeProvider _timeProvider;
    private readonly ILogger<OgImageCacheProcessor> _logger;

    public OgImageCacheProcessor(
        IServiceScopeFactory scopeFactory,
        OgImageUrlPolicy policy,
        IUserRealtimeEventPublisher realtimeEventPublisher,
        TimeProvider timeProvider,
        ILogger<OgImageCacheProcessor> logger)
    {
        _scopeFactory = scopeFactory;
        _policy = policy;
        _realtimeEventPublisher = realtimeEventPublisher;
        _timeProvider = timeProvider;
        _logger = logger;
    }

    public async Task<OgImageCacheOutcome> ProcessAsync(Guid itemId, CancellationToken cancellationToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();

        var item = await dbContext.Items.FirstOrDefaultAsync(i => i.Id == itemId, cancellationToken);
        if (item == null || !_policy.IsExternal(item.OgImageUrl))
            return OgImageCacheOutcome.Skipped;

        var sourceUrl = item.OgImageUrl!;

        // Aynı kaynak başka bir item için zaten kopyalandıysa (ör. ortak onboarding içeriği,
        // kopyalanan item) yeniden indirmeden onu kullan — kaynağın süresi dolmuş olsa bile.
        var reusedUrl = await dbContext.Items
            .IgnoreQueryFilters()
            .Where(i => i.OgImageSourceUrl == sourceUrl && i.OgImageUrl != null && i.Id != itemId)
            .Select(i => i.OgImageUrl)
            .FirstOrDefaultAsync(cancellationToken);
        if (reusedUrl != null && !_policy.IsExternal(reusedUrl))
        {
            await ApplyCachedUrlAsync(dbContext, item, sourceUrl, reusedUrl, cancellationToken);
            return OgImageCacheOutcome.Reused;
        }

        var imageCache = scope.ServiceProvider.GetRequiredService<IImageCacheService>();
        var result = await imageCache.CacheAsync(sourceUrl, cancellationToken);

        // İndirme sürerken kullanıcı görseli değiştirmiş olabilir; eski sonucu yazma.
        await dbContext.Entry(item).ReloadAsync(cancellationToken);
        if (item.OgImageUrl != sourceUrl)
            return OgImageCacheOutcome.Skipped;

        switch (result.Status)
        {
            case ImageCacheStatus.Cached:
                await ApplyCachedUrlAsync(dbContext, item, sourceUrl, result.Url!, cancellationToken);
                return OgImageCacheOutcome.Cached;

            case ImageCacheStatus.PermanentFailure:
                item.OgImageCacheFailedAt = _timeProvider.GetUtcNow().UtcDateTime;
                await dbContext.SaveChangesAsync(cancellationToken);
                _logger.LogInformation(
                    "OG image for item {ItemId} could not be cached permanently: {Reason}", itemId, result.Reason);
                return OgImageCacheOutcome.MarkedFailed;

            default:
                _logger.LogInformation(
                    "OG image for item {ItemId} failed transiently: {Reason}", itemId, result.Reason);
                return OgImageCacheOutcome.TransientFailure;
        }
    }

    private async Task ApplyCachedUrlAsync(
        SomineDbContext dbContext,
        Domain.Entities.Item item,
        string sourceUrl,
        string cachedUrl,
        CancellationToken cancellationToken)
    {
        item.OgImageSourceUrl = sourceUrl;
        item.OgImageUrl = cachedUrl;
        item.OgImageCacheFailedAt = null;
        // Mobil istemci listeyi updatedAt imzasıyla karşılaştırıp değişmediyse yeniden çizmiyor;
        // sıralamayı (favoriler/arama updatedAt'e göre) bozmadan imzayı değiştirmek için +1 ms.
        item.UpdatedAt = item.UpdatedAt.AddMilliseconds(1);
        await dbContext.SaveChangesAsync(cancellationToken);

        try
        {
            await _realtimeEventPublisher.PublishItemsChangedAsync(item.UserId, "updated", item.Id, cancellationToken);
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogWarning(ex, "Failed to publish items_changed after caching OG image for item {ItemId}", item.Id);
        }
    }
}
