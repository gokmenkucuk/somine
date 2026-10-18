using System.Collections.Concurrent;
using SomineApi.WebApi.Hubs;

namespace SomineApi.Tests.Testing;

/// <summary>SignalR'a gitmeden yayınlanan olayları kaydeden test ikizi.</summary>
public sealed class RecordingUserRealtimeEventPublisher : IUserRealtimeEventPublisher
{
    public ConcurrentQueue<(Guid UserId, string Action, Guid? EntityId)> NotificationEvents { get; } = new();

    public ConcurrentQueue<(Guid UserId, string Action, Guid? EntityId)> ItemEvents { get; } = new();

    public Task PublishItemsChangedAsync(Guid userId, string action, Guid? itemId = null, CancellationToken cancellationToken = default)
    {
        ItemEvents.Enqueue((userId, action, itemId));
        return Task.CompletedTask;
    }

    public Task PublishCategoriesChangedAsync(Guid userId, string action, Guid? categoryId = null, CancellationToken cancellationToken = default)
        => Task.CompletedTask;

    public Task PublishNotificationsChangedAsync(Guid userId, string action, Guid? notificationId = null, CancellationToken cancellationToken = default)
    {
        NotificationEvents.Enqueue((userId, action, notificationId));
        return Task.CompletedTask;
    }
}
