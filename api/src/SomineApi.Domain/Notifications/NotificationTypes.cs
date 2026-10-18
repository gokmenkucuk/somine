namespace SomineApi.Domain.Notifications;

/// <summary>
/// <c>notifications.type</c> kolonunda kullanılan kanonik değerler.
/// </summary>
/// <remarks>
/// Enum yerine sabit dizeler tercih edildi: kolon zaten <c>varchar(32)</c> metin ve mobil istemci bu
/// camelCase değerleri doğrudan ayrıştırıyor. Enum'a geçmek bir dönüştürücü (converter) gerektirir ve
/// mobil ile sunucu arasında sessiz bir uyumsuzluk riski doğurur. Kullanılmayan
/// <c>SomineApi.Domain.Enums.NotificationType</c> enum'u bu sınıfla değiştirildi.
/// </remarks>
public static class NotificationTypes
{
    /// <summary><c>notifications.type</c> kolonunun azami uzunluğu.</summary>
    public const int MaxLength = 32;

    public const string ShareRequest = "shareRequest";
    public const string ShareAccepted = "shareAccepted";
    public const string ShareRejected = "shareRejected";

    /// <summary>Vakti gelen bir hatırlatıcı için sunucunun ürettiği bildirim.</summary>
    public const string Reminder = "reminder";
}
