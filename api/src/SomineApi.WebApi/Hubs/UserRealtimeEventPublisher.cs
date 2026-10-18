using Microsoft.AspNetCore.SignalR;

namespace SomineApi.WebApi.Hubs;

public sealed class UserRealtimeEventPublisher : IUserRealtimeEventPublisher
{
    private readonly IHubContext<ItemsHub> _itemsHubContext;
    private readonly IHubContext<CategoriesHub> _categoriesHubContext;
    private readonly IHubContext<NotificationsHub> _notificationsHubContext;

    public UserRealtimeEventPublisher(
        IHubContext<ItemsHub> itemsHubContext,
        IHubContext<CategoriesHub> categoriesHubContext,
        IHubContext<NotificationsHub> notificationsHubContext)
    {
        _itemsHubContext = itemsHubContext;
        _categoriesHubContext = categoriesHubContext;
        _notificationsHubContext = notificationsHubContext;
    }

    public Task PublishItemsChangedAsync(
        Guid userId,
        string action,
        Guid? itemId = null,
        CancellationToken cancellationToken = default)
    {
        var payload = new EntityChangedEvent("item", action, itemId, DateTime.UtcNow);
        return _itemsHubContext.Clients
            .Group(UserHubGroups.ForUser(userId))
            .SendAsync("items_changed", payload, cancellationToken);
    }

    public Task PublishCategoriesChangedAsync(
        Guid userId,
        string action,
        Guid? categoryId = null,
        CancellationToken cancellationToken = default)
    {
        var payload = new EntityChangedEvent("category", action, categoryId, DateTime.UtcNow);
        return _categoriesHubContext.Clients
            .Group(UserHubGroups.ForUser(userId))
            .SendAsync("categories_changed", payload, cancellationToken);
    }

    public Task PublishNotificationsChangedAsync(
        Guid userId,
        string action,
        Guid? notificationId = null,
        CancellationToken cancellationToken = default)
    {
        var payload = new EntityChangedEvent("notification", action, notificationId, DateTime.UtcNow);
        return _notificationsHubContext.Clients
            .Group(UserHubGroups.ForUser(userId))
            .SendAsync("notifications_changed", payload, cancellationToken);
    }
}
