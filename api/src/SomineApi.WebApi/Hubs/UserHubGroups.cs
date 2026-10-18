using System.Security.Claims;

namespace SomineApi.WebApi.Hubs;

public static class UserHubGroups
{
    public static string ForUser(Guid userId) => $"user_{userId}";

    public static string? ResolveUserGroup(ClaimsPrincipal? user)
    {
        var userIdClaim = user?.FindFirst(ClaimTypes.NameIdentifier)
            ?? user?.FindFirst("sub");

        if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
        {
            return null;
        }

        return ForUser(userId);
    }
}
