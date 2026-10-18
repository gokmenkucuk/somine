using SomineApi.WebApi.Logging;

namespace SomineApi.Tests.Testing;

public sealed class NoOpLogPersistenceQueue : ILogPersistenceQueue
{
    public bool EnqueueRequestLog(RequestLogQueueEntry entry) => true;

    public bool EnqueueExceptionLog(ExceptionLogQueueEntry entry) => true;

    public ValueTask<bool> WaitToReadAsync(CancellationToken cancellationToken) => ValueTask.FromResult(false);

    public bool TryRead(out QueuedLogEntry? entry)
    {
        entry = null;
        return false;
    }
}
