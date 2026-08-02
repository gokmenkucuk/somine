using SomineApi.Domain.Reminders;

namespace SomineApi.WebApi.Options;

/// <summary>
/// Vakti gelen hatırlatıcılar için uygulama içi bildirim üreten arka plan servisinin ayarları.
/// </summary>
public class ReminderNotificationOptions
{
    public const string SectionName = "ReminderNotifications";

    /// <summary>Kapalıyken arka plan servisi hiçbir şey yapmaz (veritabanına dokunmaz).</summary>
    public bool Enabled { get; set; } = true;

    /// <summary>Tarama sıklığı.</summary>
    public TimeSpan PollInterval { get; set; } = TimeSpan.FromMinutes(1);

    /// <summary>
    /// Geriye dönük telafi penceresi. Bundan daha eski bir tetikleme anı ıskalanmış sayılır ve
    /// bildirim üretilmez. Sunucu bir süre kapalı kaldığında kaçırılanların yakalanmasını sağlar;
    /// öte yandan bu özellik ilk kez devreye girdiğinde aylar öncesine ait hatırlatıcıların
    /// topluca bildirim yağdırmasını engeller (backfill yerine geçer).
    /// </summary>
    public TimeSpan CatchUpWindow { get; set; } = TimeSpan.FromHours(24);

    /// <summary>Kullanıcının zaman dilimi yoksa varsayılan IANA kimliği.</summary>
    public string DefaultTimeZoneId { get; set; } = ReminderTimeZones.DefaultTimeZoneId;

    /// <summary>Tek turda incelenecek azami hatırlatıcı sayısı.</summary>
    public int BatchSize { get; set; } = 500;

    public TimeSpan EffectivePollInterval =>
        PollInterval > TimeSpan.Zero ? PollInterval : TimeSpan.FromMinutes(1);

    public TimeSpan EffectiveCatchUpWindow =>
        CatchUpWindow > TimeSpan.Zero ? CatchUpWindow : TimeSpan.FromHours(24);

    public int EffectiveBatchSize => BatchSize is > 0 and <= 5000 ? BatchSize : 500;
}
