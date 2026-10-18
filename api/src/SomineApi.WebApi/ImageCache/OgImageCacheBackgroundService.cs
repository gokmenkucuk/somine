namespace SomineApi.WebApi.ImageCache;

/// <summary>Kuyruktaki item'ların OG görsellerini sırayla sunucuya kopyalar.</summary>
public sealed class OgImageCacheBackgroundService : BackgroundService
{
    private readonly IOgImageCacheQueue _queue;
    private readonly OgImageCacheProcessor _processor;
    private readonly OgImageUrlPolicy _policy;
    private readonly ILogger<OgImageCacheBackgroundService> _logger;

    public OgImageCacheBackgroundService(
        IOgImageCacheQueue queue,
        OgImageCacheProcessor processor,
        OgImageUrlPolicy policy,
        ILogger<OgImageCacheBackgroundService> logger)
    {
        _queue = queue;
        _processor = processor;
        _policy = policy;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (await _queue.WaitToReadAsync(stoppingToken))
        {
            while (_queue.TryRead(out var itemId))
            {
                if (!_policy.Enabled)
                    continue;

                try
                {
                    await _processor.ProcessAsync(itemId, stoppingToken);
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    throw;
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Failed to cache OG image for item {ItemId}", itemId);
                }
            }
        }
    }
}
