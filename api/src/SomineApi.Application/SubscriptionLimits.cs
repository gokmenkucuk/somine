namespace SomineApi.Application;

public static class SubscriptionLimits
{
    public const int FreeMaxItems = 500;           // soft-delete edilmişler SAYILMAZ
    public const int FreeMaxCategories = 10;
    public const int FreeMaxActiveReminders = 3;   // yalnızca IsActive
    /// <summary>
    /// Ücretsiz planda takvim ayı (UTC) başına gönderilebilecek paylaşım isteği.
    /// Reddedilenler de sayılır; aksi halde reddettirip tekrar göndererek aşılırdı.
    /// </summary>
    public const int FreeMonthlyShares = 5;

    /// <summary>Ayın ilk günü 00:00 UTC.</summary>
    public static DateTime MonthStartUtc(DateTime nowUtc) => new(nowUtc.Year, nowUtc.Month, 1, 0, 0, 0, DateTimeKind.Utc);
}
