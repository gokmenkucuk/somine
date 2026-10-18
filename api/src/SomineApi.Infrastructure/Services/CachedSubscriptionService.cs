using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Logging;
using SomineApi.Application.DTOs.Subscriptions;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Entities;
using SomineApi.Infrastructure.Data;

namespace SomineApi.Infrastructure.Services;

public class CachedSubscriptionService : ISubscriptionStatusService, ISubscriptionTierService
{
    private static readonly TimeSpan ActiveCacheTtl = TimeSpan.FromMinutes(15);
    private static readonly TimeSpan InactiveCacheTtl = TimeSpan.FromMinutes(5);
    private static readonly TimeSpan GracePeriod = TimeSpan.FromHours(24);

    private readonly RevenueCatSubscriptionStatusService _inner;
    private readonly SomineDbContext _dbContext;
    private readonly IMemoryCache _cache;
    private readonly ILogger<CachedSubscriptionService> _logger;

    public CachedSubscriptionService(
        RevenueCatSubscriptionStatusService inner,
        SomineDbContext dbContext,
        IMemoryCache cache,
        ILogger<CachedSubscriptionService> logger)
    {
        _inner = inner;
        _dbContext = dbContext;
        _cache = cache;
        _logger = logger;
    }

    public async Task<SubscriptionStatusDto> GetStatusAsync(User user, string? preferredPlatform, CancellationToken cancellationToken = default)
    {
        var result = await GetStatusCoreAsync(user, preferredPlatform, cancellationToken);
        return result.Status;
    }

    public async Task<bool> IsPremiumForEnforcementAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        try
        {
            var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == userId, cancellationToken);
            if (user == null)
            {
                return false;
            }

            var result = await GetStatusCoreAsync(user, null, cancellationToken);
            if (result.IsUnknown)
            {
                _logger.LogWarning("Subscription status is unknown for user {UserId}; failing open for enforcement", userId);
                return true;
            }

            return result.Status.IsActive;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Unexpected error while enforcing subscription tier for user {UserId}; failing open", userId);
            return true;
        }
    }

    private async Task<SubscriptionLookupResult> GetStatusCoreAsync(User user, string? preferredPlatform, CancellationToken cancellationToken)
    {
        var cacheKey = BuildCacheKey(user.Id, preferredPlatform);

        if (_cache.TryGetValue(cacheKey, out SubscriptionStatusDto? cached) && cached != null)
        {
            return new SubscriptionLookupResult(cached, false);
        }

        try
        {
            var status = await _inner.GetStatusAsync(user, preferredPlatform, cancellationToken);

            _cache.Set(cacheKey, status, status.IsActive ? ActiveCacheTtl : InactiveCacheTtl);

            user.PremiumCheckedAtUtc = DateTime.UtcNow;
            user.PremiumExpiresAtUtc = status.IsActive
                ? (status.ExpiresAt ?? DateTime.UtcNow.AddYears(100))
                : null;
            await _dbContext.SaveChangesAsync(cancellationToken);

            return new SubscriptionLookupResult(status, false);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Subscription status lookup failed for user {UserId}; falling back to DB snapshot", user.Id);

            if (user.PremiumExpiresAtUtc != null && user.PremiumExpiresAtUtc > DateTime.UtcNow - GracePeriod)
            {
                var fallbackStatus = new SubscriptionStatusDto(true, null, user.PremiumExpiresAtUtc, preferredPlatform);
                _cache.Set(cacheKey, fallbackStatus, InactiveCacheTtl);
                return new SubscriptionLookupResult(fallbackStatus, false);
            }

            // Snapshot yok/eskimiş — sonuçta cache'e KOYMA ki sonraki istek tekrar denesin.
            return new SubscriptionLookupResult(new SubscriptionStatusDto(false, null, null, preferredPlatform), true);
        }
    }

    private static string BuildCacheKey(Guid userId, string? platform) => $"sub:tier:{userId}:{platform ?? "any"}";

    private sealed record SubscriptionLookupResult(SubscriptionStatusDto Status, bool IsUnknown);
}
