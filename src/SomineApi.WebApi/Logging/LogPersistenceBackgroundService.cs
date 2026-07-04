using Microsoft.EntityFrameworkCore;
using SomineApi.Domain.Entities;
using SomineApi.Infrastructure.Data;

namespace SomineApi.WebApi.Logging;

public sealed class LogPersistenceBackgroundService : BackgroundService
{
    private readonly IServiceScopeFactory _scopeFactory;
    private readonly ILogPersistenceQueue _queue;
    private readonly ILogger<LogPersistenceBackgroundService> _logger;

    public LogPersistenceBackgroundService(
        IServiceScopeFactory scopeFactory,
        ILogPersistenceQueue queue,
        ILogger<LogPersistenceBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _queue = queue;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (await _queue.WaitToReadAsync(stoppingToken))
        {
            var requestLogs = new List<RequestLog>();
            var exceptionLogs = new List<ExceptionLog>();

            while (_queue.TryRead(out var entry) && entry != null)
            {
                switch (entry)
                {
                    case RequestLogQueueEntry requestEntry:
                        requestLogs.Add(requestEntry.Log);
                        break;
                    case ExceptionLogQueueEntry exceptionEntry:
                        exceptionLogs.Add(exceptionEntry.Log);
                        break;
                }
            }

            if (requestLogs.Count == 0 && exceptionLogs.Count == 0)
            {
                continue;
            }

            try
            {
                using var scope = _scopeFactory.CreateScope();
                var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();

                if (requestLogs.Count > 0)
                {
                    await dbContext.RequestLogs.AddRangeAsync(requestLogs, stoppingToken);
                    await dbContext.SaveChangesAsync(stoppingToken);
                }

                if (exceptionLogs.Count > 0)
                {
                    await dbContext.ExceptionLogs.AddRangeAsync(exceptionLogs, stoppingToken);
                    await dbContext.SaveChangesAsync(stoppingToken);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Failed to persist queued logs. RequestCount={RequestCount}, ExceptionCount={ExceptionCount}",
                    requestLogs.Count,
                    exceptionLogs.Count);
            }
        }
    }
}
