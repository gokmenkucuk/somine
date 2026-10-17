using SomineApi.Domain.Interfaces;

namespace SomineApi.Domain.Entities;

/// <summary>
/// Bir cihazın Firebase Cloud Messaging (FCM) kayıt token'ı. Uygulama kapalıyken uzak bildirim
/// (push) göndermek için kullanılır. Token küresel olarak benzersizdir: aynı cihazda başka bir
/// hesapla oturum açılırsa satır yeni kullanıcıya taşınır.
/// </summary>
public class DeviceToken : IAuditableEntity
{
    public const int MaxTokenLength = 512;
    public const int MaxPlatformLength = 16;
    public const int MaxLocaleLength = 16;

    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Token { get; set; } = string.Empty;

    /// <summary><c>ios</c> / <c>android</c>.</summary>
    public string? Platform { get; set; }

    /// <summary>Push metninin dili için cihaz dili (örn. <c>tr</c>, <c>en</c>).</summary>
    public string? Locale { get; set; }

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>İstemcinin token'ı en son bildirdiği an (bayat token temizliği için).</summary>
    public DateTime LastSeenAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
}
