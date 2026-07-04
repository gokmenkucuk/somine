using System.Security.Claims;

namespace SomineApi.Application.Interfaces;

public interface IJwtService
{
    string GenerateAccessToken(Guid userId, string email, string firebaseUid, Guid sessionId);
    string GenerateRefreshToken();
    string HashRefreshToken(string refreshToken);
    Guid? ValidateAccessToken(string token);
    ClaimsPrincipal? GetPrincipalFromToken(string token);
}
