using System.Diagnostics.CodeAnalysis;

namespace SomineApi.WebApi.Push;

/// <summary>
/// HTTP isteğini bekletmeden push göndermek için kuyruk. Gönderim
/// <see cref="PushNotificationBackgroundService"/> tarafından yapılır; push hatası isteği asla
/// başarısız kılmaz.
/// </summary>
/// <remarks>
/// Hatırlatıcılar bilinçli olarak kuyruğa alınmaz: cihaz onları flutter_local_notifications ile
/// zaten yerel olarak planlıyor; sunucudan da push gitmesi çift uyarı üretirdi.
/// </remarks>
public interface IPushNotificationQueue
{
    /// <summary>İsteği kuyruğa alır. Push kapalıysa veya kuyruk doluysa <c>false</c> döner; asla fırlatmaz.</summary>
    bool Enqueue(PushNotificationRequest request);
    ValueTask<bool> WaitToReadAsync(CancellationToken cancellationToken);
    bool TryRead([MaybeNullWhen(false)] out PushNotificationRequest request);
}
