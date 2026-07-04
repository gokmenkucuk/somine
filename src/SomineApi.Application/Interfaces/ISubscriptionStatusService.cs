using SomineApi.Application.DTOs.Subscriptions;
using SomineApi.Domain.Entities;

namespace SomineApi.Application.Interfaces;

public interface ISubscriptionStatusService
{
    Task<SubscriptionStatusDto> GetStatusAsync(User user, string? preferredPlatform, CancellationToken cancellationToken = default);
}
