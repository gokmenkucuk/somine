using System.Text.Json;
using SomineApi.Domain.Entities;

namespace SomineApi.WebApi.Push;

/// <summary>
/// Bir kullanıcının tüm cihazlarına gönderilecek push isteği. Metin, gönderim anında her cihazın
/// diline göre <see cref="PushNotificationTexts"/> ile kurulur.
/// </summary>
/// <param name="UserId">Alıcı kullanıcı.</param>
/// <param name="Type"><see cref="Domain.Notifications.NotificationTypes"/> değeri.</param>
/// <param name="Data">
/// İstemciye giden veri yükü (<c>type</c>, <c>notificationId</c>, <c>shareId</c>, <c>categoryId</c>…).
/// FCM veri değerleri metin olmak zorunda.
/// </param>
public sealed record PushNotificationRequest(Guid UserId, string Type, IReadOnlyDictionary<string, string> Data)
{
    /// <summary>
    /// Kaydedilmiş bir <see cref="Notification"/> satırından push isteği üretir. <c>Data</c> JSON'unun
    /// üst seviye skaler alanları olduğu gibi taşınır; böylece push yükü uygulama içi bildirimle
    /// aynı alan adlarını kullanır.
    /// </summary>
    public static PushNotificationRequest FromNotification(Notification notification)
    {
        var data = new Dictionary<string, string>(StringComparer.Ordinal);

        if (notification.Data != null && notification.Data.RootElement.ValueKind == JsonValueKind.Object)
        {
            foreach (var property in notification.Data.RootElement.EnumerateObject())
            {
                var value = property.Value.ValueKind switch
                {
                    JsonValueKind.String => property.Value.GetString(),
                    JsonValueKind.Number or JsonValueKind.True or JsonValueKind.False => property.Value.GetRawText(),
                    _ => null
                };

                if (value != null) data[property.Name] = value;
            }
        }

        data["type"] = notification.Type;
        data["notificationId"] = notification.Id.ToString();

        return new PushNotificationRequest(notification.UserId, notification.Type, data);
    }
}
