using System.Collections.Concurrent;

namespace SomineApi.Domain.Reminders;

/// <summary>
/// IANA zaman dilimi çözümlemesi + önbelleği.
/// </summary>
/// <remarks>
/// Kullanıcıda zaman dilimi yoksa varsayılan Türkiye'dir. Türkiye 2016'dan beri kalıcı UTC+03:00
/// (yaz saati uygulaması yok), bu yüzden tzdata bulunamadığında sabit +03:00'lık bir yedek zaman dilimi
/// davranışsal olarak Europe/Istanbul ile birebir aynıdır — container'da tzdata eksikse bile hatırlatıcılar
/// doğru anda tetiklenir.
/// </remarks>
public static class ReminderTimeZones
{
    public const string DefaultTimeZoneId = "Europe/Istanbul";

    /// <summary>Zaman dilimi kimliği için kabul edilen azami uzunluk (users.time_zone_id kolonu ile aynı).</summary>
    public const int MaxTimeZoneIdLength = 64;

    private static readonly TimeZoneInfo FallbackTimeZone = TimeZoneInfo.CreateCustomTimeZone(
        id: "SoMine/UTC+03",
        baseUtcOffset: TimeSpan.FromHours(3),
        displayName: "(UTC+03:00) somine varsayılanı",
        standardDisplayName: "UTC+03:00");

    private static readonly ConcurrentDictionary<string, TimeZoneInfo> Cache = new(StringComparer.Ordinal);

    /// <summary>
    /// Verilen IANA kimliğini çözer. Kimlik boşsa <paramref name="fallbackId"/>, o da çözülemezse
    /// sabit UTC+03:00 döner. Asla istisna fırlatmaz.
    /// </summary>
    public static TimeZoneInfo Resolve(string? timeZoneId, string? fallbackId = null)
    {
        var id = FirstNonBlank(timeZoneId, fallbackId, DefaultTimeZoneId);
        return Cache.GetOrAdd(id, static key =>
        {
            try
            {
                return TimeZoneInfo.FindSystemTimeZoneById(key);
            }
            catch (Exception ex) when (ex is TimeZoneNotFoundException or InvalidTimeZoneException)
            {
                return FallbackTimeZone;
            }
        });
    }

    /// <summary>Kimliğin sistemde gerçekten tanımlı olup olmadığını söyler (doğrulama/teşhis için).</summary>
    public static bool IsKnown(string? timeZoneId)
    {
        if (string.IsNullOrWhiteSpace(timeZoneId)) return false;
        try
        {
            TimeZoneInfo.FindSystemTimeZoneById(timeZoneId);
            return true;
        }
        catch (Exception ex) when (ex is TimeZoneNotFoundException or InvalidTimeZoneException)
        {
            return false;
        }
    }

    private static string FirstNonBlank(string? a, string? b, string c)
    {
        if (!string.IsNullOrWhiteSpace(a)) return a.Trim();
        if (!string.IsNullOrWhiteSpace(b)) return b.Trim();
        return c;
    }
}
