using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Configuration;
using SomineApi.Application.Interfaces;

namespace SomineApi.Infrastructure.Services;

public class FirebaseAuthService : IFirebaseAuthService
{
    private const string DefaultFirebaseAppName = "[DEFAULT]";
    private readonly FirebaseAuth _auth;

    public FirebaseAuthService(IConfiguration configuration)
    {
        var projectId = configuration["Firebase:ProjectId"];
        var credentialsPath = NormalizeCredentialsPath(configuration["Firebase:CredentialsPath"]);

        if (!string.IsNullOrWhiteSpace(credentialsPath))
        {
            if (!Path.IsPathRooted(credentialsPath))
            {
                credentialsPath = Path.GetFullPath(Path.Combine(AppContext.BaseDirectory, credentialsPath));
            }

            if (!File.Exists(credentialsPath))
            {
                throw new FileNotFoundException("Firebase credentials file not found.", credentialsPath);
            }

            Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", credentialsPath);
        }

        FirebaseApp? firebaseApp = null;

        try
        {
            firebaseApp = FirebaseApp.GetInstance(DefaultFirebaseAppName);
        }
        catch (ArgumentException)
        {
        }

        firebaseApp ??= FirebaseApp.Create(new AppOptions
        {
            ProjectId = projectId,
            Credential = GoogleCredential.GetApplicationDefault()
        });

        _auth = FirebaseAuth.GetAuth(firebaseApp);
    }

    public async Task<FirebaseUserInfo> VerifyGoogleTokenAsync(string idToken)
    {
        return await VerifyTokenAsync(idToken);
    }

    public async Task<FirebaseUserInfo> VerifyAppleTokenAsync(string idToken)
    {
        return await VerifyTokenAsync(idToken);
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

    private static string? NormalizeCredentialsPath(string? configuredPath)
    {
        if (string.IsNullOrWhiteSpace(configuredPath))
            return null;

        var trimmed = configuredPath.Trim();
        return trimmed.StartsWith("CHANGE_ME", StringComparison.OrdinalIgnoreCase)
            ? null
            : trimmed;
    }
}
