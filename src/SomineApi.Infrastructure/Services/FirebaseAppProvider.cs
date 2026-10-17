using FirebaseAdmin;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Configuration;

namespace SomineApi.Infrastructure.Services;

/// <summary>
/// Süreç genelinde tek bir varsayılan <see cref="FirebaseApp"/> örneği sağlar. Kimlik doğrulama
/// (<see cref="FirebaseAuthService"/>) ve push (<see cref="FcmPushNotificationSender"/>) aynı
/// uygulamayı ve aynı servis hesabı kimlik bilgisini paylaşır.
/// </summary>
public static class FirebaseAppProvider
{
    private const string DefaultFirebaseAppName = "[DEFAULT]";
    private static readonly object SyncRoot = new();

    /// <summary>
    /// Varsayılan uygulamayı döndürür; yoksa <c>Firebase:ProjectId</c> /
    /// <c>Firebase:CredentialsPath</c> (veya <c>GOOGLE_APPLICATION_CREDENTIALS</c>) ile oluşturur.
    /// Kimlik bilgisi bulunamazsa istisna fırlatır.
    /// </summary>
    public static FirebaseApp GetOrCreateDefault(IConfiguration configuration)
    {
        var existing = TryGetDefault();
        if (existing != null) return existing;

        lock (SyncRoot)
        {
            existing = TryGetDefault();
            if (existing != null) return existing;

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

            return FirebaseApp.Create(new AppOptions
            {
                ProjectId = projectId,
                Credential = GoogleCredential.GetApplicationDefault()
            });
        }
    }

    private static FirebaseApp? TryGetDefault()
    {
        try
        {
            return FirebaseApp.GetInstance(DefaultFirebaseAppName);
        }
        catch (ArgumentException)
        {
            return null;
        }
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
