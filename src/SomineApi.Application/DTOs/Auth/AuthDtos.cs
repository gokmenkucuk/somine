namespace SomineApi.Application.DTOs.Auth;

public record GoogleLoginRequest(string IdToken);
public record AppleLoginRequest(string IdToken, string? AuthorizationCode = null);
public record RefreshTokenRequest(string RefreshToken);
public record LogoutRequest(string? RefreshToken = null);

public record AuthResponse(
    string AccessToken,
    string RefreshToken,
    string TokenType,
    int ExpiresIn,
    UserDto User
);

public record UserDto(
    Guid Id,
    string? Email,
    string? DisplayName,
    string? Username,
    string? PhotoUrl,
    string? PhotoBase64 = null,
    string? TimeZoneId = null
);

public record AuthSessionDto(
    Guid Id,
    string? ClientId,
    string? Platform,
    string? DeviceName,
    string? UserAgent,
    string? IpAddress,
    DateTime CreatedAt,
    DateTime? LastUsedAt,
    DateTime ExpiresAt,
    DateTime? RevokedAt,
    bool IsCurrent,
    bool IsActive
);
