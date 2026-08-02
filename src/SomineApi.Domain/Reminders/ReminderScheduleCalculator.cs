using SomineApi.Domain.Enums;

namespace SomineApi.Domain.Reminders;

/// <summary>
/// Hatırlatıcı tekrar mantığı — saf, durumsuz, tamamen test edilebilir.
/// Referans: mobil <c>lib/core/models/reminder_model.dart</c> → <c>calculateNextOccurrence()</c>.
/// </summary>
/// <remarks>
/// Tüm hesaplar önce YEREL duvar saatinde yapılır, sonra kullanıcının zaman dilimiyle UTC'ye çevrilir.
/// Böylece "her gün 09:00" yaz saati geçişlerinde de 09:00 kalır (UTC üzerinde gün eklemek bunu bozardı).
/// Tekrar aralıkları kapalı formülle (O(1)) bulunur; mobildeki döngüler taklit edilmez ama sonuç aynıdır.
/// </remarks>
public static class ReminderScheduleCalculator
{
    /// <summary>
    /// <paramref name="atLocal"/> anında (dahil) tetiklenmiş olması gereken EN SON tekrar anını döner.
    /// Hatırlatıcı henüz hiç başlamadıysa <c>null</c>.
    /// </summary>
    public static DateTime? GetDueOccurrenceLocal(in ReminderSchedule schedule, DateTime atLocal)
    {
        var at = DateTime.SpecifyKind(atLocal, DateTimeKind.Unspecified);
        var repeat = schedule.EffectiveRepeatType;
        var anchor = GetAnchorLocal(schedule, repeat);

        if (anchor > at) return null;

        switch (repeat)
        {
            case RepeatFrequency.None:
                return anchor;

            case RepeatFrequency.Daily:
                return LastByStep(anchor, at, TimeSpan.FromDays(1));

            case RepeatFrequency.Weekly:
                return LastByStep(anchor, at, TimeSpan.FromDays(7));

            case RepeatFrequency.CustomDays:
            {
                var days = schedule.CustomRepeatDays.GetValueOrDefault();
                return days > 0 ? LastByStep(anchor, at, TimeSpan.FromDays(days)) : anchor;
            }

            case RepeatFrequency.CustomMinutes:
            {
                var minutes = schedule.CustomRepeatMinutes.GetValueOrDefault();
                return minutes > 0 ? LastByStep(anchor, at, TimeSpan.FromMinutes(minutes)) : anchor;
            }

            case RepeatFrequency.Monthly:
            {
                var months = ((at.Year - anchor.Year) * 12) + (at.Month - anchor.Month);
                if (months < 0) months = 0;
                var candidate = anchor.AddMonths(months);
                if (candidate > at && months > 0) candidate = anchor.AddMonths(months - 1);
                return candidate;
            }

            case RepeatFrequency.Yearly:
            {
                var years = at.Year - anchor.Year;
                if (years < 0) years = 0;
                var candidate = anchor.AddYears(years);
                if (candidate > at && years > 0) candidate = anchor.AddYears(years - 1);
                return candidate;
            }

            case RepeatFrequency.Weekdays:
                return LastByDayFilter(anchor, at, schedule.TimeOfDay, IsWeekday);

            case RepeatFrequency.Weekends:
                return LastByDayFilter(anchor, at, schedule.TimeOfDay, IsWeekend);

            default:
                return anchor;
        }
    }

