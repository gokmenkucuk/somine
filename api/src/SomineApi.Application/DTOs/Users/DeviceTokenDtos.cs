namespace SomineApi.Application.DTOs.Users;

/// <summary><c>PUT /api/users/me/device-token</c> gövdesi (kayıt / yenileme).</summary>
/// <param name="Token">FCM kayıt token'ı.</param>
/// <param name="Platform"><c>ios</c> / <c>android</c>.</param>
/// <param name="Locale">Cihaz dili (örn. <c>tr</c>, <c>en</c>); push metninin dili.</param>
public record RegisterDeviceTokenRequest(string? Token, string? Platform = null, string? Locale = null);

/// <summary><c>DELETE /api/users/me/device-token</c> gövdesi (oturum kapatma).</summary>
public record UnregisterDeviceTokenRequest(string? Token);
