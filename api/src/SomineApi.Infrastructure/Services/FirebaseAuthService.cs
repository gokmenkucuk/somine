using FirebaseAdmin.Auth;
using Microsoft.Extensions.Configuration;
using SomineApi.Application.Interfaces;

namespace SomineApi.Infrastructure.Services;

public class FirebaseAuthService : IFirebaseAuthService
{
    private readonly FirebaseAuth _auth;

    public FirebaseAuthService(IConfiguration configuration)
    {
        // Varsayılan FirebaseApp push gönderici ile paylaşılır (FirebaseAppProvider).
        _auth = FirebaseAuth.GetAuth(FirebaseAppProvider.GetOrCreateDefault(configuration));
    }

    public async Task<FirebaseUserInfo> VerifyGoogleTokenAsync(string idToken)
    {
        return await VerifyTokenAsync(idToken);
    }

    public async Task<FirebaseUserInfo> VerifyAppleTokenAsync(string idToken)
    {
        return await VerifyTokenAsync(idToken);
    }

    public async Task<bool?> UserExistsAsync(string firebaseUid, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(firebaseUid)) return false;

        try
        {
            await _auth.GetUserAsync(firebaseUid, cancellationToken);
            return true;
        }
        catch (FirebaseAuthException ex) when (ex.AuthErrorCode == AuthErrorCode.UserNotFound)
        {
            return false;
        }
        catch (Exception ex) when (ex is FirebaseAuthException or HttpRequestException or TaskCanceledException)
        {
            return null;
        }
    }

    private async Task<FirebaseUserInfo> VerifyTokenAsync(string idToken)
    {
        if (string.IsNullOrWhiteSpace(idToken))
        {
            throw new UnauthorizedAccessException("Identity token is required.");
        }

        try
        {
            var decoded = await _auth.VerifyIdTokenAsync(idToken);
            return ExtractUserInfo(decoded);
        }
        catch (FirebaseAuthException ex)
        {
            throw new UnauthorizedAccessException("Invalid identity token.", ex);
        }
        catch (ArgumentException ex)
        {
            throw new UnauthorizedAccessException("Invalid identity token.", ex);
        }
    }

    private static FirebaseUserInfo ExtractUserInfo(FirebaseToken decoded)
    {
        var email = decoded.Claims.TryGetValue("email", out var emailObj) ? emailObj?.ToString() : null;
        var name = decoded.Claims.TryGetValue("name", out var nameObj) ? nameObj?.ToString() : null;
        var picture = decoded.Claims.TryGetValue("picture", out var picObj) ? picObj?.ToString() : null;

        return new FirebaseUserInfo(decoded.Uid, email, name, picture);
    }
}
