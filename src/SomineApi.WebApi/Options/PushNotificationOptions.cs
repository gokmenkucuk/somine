namespace SomineApi.WebApi.Options;

/// <summary>
/// Uzak bildirim (FCM push) ayarları. Kimlik bilgisi <c>Firebase:CredentialsPath</c> /
/// <c>GOOGLE_APPLICATION_CREDENTIALS</c> ile kimlik doğrulamayla ortaktır.
/// </summary>
public class PushNotificationOptions
{
    public const string SectionName = "PushNotifications";

    /// <summary>Kapalıyken push kuyruğa alınmaz; bildirimler yalnız DB + SignalR ile kalır.</summary>
    public bool Enabled { get; set; } = true;
}
