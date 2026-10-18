using SomineApi.Domain.Enums;

namespace SomineApi.Domain.Reminders;

/// <summary>
/// Bir hatırlatıcının zamanlama tanımı — saf veri, EF'e ya da HTTP'ye bağlı değil.
/// Yerel duvar saati (wall clock) semantiği taşır: <see cref="StartDate"/> + <see cref="Hour"/>:<see cref="Minute"/>
/// kullanıcının zaman diliminde yorumlanır.
/// </summary>
public readonly record struct ReminderSchedule(
    DateOnly StartDate,
    int Hour,
    int Minute,
    RepeatFrequency RepeatType,
    int? CustomRepeatDays = null,
    int? CustomRepeatMinutes = null)
{
    /// <summary>
    /// Saat/dakika alanları bozuk veriye karşı kırpılmış hâli.
    /// </summary>
    public TimeSpan TimeOfDay => new(Math.Clamp(Hour, 0, 23), Math.Clamp(Minute, 0, 59), 0);

    /// <summary>
    /// Kullanılacak tekrar tipi.
    /// </summary>
    /// <remarks>
    /// GEÇMİŞ VERİ KORUMASI (güvenlik ağı) — aktif bir hata telafisi DEĞİL.
    /// <para>
    /// Sunucu enum'u bir dönem mobilden farklı sıradaydı (sunucuda 7 = CustomDays, 8 = CustomMinutes;
    /// mobilde 7 = customMinutes, 8 = customDays). Mobil <c>repeat.index</c>'i tam sayı gönderdiği için
    /// "her 15 dakikada bir" hatırlatıcılar veritabanına <c>CustomDays</c> + <c>custom_repeat_minutes=15</c>
    /// olarak yazıldı. Kök neden giderildi: <see cref="RepeatFrequency"/> artık mobil sırayla birebir aynı
    /// (bkz. o dosyadaki wire-contract notu) ve mevcut kayıtlar <c>prod_v16_fix_repeat_frequency.sql</c>
    /// ile düzeltildi.
    /// </para>
    /// <para>
    /// Bu özellik, SQL düzeltmesi çalıştırılmamış ortamlarda ya da elde kalmış bozuk kayıtlarda doğru
    /// davranmayı sürdürebilmek için KORUNUYOR. Tutarlı veride hiçbir etkisi yoktur (yalnızca beklenen
    /// custom alanı boş, diğeri doluyken devreye girer), dolayısıyla kaldırılması gerekmez.
    /// </para>
    /// </remarks>
    public RepeatFrequency EffectiveRepeatType => RepeatType switch
    {
        RepeatFrequency.CustomDays when CustomRepeatDays is not > 0 && CustomRepeatMinutes is > 0
            => RepeatFrequency.CustomMinutes,
        RepeatFrequency.CustomMinutes when CustomRepeatMinutes is not > 0 && CustomRepeatDays is > 0
            => RepeatFrequency.CustomDays,
        _ => RepeatType
    };
}
