using System.Threading.Channels;

namespace SomineApi.WebApi.Embeddings;

public sealed class ChannelEmbeddingQueue : IEmbeddingQueue
{
    private const int Capacity = 4096;

    private readonly Channel<Guid> _channel = Channel.CreateBounded<Guid>(
        new BoundedChannelOptions(Capacity)
        {
            SingleReader = true,
            SingleWriter = false,
            FullMode = BoundedChannelFullMode.DropWrite
        });

    private readonly ILogger<ChannelEmbeddingQueue> _logger;

    public ChannelEmbeddingQueue(ILogger<ChannelEmbeddingQueue> logger)
    {
        _logger = logger;
    }

    public bool Enqueue(Guid itemId)
    {
        var written = _channel.Writer.TryWrite(itemId);
        if (!written)
        {
            _logger.LogWarning("Dropping embedding request for item {ItemId} because the embedding queue is full.", itemId);
        }

        return written;
    }

    public ValueTask<bool> WaitToReadAsync(CancellationToken cancellationToken)
        => _channel.Reader.WaitToReadAsync(cancellationToken);

    public bool TryRead(out Guid itemId)
        => _channel.Reader.TryRead(out itemId);
}
