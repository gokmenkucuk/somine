namespace SomineApi.Application.Interfaces;

public interface ISubscriptionTierService
{
    /// Enforcement kararı: bilinmeyen/ulaşılamayan durumda TRUE döner (fail-open).
    Task<bool> IsPremiumForEnforcementAsync(Guid userId, CancellationToken cancellationToken = default);
}
