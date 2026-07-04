using System.Diagnostics;
using SomineApi.WebApi.Logging;

namespace SomineApi.WebApi.Middleware;

public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogPersistenceQueue _queue;

    public RequestLoggingMiddleware(RequestDelegate next, ILogPersistenceQueue queue)
    {
        _next = next;
        _queue = queue;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        LogPayloadBuilder.GetOrCreateRequestLogId(context);

        var stopwatch = Stopwatch.StartNew();
        await _next(context);
        stopwatch.Stop();

        var requestLog = LogPayloadBuilder.BuildRequestLog(context, stopwatch.ElapsedMilliseconds);
        _queue.EnqueueRequestLog(new RequestLogQueueEntry(requestLog));
    }
}
