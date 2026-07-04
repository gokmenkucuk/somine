namespace SomineApi.WebApi.Hubs;

public sealed record EntityChangedEvent(
    string Entity,
    string Action,
    Guid? Id,
    DateTime TimestampUtc);
