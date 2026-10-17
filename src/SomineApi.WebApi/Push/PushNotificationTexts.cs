using SomineApi.Domain.Notifications;

namespace SomineApi.WebApi.Push;

/// <summary>
/// Push başlık/metinlerinin TR/EN karşılıkları. Türkçe metinler <c>SharesController</c>'ın
/// <c>notifications</c> tablosuna yazdığı başlık/mesajlarla, İngilizceler mobil istemcinin
/// <c>app_en.arb</c> karşılıklarıyla birebir aynıdır.
/// </summary>
public static class PushNotificationTexts
{
    /// <summary>
    /// Cihaz dili <c>tr</c> ile başlıyorsa veya bilinmiyorsa Türkçe, aksi halde İngilizce.
    /// </summary>
    public static bool IsTurkish(string? locale) =>
        string.IsNullOrWhiteSpace(locale)
        || locale.Trim().StartsWith("tr", StringComparison.OrdinalIgnoreCase);

    /// <summary>Tür desteklenmiyorsa <c>null</c> döner (push gönderilmez).</summary>
    public static (string Title, string Body)? Build(PushNotificationRequest request, string? locale)
    {
        var tr = IsTurkish(locale);
        var collection = Value(request, "categoryName") ?? (tr ? "Koleksiyon" : "Collection");

        return request.Type switch
        {
            NotificationTypes.ShareRequest => tr
                ? ("Yeni Paylaşım İsteği",
                   $"{Value(request, "fromUserName") ?? "Bir kullanıcı"} \"{collection}\" koleksiyonunu sizinle paylaşmak istiyor.")
                : ("New Share Request",
                   $"{Value(request, "fromUserName") ?? "A user"} wants to share the \"{collection}\" collection with you."),
            NotificationTypes.ShareAccepted => tr
                ? ("Paylaşım Kabul Edildi", $"Paylaşım isteğiniz kabul edildi: {collection}")
                : ("Share Accepted", $"Your share request was accepted: {collection}"),
            NotificationTypes.ShareRejected => tr
                ? ("Paylaşım Reddedildi", $"Paylaşım isteğiniz reddedildi: {collection}")
                : ("Share Rejected", $"Your share request was rejected: {collection}"),
            _ => null
        };
    }

    private static string? Value(PushNotificationRequest request, string key) =>
        request.Data.TryGetValue(key, out var value) && !string.IsNullOrWhiteSpace(value) ? value : null;
}
