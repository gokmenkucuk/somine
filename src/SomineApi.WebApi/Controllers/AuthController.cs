using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using SomineApi.Application.DTOs.Auth;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Entities;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Extensions;
using SomineApi.WebApi.Security;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("api/auth")]
[EnableRateLimiting("auth")]
public class AuthController : ControllerBase
{
    private readonly IJwtService _jwtService;
    private readonly SomineDbContext _dbContext;
    private readonly ILogger<AuthController> _logger;

    public AuthController(
        IJwtService jwtService,
        SomineDbContext dbContext,
        ILogger<AuthController> logger)
    {
        _jwtService = jwtService;
        _dbContext = dbContext;
        _logger = logger;
    }

    [HttpPost("google")]
    [RequireClientProof]
    public async Task<ActionResult<AuthResponse>> LoginWithGoogle(
        [FromBody] GoogleLoginRequest request,
        [FromServices] IFirebaseAuthService firebaseAuth)
    {
        var firebaseUser = await firebaseAuth.VerifyGoogleTokenAsync(request.IdToken);

        var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.FirebaseUid == firebaseUser.Uid);

        if (user == null)
        {
            user = new User
            {
                Id = Guid.NewGuid(),
                FirebaseUid = firebaseUser.Uid,
                Email = firebaseUser.Email,
                DisplayName = firebaseUser.DisplayName,
                PhotoUrl = firebaseUser.PhotoUrl,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            _dbContext.Users.Add(user);
            await _dbContext.SaveChangesAsync();
        }

        var (accessToken, refreshToken) = await CreateSessionTokensAsync(user);

        var userDto = new UserDto(user.Id, user.Email, user.DisplayName, user.Username, user.PhotoUrl);

        return Ok(new AuthResponse(accessToken, refreshToken, "Bearer", 3600, userDto));
    }

    [HttpPost("apple")]
    [RequireClientProof]
    public async Task<ActionResult<AuthResponse>> LoginWithApple(
        [FromBody] AppleLoginRequest request,
        [FromServices] IFirebaseAuthService firebaseAuth)
    {
        var firebaseUser = await firebaseAuth.VerifyAppleTokenAsync(request.IdToken);

        var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.FirebaseUid == firebaseUser.Uid);

        if (user == null)
        {
            user = new User
            {
                Id = Guid.NewGuid(),
                FirebaseUid = firebaseUser.Uid,
                Email = firebaseUser.Email,
                DisplayName = firebaseUser.DisplayName,
                PhotoUrl = firebaseUser.PhotoUrl,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            _dbContext.Users.Add(user);
            await _dbContext.SaveChangesAsync();
        }

        var (accessToken, refreshToken) = await CreateSessionTokensAsync(user);

        var userDto = new UserDto(user.Id, user.Email, user.DisplayName, user.Username, user.PhotoUrl);

        return Ok(new AuthResponse(accessToken, refreshToken, "Bearer", 3600, userDto));
    }

    [HttpPost("refresh")]
    [RequireClientProof]
    public async Task<ActionResult<AuthResponse>> RefreshToken([FromBody] RefreshTokenRequest request)
    {
        var refreshTokenHash = _jwtService.HashRefreshToken(request.RefreshToken);
        var session = await _dbContext.AuthSessions
            .Include(s => s.User)
            .FirstOrDefaultAsync(s => s.RefreshTokenHash == refreshTokenHash);

        if (session == null || session.RevokedAt != null || session.ExpiresAt <= DateTime.UtcNow)
            return Unauthorized(new { error = "Invalid refresh token" });

        var verifiedClientId = HttpContext.Items[HttpContextItemKeys.VerifiedClientId] as string;
        if (!string.IsNullOrWhiteSpace(session.ClientId) &&
            !string.Equals(session.ClientId, verifiedClientId, StringComparison.Ordinal))
        {
            return Unauthorized(new { error = "Client mismatch for refresh token" });
        }

        session.RevokedAt = DateTime.UtcNow;
        session.LastUsedAt = DateTime.UtcNow;

        var (accessToken, refreshToken, newSessionId) = CreateSessionTokens(session.User);

        var newSession = BuildAuthSession(session.User, refreshToken, newSessionId);
        session.ReplacedBySessionId = newSession.Id;

        _dbContext.AuthSessions.Add(newSession);
        await _dbContext.SaveChangesAsync();

        var userDto = new UserDto(session.User.Id, session.User.Email, session.User.DisplayName, session.User.Username, session.User.PhotoUrl);

        return Ok(new AuthResponse(accessToken, refreshToken, "Bearer", 3600, userDto));
    }