    /// <summary>
    /// <paramref name="fromLocal"/> anında ya da sonrasında gerçekleşecek İLK tekrar anını döner.
    /// Tekrarsız bir hatırlatıcının vakti geçmişse <c>null</c>.
    /// </summary>
    public static DateTime? GetNextOccurrenceLocal(in ReminderSchedule schedule, DateTime fromLocal)
    {
        var from = DateTime.SpecifyKind(fromLocal, DateTimeKind.Unspecified);
        var repeat = schedule.EffectiveRepeatType;
        var anchor = GetAnchorLocal(schedule, repeat);

        if (anchor >= from) return anchor;

        switch (repeat)
        {
            case RepeatFrequency.None:
                return null;

            case RepeatFrequency.Daily:
                return NextByStep(anchor, from, TimeSpan.FromDays(1));

            case RepeatFrequency.Weekly:
                return NextByStep(anchor, from, TimeSpan.FromDays(7));

            case RepeatFrequency.CustomDays:
            {
                var days = schedule.CustomRepeatDays.GetValueOrDefault();
                return days > 0 ? NextByStep(anchor, from, TimeSpan.FromDays(days)) : null;
            }

            case RepeatFrequency.CustomMinutes:
            {
                var minutes = schedule.CustomRepeatMinutes.GetValueOrDefault();
                return minutes > 0 ? NextByStep(anchor, from, TimeSpan.FromMinutes(minutes)) : null;
            }

            case RepeatFrequency.Monthly:
            {
                var months = ((from.Year - anchor.Year) * 12) + (from.Month - anchor.Month);
                if (months < 0) months = 0;
                var candidate = anchor.AddMonths(months);
                if (candidate < from) candidate = anchor.AddMonths(months + 1);
                return candidate;
            }

            case RepeatFrequency.Yearly:
            {
                var years = from.Year - anchor.Year;
                if (years < 0) years = 0;
                var candidate = anchor.AddYears(years);
                if (candidate < from) candidate = anchor.AddYears(years + 1);
                return candidate;
            }

            case RepeatFrequency.Weekdays:
                return NextByDayFilter(from, schedule.TimeOfDay, IsWeekday);

            case RepeatFrequency.Weekends:
                return NextByDayFilter(from, schedule.TimeOfDay, IsWeekend);

            default:
                return null;
        }
    }

    /// <summary>
    /// <paramref name="nowUtc"/> anında tetiklenmesi gereken en son tekrarın UTC karşılığı.
    /// </summary>
    public static DateTimeOffset? GetDueOccurrenceUtc(in ReminderSchedule schedule, DateTimeOffset nowUtc, TimeZoneInfo timeZone)
    {
        ArgumentNullException.ThrowIfNull(timeZone);
        var nowLocal = TimeZoneInfo.ConvertTime(nowUtc, timeZone).DateTime;
        var due = GetDueOccurrenceLocal(schedule, nowLocal);
        if (due is null) return null;

        var dueUtc = ToUtc(due.Value, timeZone);

        // Yaz saati geçişi yerel/UTC eşlemesini kaydırabilir; sonuç gerçekten geçmişte değilse
        // bir önceki tekrara in ki "vakti gelmiş" garantisi korunsun.
        if (dueUtc > nowUtc)
        {
            var earlier = GetDueOccurrenceLocal(schedule, due.Value.AddSeconds(-1));
            if (earlier is null || earlier == due) return null;
            dueUtc = ToUtc(earlier.Value, timeZone);
            if (dueUtc > nowUtc) return null;
        }

        return dueUtc;
    }

    /// <summary>
    /// <paramref name="fromUtc"/> anından itibaren ilk tekrarın UTC karşılığı (istemciye gösterilen "sıradaki").
    /// </summary>
    public static DateTimeOffset? GetNextOccurrenceUtc(in ReminderSchedule schedule, DateTimeOffset fromUtc, TimeZoneInfo timeZone)
    {
        ArgumentNullException.ThrowIfNull(timeZone);
        var fromLocal = TimeZoneInfo.ConvertTime(fromUtc, timeZone).DateTime;
        var next = GetNextOccurrenceLocal(schedule, fromLocal);
        return next is null ? null : ToUtc(next.Value, timeZone);
    }

