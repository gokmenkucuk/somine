using System.Collections.Concurrent;
using SomineApi.Application.Interfaces;

namespace SomineApi.Tests.Testing;

public sealed class FakeSubscriptionTierService : ISubscriptionTierService
{
    private readonly ConcurrentDictionary<Guid, bool> _premiumUsers = new();

    public bool DefaultIsPremium { get; set; }

    public void SetPremium(Guid userId, bool isPremium)
    {
        _premiumUsers[userId] = isPremium;
    }

    public Task<bool> IsPremiumForEnforcementAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return Task.FromResult(_premiumUsers.TryGetValue(userId, out var isPremium)
            ? isPremium
            : DefaultIsPremium);
    }
}
