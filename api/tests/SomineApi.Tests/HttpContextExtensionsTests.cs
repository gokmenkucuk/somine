using System.Security.Claims;
using Microsoft.AspNetCore.Http;
using SomineApi.WebApi.Extensions;

namespace SomineApi.Tests;

public class HttpContextExtensionsTests
{
    [Fact]
    public void GetUserId_ReadsSubClaim()
    {
        var userId = Guid.NewGuid();
        var context = CreateHttpContext(new Claim("sub", userId.ToString()));

        var resolved = context.GetUserId();

        Assert.Equal(userId, resolved);
    }

    [Fact]
    public void GetUserId_ReadsNameIdentifierClaim()
    {
        var userId = Guid.NewGuid();
        var context = CreateHttpContext(new Claim(ClaimTypes.NameIdentifier, userId.ToString()));

        var resolved = context.GetUserId();

        Assert.Equal(userId, resolved);
    }

    [Fact]
    public void GetUserId_InvalidClaim_ThrowsUnauthorizedAccessException()
    {
        var context = CreateHttpContext(new Claim("sub", "invalid-guid"));

        Assert.Throws<UnauthorizedAccessException>(() => context.GetUserId());
    }

    [Fact]
    public void GetSessionId_ValidClaim_ReturnsSessionId()
    {
        var sessionId = Guid.NewGuid();
        var context = CreateHttpContext(new Claim("sid", sessionId.ToString()));

        var resolved = context.GetSessionId();

        Assert.Equal(sessionId, resolved);
    }

    [Fact]
    public void GetSessionId_MissingOrInvalidClaim_ReturnsNull()
    {
        var missingContext = CreateHttpContext();
        var invalidContext = CreateHttpContext(new Claim("sid", "invalid-guid"));

        Assert.Null(missingContext.GetSessionId());
        Assert.Null(invalidContext.GetSessionId());
    }

    private static DefaultHttpContext CreateHttpContext(params Claim[] claims)
    {
        var context = new DefaultHttpContext();
        var identity = new ClaimsIdentity(claims, "TestAuth");
        context.User = new ClaimsPrincipal(identity);
        return context;
    }
}