    /// <summary>
    /// Yerel duvar saatini UTC'ye çevirir. Yaz saatine geçiş boşluğuna düşen "var olmayan" saatler
    /// (örn. 03:00'a atlayan bir gecede 02:30) ileri kaydırılır — istisna fırlatılmaz.
    /// </summary>
    public static DateTimeOffset ToUtc(DateTime local, TimeZoneInfo timeZone)
    {
        ArgumentNullException.ThrowIfNull(timeZone);
        var unspecified = DateTime.SpecifyKind(local, DateTimeKind.Unspecified);

        if (timeZone.IsInvalidTime(unspecified))
        {
            for (var offset = 1; offset <= 240; offset++)
            {
                var shifted = unspecified.AddMinutes(offset);
                if (!timeZone.IsInvalidTime(shifted))
                {
                    unspecified = shifted;
                    break;
                }
            }
        }

        return new DateTimeOffset(TimeZoneInfo.ConvertTimeToUtc(unspecified, timeZone), TimeSpan.Zero);
    }

    /// <summary>
    /// Tekrarın başlangıç noktası. Weekdays/Weekends için başlangıç günü uygun değilse ileri kaydırılır
    /// (mobildeki <c>_nextWeekdaysOnly</c>/<c>_nextWeekendsOnly</c> ile aynı davranış).
    /// </summary>
    private static DateTime GetAnchorLocal(in ReminderSchedule schedule, RepeatFrequency repeat)
    {
        var start = schedule.StartDate.ToDateTime(TimeOnly.MinValue, DateTimeKind.Unspecified) + schedule.TimeOfDay;

        return repeat switch
        {
            RepeatFrequency.Weekdays => AdvanceToMatchingDay(start, IsWeekday),
            RepeatFrequency.Weekends => AdvanceToMatchingDay(start, IsWeekend),
            _ => start
        };
    }

    private static DateTime AdvanceToMatchingDay(DateTime value, Func<DayOfWeek, bool> isAllowed)
    {
        for (var i = 0; i < 7 && !isAllowed(value.DayOfWeek); i++)
        {
            value = value.AddDays(1);
        }

        return value;
    }

    private static DateTime LastByStep(DateTime anchor, DateTime at, TimeSpan step)
    {
        if (step <= TimeSpan.Zero) return anchor;
        var steps = (at - anchor).Ticks / step.Ticks;
        if (steps <= 0) return anchor;
        return anchor.AddTicks(step.Ticks * steps);
    }

    private static DateTime NextByStep(DateTime anchor, DateTime from, TimeSpan step)
    {
        if (step <= TimeSpan.Zero) return anchor;
        var elapsed = (from - anchor).Ticks;
        if (elapsed <= 0) return anchor;
        var steps = elapsed / step.Ticks;
        if (anchor.AddTicks(step.Ticks * steps) < from) steps++;
        return anchor.AddTicks(step.Ticks * steps);
    }

    private static DateTime LastByDayFilter(DateTime anchor, DateTime at, TimeSpan timeOfDay, Func<DayOfWeek, bool> isAllowed)
    {
        var candidateDate = at.Date;
        if (at.TimeOfDay < timeOfDay) candidateDate = candidateDate.AddDays(-1);

        var candidate = candidateDate + timeOfDay;
        for (var i = 0; i < 7 && !isAllowed(candidate.DayOfWeek); i++)
        {
            candidate = candidate.AddDays(-1);
        }

        return candidate < anchor ? anchor : candidate;
    }

    private static DateTime NextByDayFilter(DateTime from, TimeSpan timeOfDay, Func<DayOfWeek, bool> isAllowed)
    {
        var candidateDate = from.Date;
        if (from.TimeOfDay > timeOfDay) candidateDate = candidateDate.AddDays(1);

        var candidate = candidateDate + timeOfDay;
        for (var i = 0; i < 7 && !isAllowed(candidate.DayOfWeek); i++)
        {
            candidate = candidate.AddDays(1);
        }

        return candidate;
    }

    private static bool IsWeekday(DayOfWeek day) => day is not (DayOfWeek.Saturday or DayOfWeek.Sunday);

    private static bool IsWeekend(DayOfWeek day) => day is DayOfWeek.Saturday or DayOfWeek.Sunday;
}
