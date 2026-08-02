using SomineApi.Application.Interfaces;

namespace SomineApi.Tests.Testing;

public sealed class FakeFirebaseAuthService : IFirebaseAuthService
{
    public FirebaseUserInfo UserInfo { get; set; } =
        new("fake-firebase-uid", "fake-user@somine.test", "Fake User", null);

    public Task<FirebaseUserInfo> VerifyGoogleTokenAsync(string idToken)
    {
        return Task.FromResult(UserInfo);
    }

    public Task<FirebaseUserInfo> VerifyAppleTokenAsync(string idToken)
    {
        return Task.FromResult(UserInfo);
    }
}
