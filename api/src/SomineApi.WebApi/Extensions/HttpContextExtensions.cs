using System.Security.Claims;

namespace SomineApi.WebApi.Extensions;

public static class HttpContextExtensions
{
    public static Guid GetUserId(this HttpContext context)
    {
        var userIdClaim = context.User.FindFirst(ClaimTypes.NameIdentifier)
            ?? context.User.FindFirst("sub");

        if (userIdClaim == null || !Guid.TryParse(userIdClaim.Value, out var userId))
            throw new UnauthorizedAccessException("Invalid or missing user token.");

        return userId;
    }

    public static Guid? GetSessionId(this HttpContext context)
    {
        var sessionClaim = context.User.FindFirst("sid");
        if (sessionClaim == null || !Guid.TryParse(sessionClaim.Value, out var sessionId))
            return null;

        return sessionId;
    }
}
