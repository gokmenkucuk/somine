namespace SomineApi.WebApi.Hubs;

public interface IUserRealtimeEventPublisher
{
    Task PublishItemsChangedAsync(Guid userId, string action, Guid? itemId = null, CancellationToken cancellationToken = default);
    Task PublishCategoriesChangedAsync(Guid userId, string action, Guid? categoryId = null, CancellationToken cancellationToken = default);
    Task PublishNotificationsChangedAsync(Guid userId, string action, Guid? notificationId = null, CancellationToken cancellationToken = default);
}
