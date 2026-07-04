using System.Threading.Channels;

namespace SomineApi.WebApi.Logging;

public sealed class ChannelLogPersistenceQueue : ILogPersistenceQueue
{
    private const int Capacity = 4096;

    private readonly Channel<QueuedLogEntry> _channel = Channel.CreateBounded<QueuedLogEntry>(
        new BoundedChannelOptions(Capacity)
        {
            SingleReader = true,
            SingleWriter = false,
            FullMode = BoundedChannelFullMode.DropWrite
        });

    private readonly ILogger<ChannelLogPersistenceQueue> _logger;

    public ChannelLogPersistenceQueue(ILogger<ChannelLogPersistenceQueue> logger)
    {
        _logger = logger;
    }

    public bool EnqueueRequestLog(RequestLogQueueEntry entry)
        => TryWrite(entry, "request");

    public bool EnqueueExceptionLog(ExceptionLogQueueEntry entry)
        => TryWrite(entry, "exception");

    public ValueTask<bool> WaitToReadAsync(CancellationToken cancellationToken)
        => _channel.Reader.WaitToReadAsync(cancellationToken);

    public bool TryRead(out QueuedLogEntry? entry)
        => _channel.Reader.TryRead(out entry);

    private bool TryWrite(QueuedLogEntry entry, string logType)
    {
        var written = _channel.Writer.TryWrite(entry);
        if (!written)
        {
            _logger.LogWarning("Dropping {LogType} log entry because the persistence queue is full.", logType);
        }

        return written;
    }
}
