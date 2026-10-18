namespace SomineApi.Application.Interfaces;

public interface IFirebaseAuthService
{
    Task<FirebaseUserInfo> VerifyGoogleTokenAsync(string idToken);
    Task<FirebaseUserInfo> VerifyAppleTokenAsync(string idToken);

    /// <summary>
    /// Firebase'de bu kullanıcı hâlâ var mı? true/false; Firebase'e ulaşılamazsa null
    /// (çağıran tarafı engellememek için "bilinmiyor").
    /// </summary>
    Task<bool?> UserExistsAsync(string firebaseUid, CancellationToken cancellationToken = default);
}

public record FirebaseUserInfo(string Uid, string? Email, string? DisplayName, string? PhotoUrl);
