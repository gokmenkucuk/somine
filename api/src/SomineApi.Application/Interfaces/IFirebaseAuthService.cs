namespace SomineApi.Application.Interfaces;

public interface IFirebaseAuthService
{
    Task<FirebaseUserInfo> VerifyGoogleTokenAsync(string idToken);
    Task<FirebaseUserInfo> VerifyAppleTokenAsync(string idToken);
}

public record FirebaseUserInfo(string Uid, string? Email, string? DisplayName, string? PhotoUrl);
