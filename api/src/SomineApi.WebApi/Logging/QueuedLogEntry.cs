using SomineApi.Domain.Entities;

namespace SomineApi.WebApi.Logging;

public abstract record QueuedLogEntry;

public sealed record RequestLogQueueEntry(RequestLog Log) : QueuedLogEntry;

public sealed record ExceptionLogQueueEntry(ExceptionLog Log) : QueuedLogEntry;