    [HttpGet("sessions")]
    [Authorize]
    public async Task<ActionResult<List<AuthSessionDto>>> GetSessions()
    {
        var userId = HttpContext.GetUserId();
        var currentSessionId = HttpContext.GetSessionId();
        var now = DateTime.UtcNow;

        var sessions = await _dbContext.AuthSessions
            .Where(session => session.UserId == userId)
            .OrderByDescending(session => session.LastUsedAt ?? session.CreatedAt)
            .Select(session => new AuthSessionDto(
                session.Id,
                session.ClientId,
                session.Platform,
                session.DeviceName,
                session.UserAgent,
                session.IpAddress,
                session.CreatedAt,
                session.LastUsedAt,
                session.ExpiresAt,
                session.RevokedAt,
                currentSessionId.HasValue && session.Id == currentSessionId.Value,
                session.RevokedAt == null && session.ExpiresAt > now))
            .ToListAsync();

        return Ok(sessions);
    }

    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout([FromBody] LogoutRequest? request = null)
    {
        var userId = HttpContext.GetUserId();
        var currentSessionId = HttpContext.GetSessionId();
        var refreshTokenHash = string.IsNullOrWhiteSpace(request?.RefreshToken)
            ? null
            : _jwtService.HashRefreshToken(request!.RefreshToken!);

        AuthSession? session = null;

        if (currentSessionId.HasValue)
        {
            session = await _dbContext.AuthSessions
                .FirstOrDefaultAsync(authSession => authSession.Id == currentSessionId.Value && authSession.UserId == userId);
        }

        if (session == null && refreshTokenHash != null)
        {
            session = await _dbContext.AuthSessions
                .FirstOrDefaultAsync(authSession => authSession.UserId == userId && authSession.RefreshTokenHash == refreshTokenHash);
        }

        if (session == null)
            return NoContent();

        RevokeSession(session);
        _dbContext.AuthSessions.Update(session);
        var affectedRows = await _dbContext.SaveChangesAsync();
        _logger.LogInformation("Logout revoked session {SessionId} for user {UserId}. SaveChanges={AffectedRows}", session.Id, userId, affectedRows);

        return NoContent();
    }

    [HttpPost("logout-all")]
    [Authorize]
    public async Task<IActionResult> LogoutAll()
    {
        var userId = HttpContext.GetUserId();

        var sessions = await _dbContext.AuthSessions
            .Where(session => session.UserId == userId && session.RevokedAt == null)
            .ToListAsync();

        foreach (var session in sessions)
        {
            RevokeSession(session);
            _dbContext.AuthSessions.Update(session);
        }

        var affectedRows = await _dbContext.SaveChangesAsync();
        _logger.LogInformation("LogoutAll revoked {SessionCount} sessions for user {UserId}. SaveChanges={AffectedRows}", sessions.Count, userId, affectedRows);

        return NoContent();
    }

    [HttpDelete("sessions/{sessionId:guid}")]
    [Authorize]
    public async Task<IActionResult> RevokeSessionById(Guid sessionId)
    {
        var userId = HttpContext.GetUserId();
        var session = await _dbContext.AuthSessions
            .FirstOrDefaultAsync(authSession => authSession.Id == sessionId && authSession.UserId == userId);

        if (session == null)
            return NotFound(new { error = "Session not found" });

        RevokeSession(session);
        _dbContext.AuthSessions.Update(session);
        var affectedRows = await _dbContext.SaveChangesAsync();
        _logger.LogInformation("RevokeSessionById revoked session {SessionId} for user {UserId}. SaveChanges={AffectedRows}", sessionId, userId, affectedRows);

        return NoContent();
    }

    // Hesap silme: DELETE /api/users/me (UsersController) — tüm veriyi temizler.
    // Eski DeleteAccount kaldırıldı: yalnızca user satırını siliyordu ve
    // collection_shares Restrict FK'sı nedeniyle paylaşımı olan kullanıcıda patlıyordu.

    private static void RevokeSession(AuthSession session)
    {
        var now = DateTime.UtcNow;
        session.RevokedAt ??= now;
        session.LastUsedAt = now;
        session.UpdatedAt = now;
    }

    private async Task<(string AccessToken, string RefreshToken)> CreateSessionTokensAsync(User user)
    {
        var (accessToken, refreshToken, sessionId) = CreateSessionTokens(user);
        var session = BuildAuthSession(user, refreshToken, sessionId);
        _dbContext.AuthSessions.Add(session);
        await _dbContext.SaveChangesAsync();
        return (accessToken, refreshToken);
    }

    private (string AccessToken, string RefreshToken, Guid SessionId) CreateSessionTokens(User user)
    {
        var sessionId = Guid.NewGuid();
        var refreshToken = _jwtService.GenerateRefreshToken();
        var accessToken = _jwtService.GenerateAccessToken(user.Id, user.Email ?? "", user.FirebaseUid, sessionId);
        return (accessToken, refreshToken, sessionId);
    }

    private AuthSession BuildAuthSession(User user, string refreshToken, Guid sessionId)
    {
        var now = DateTime.UtcNow;
        var refreshTokenDays = int.TryParse(HttpContext.RequestServices.GetRequiredService<IConfiguration>()["Jwt:RefreshTokenExpireDays"], out var configuredDays)
            ? configuredDays
            : 30;

        var verifiedClientId = HttpContext.Items[HttpContextItemKeys.VerifiedClientId] as string;
        var verifiedPlatform = HttpContext.Items[HttpContextItemKeys.VerifiedClientPlatform] as string;
        var userAgent = Request.Headers.UserAgent.ToString();

        return new AuthSession
        {
            Id = sessionId,
            UserId = user.Id,
            RefreshTokenHash = _jwtService.HashRefreshToken(refreshToken),
            ClientId = verifiedClientId,
            Platform = verifiedPlatform,
            DeviceName = verifiedClientId,
            UserAgent = string.IsNullOrWhiteSpace(userAgent) ? null : userAgent,
            IpAddress = HttpContext.Connection.RemoteIpAddress?.ToString(),
            ExpiresAt = now.AddDays(refreshTokenDays),
            LastUsedAt = now,
            CreatedAt = now,
            UpdatedAt = now
        };
    }
}
