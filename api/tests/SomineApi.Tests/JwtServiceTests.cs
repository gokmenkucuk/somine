using Microsoft.Extensions.Configuration;
using SomineApi.Infrastructure.Services;

namespace SomineApi.Tests;

public class JwtServiceTests
{
    private static JwtService CreateService()
    {
        var configuration = new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Jwt:Secret"] = "SomineApi-SuperSecretKey-256Bits-MinimumLength-Required!!",
                ["Jwt:Issuer"] = "somine-api",
                ["Jwt:Audience"] = "somine-app",
                ["Jwt:AccessTokenExpireMinutes"] = "60"
            })
            .Build();

        return new JwtService(configuration);
    }

    [Fact]
    public void GenerateAccessToken_ValidateAccessToken_ReturnsUserId()
    {
        var service = CreateService();
        var userId = Guid.NewGuid();

        var token = service.GenerateAccessToken(userId, "test@somine.app", "firebase-uid-1", Guid.NewGuid());
        var validatedUserId = service.ValidateAccessToken(token);

        Assert.Equal(userId, validatedUserId);
    }

    [Fact]
    public void GenerateAccessToken_IncludesSessionIdClaim()
    {
        var service = CreateService();
        var sessionId = Guid.NewGuid();

        var token = service.GenerateAccessToken(Guid.NewGuid(), "test@somine.app", "firebase-uid-1", sessionId);
        var principal = service.GetPrincipalFromToken(token);

        Assert.NotNull(principal);
        Assert.Equal(sessionId.ToString(), principal!.FindFirst("sid")?.Value);
        Assert.Equal("access", principal.FindFirst("type")?.Value);
    }

    [Fact]
    public void HashRefreshToken_SameInput_ProducesSameHash()
    {
        var service = CreateService();

        var first = service.HashRefreshToken("same-token");
        var second = service.HashRefreshToken("same-token");

        Assert.Equal(first, second);
        Assert.Equal(64, first.Length);
    }

    [Fact]
    public void HashRefreshToken_DifferentInputs_ProduceDifferentHashes()
    {
        var service = CreateService();

        var first = service.HashRefreshToken("token-a");
        var second = service.HashRefreshToken("token-b");

        Assert.NotEqual(first, second);
    }

    [Fact]
    public void GetPrincipalFromToken_InvalidToken_ReturnsNull()
    {
        var service = CreateService();

        var principal = service.GetPrincipalFromToken("not-a-real-jwt");

        Assert.Null(principal);
    }
}
