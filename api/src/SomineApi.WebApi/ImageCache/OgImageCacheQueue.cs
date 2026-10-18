using System.Threading.Channels;

namespace SomineApi.WebApi.ImageCache;

public interface IOgImageCacheQueue
{
    bool Enqueue(Guid itemId);
    ValueTask<bool> WaitToReadAsync(CancellationToken cancellationToken);
    bool TryRead(out Guid itemId);
}

/// <summary>Item oluşturma/güncelleme isteğini bekletmeden OG görsel önbelleği işini sıraya alır.</summary>
public sealed class ChannelOgImageCacheQueue : IOgImageCacheQueue
{
    private const int Capacity = 4096;

    private readonly Channel<Guid> _channel = Channel.CreateBounded<Guid>(
        new BoundedChannelOptions(Capacity)
        {
            SingleReader = true,
            SingleWriter = false,
            FullMode = BoundedChannelFullMode.DropWrite
        });

    private readonly ILogger<ChannelOgImageCacheQueue> _logger;

    public ChannelOgImageCacheQueue(ILogger<ChannelOgImageCacheQueue> logger)
    {
        _logger = logger;
    }

    public bool Enqueue(Guid itemId)
    {
        var written = _channel.Writer.TryWrite(itemId);
        if (!written)
        {
            // Düşen iş kaybolmaz: backfill harici kalan görselleri sonradan yakalar.
            _logger.LogWarning("Dropping OG image cache request for item {ItemId} because the queue is full.", itemId);
        }

        return written;
    }

    public ValueTask<bool> WaitToReadAsync(CancellationToken cancellationToken)
        => _channel.Reader.WaitToReadAsync(cancellationToken);

    public bool TryRead(out Guid itemId)
        => _channel.Reader.TryRead(out itemId);
}
