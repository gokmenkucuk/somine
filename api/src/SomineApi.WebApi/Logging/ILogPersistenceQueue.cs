namespace SomineApi.WebApi.Logging;

public interface ILogPersistenceQueue
{
    bool EnqueueRequestLog(RequestLogQueueEntry entry);
    bool EnqueueExceptionLog(ExceptionLogQueueEntry entry);
    ValueTask<bool> WaitToReadAsync(CancellationToken cancellationToken);
    bool TryRead(out QueuedLogEntry? entry);
}
