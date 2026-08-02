using SomineApi.Domain.Enums;
using SomineApi.Domain.Reminders;

namespace SomineApi.Tests;

// Saf tekrar mantığı — 9 RepeatFrequency değerinin tamamı + ay sonu / artık yıl / yaz saati kenar durumları.
public class ReminderScheduleCalculatorTests
{
    private static readonly TimeZoneInfo Istanbul = ReminderTimeZones.Resolve("Europe/Istanbul");

    private static ReminderSchedule Schedule(
        string startDate,
        int hour = 9,
        int minute = 0,
        RepeatFrequency repeat = RepeatFrequency.None,
        int? customDays = null,
        int? customMinutes = null)
        => new(DateOnly.Parse(startDate), hour, minute, repeat, customDays, customMinutes);

    private static DateTime Local(string value) => DateTime.Parse(value, null, System.Globalization.DateTimeStyles.None);

    // ---------- None ----------

    [Fact]
    public void None_BeforeStart_HasNoDueOccurrence()
    {
        var schedule = Schedule("2026-08-10", repeat: RepeatFrequency.None);
        Assert.Null(ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-08-10T08:59:00")));
    }

    [Fact]
    public void None_AtOrAfterStart_ReturnsStartAndNeverAdvances()
    {
        var schedule = Schedule("2026-08-10", repeat: RepeatFrequency.None);

        Assert.Equal(Local("2026-08-10T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-08-10T09:00:00")));
        Assert.Equal(Local("2026-08-10T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2027-01-01T00:00:00")));
        // Tekrarsız ve vakti geçmiş → sıradaki yok
        Assert.Null(ReminderScheduleCalculator.GetNextOccurrenceLocal(schedule, Local("2026-08-10T09:00:01")));
    }

    // ---------- Daily ----------

    [Fact]
    public void Daily_AdvancesOneDayAtATime()
    {
        var schedule = Schedule("2026-08-01", repeat: RepeatFrequency.Daily);

        Assert.Equal(Local("2026-08-09T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-08-10T08:59:00")));
        Assert.Equal(Local("2026-08-10T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-08-10T09:00:00")));
        Assert.Equal(Local("2026-08-10T09:00:00"), ReminderScheduleCalculator.GetNextOccurrenceLocal(schedule, Local("2026-08-09T09:00:01")));
    }

    // ---------- Weekly ----------

    [Fact]
    public void Weekly_KeepsTheSameWeekday()
    {
        // 2026-08-03 pazartesi
        var schedule = Schedule("2026-08-03", repeat: RepeatFrequency.Weekly);
        var due = ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-08-25T12:00:00"));

        Assert.Equal(Local("2026-08-24T09:00:00"), due);
        Assert.Equal(DayOfWeek.Monday, due!.Value.DayOfWeek);
    }

    // ---------- Monthly ----------

    [Fact]
    public void Monthly_ClampsToLastDayOfShorterMonths()
    {
        var schedule = Schedule("2026-01-31", repeat: RepeatFrequency.Monthly);

        // Şubat 2026 = 28 gün → 28'ine kırpılır
        Assert.Equal(Local("2026-02-28T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-02-28T23:00:00")));
        // Mart yeniden 31 → kırpma kalıcı DEĞİL (orijinal gün korunur)
        Assert.Equal(Local("2026-03-31T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-04-01T00:00:00")));
        // Nisan 30 gün
        Assert.Equal(Local("2026-04-30T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-04-30T12:00:00")));
    }

    [Fact]
    public void Monthly_NextOccurrenceCrossesYearBoundary()
    {
        var schedule = Schedule("2026-11-15", repeat: RepeatFrequency.Monthly);
        Assert.Equal(Local("2027-01-15T09:00:00"), ReminderScheduleCalculator.GetNextOccurrenceLocal(schedule, Local("2026-12-15T09:00:01")));
    }

    // ---------- Yearly ----------

    [Fact]
    public void Yearly_LeapDayFallsBackToFeb28AndRecoversOnLeapYears()
    {
        var schedule = Schedule("2024-02-29", repeat: RepeatFrequency.Yearly);

        Assert.Equal(Local("2025-02-28T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2025-06-01T00:00:00")));
        Assert.Equal(Local("2027-02-28T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2027-06-01T00:00:00")));
        // 2028 artık yıl → 29 Şubat geri gelir (mobil sürüm bir kez 28'e düştükten sonra orada kalır;
        // sunucu her zaman orijinal günden hesapladığı için kaymayı biriktirmez)
        Assert.Equal(Local("2028-02-29T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2028-06-01T00:00:00")));
    }

    [Fact]
    public void Yearly_BeforeFirstAnniversaryStaysOnStart()
    {
        var schedule = Schedule("2026-03-10", repeat: RepeatFrequency.Yearly);
        Assert.Equal(Local("2026-03-10T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2027-01-05T00:00:00")));
    }

    // ---------- Weekdays ----------

    [Fact]
    public void Weekdays_SkipsWeekendsAndShiftsAWeekendStartForward()
    {
        // 2026-08-08 cumartesi → çapa pazartesi 2026-08-10'a kayar
        var schedule = Schedule("2026-08-08", repeat: RepeatFrequency.Weekdays);

        Assert.Null(ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-08-09T23:00:00")));
        Assert.Equal(Local("2026-08-10T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-08-10T09:00:00")));

        // Pazar günü sorulursa en son tetikleme cuma olmalı
        var due = ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-08-16T12:00:00"));
        Assert.Equal(Local("2026-08-14T09:00:00"), due);
        Assert.Equal(DayOfWeek.Friday, due!.Value.DayOfWeek);

        // Cumadan sonraki sıradaki → pazartesi
        var next = ReminderScheduleCalculator.GetNextOccurrenceLocal(schedule, Local("2026-08-14T09:00:01"));
        Assert.Equal(Local("2026-08-17T09:00:00"), next);
        Assert.Equal(DayOfWeek.Monday, next!.Value.DayOfWeek);
    }

    // ---------- Weekends ----------

    [Fact]
    public void Weekends_OnlyFiresOnSaturdayAndSunday()
    {
        // 2026-08-10 pazartesi → çapa cumartesi 2026-08-15'e kayar
        var schedule = Schedule("2026-08-10", repeat: RepeatFrequency.Weekends);

        Assert.Null(ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-08-14T23:00:00")));

        var due = ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-08-19T12:00:00"));
        Assert.Equal(Local("2026-08-16T09:00:00"), due);
        Assert.Equal(DayOfWeek.Sunday, due!.Value.DayOfWeek);

        var next = ReminderScheduleCalculator.GetNextOccurrenceLocal(schedule, Local("2026-08-17T00:00:00"));
        Assert.Equal(Local("2026-08-22T09:00:00"), next);
        Assert.Equal(DayOfWeek.Saturday, next!.Value.DayOfWeek);
    }

    // ---------- CustomDays ----------

    [Fact]
    public void CustomDays_UsesTheConfiguredInterval()
    {
        var schedule = Schedule("2026-08-01", repeat: RepeatFrequency.CustomDays, customDays: 3);

        Assert.Equal(Local("2026-08-13T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-08-15T08:00:00")));
        Assert.Equal(Local("2026-08-16T09:00:00"), ReminderScheduleCalculator.GetNextOccurrenceLocal(schedule, Local("2026-08-15T08:00:00")));
    }

    [Fact]
    public void CustomDays_WithoutIntervalDoesNotRepeat()
    {
        var schedule = Schedule("2026-08-01", repeat: RepeatFrequency.CustomDays);
        Assert.Equal(Local("2026-08-01T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-09-01T09:00:00")));
    }

    // ---------- CustomMinutes ----------

    [Fact]
    public void CustomMinutes_UsesTheConfiguredInterval()
    {
        var schedule = Schedule("2026-08-01", repeat: RepeatFrequency.CustomMinutes, customMinutes: 15);

        Assert.Equal(Local("2026-08-01T10:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-08-01T10:14:00")));
        Assert.Equal(Local("2026-08-01T10:15:00"), ReminderScheduleCalculator.GetNextOccurrenceLocal(schedule, Local("2026-08-01T10:14:00")));
    }

    // ---------- Geçmiş veri koruması (eski enum sırası uyumsuzluğu) ----------

    [Fact]
    public void EffectiveRepeatType_RepairsMobileEnumIndexSwap()
    {
        // Sunucu enum'u artık mobille aynı sırada, ama SQL düzeltmesi uygulanmamış ortamlarda
        // eski kayıtlar hâlâ CustomDays + custom_repeat_minutes=15 şeklinde durabilir.
        // Dolu olan alan custom_repeat_minutes olduğu için dakika bazlı tekrar olarak yorumlanmalı.
        var mobileCustomMinutes = Schedule("2026-08-01", repeat: RepeatFrequency.CustomDays, customMinutes: 15);
        Assert.Equal(RepeatFrequency.CustomMinutes, mobileCustomMinutes.EffectiveRepeatType);
        Assert.Equal(Local("2026-08-01T10:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(mobileCustomMinutes, Local("2026-08-01T10:14:00")));

        var mobileCustomDays = Schedule("2026-08-01", repeat: RepeatFrequency.CustomMinutes, customDays: 3);
        Assert.Equal(RepeatFrequency.CustomDays, mobileCustomDays.EffectiveRepeatType);
        Assert.Equal(Local("2026-08-13T09:00:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(mobileCustomDays, Local("2026-08-15T08:00:00")));

        // Tutarlı veri olduğu gibi kalır
        Assert.Equal(RepeatFrequency.CustomDays, Schedule("2026-08-01", repeat: RepeatFrequency.CustomDays, customDays: 2).EffectiveRepeatType);
    }

    // ---------- Bozuk veri ----------

    [Fact]
    public void OutOfRangeTimeIsClamped()
    {
        var schedule = Schedule("2026-08-01", hour: 99, minute: 99, repeat: RepeatFrequency.None);
        Assert.Equal(Local("2026-08-01T23:59:00"), ReminderScheduleCalculator.GetDueOccurrenceLocal(schedule, Local("2026-08-02T00:00:00")));
    }

    // ---------- UTC / zaman dilimi ----------

    [Fact]
    public void Utc_TurkeyIsAlwaysThreeHoursAhead()
    {
        var schedule = Schedule("2026-08-10", hour: 9, repeat: RepeatFrequency.Daily);
        var now = new DateTimeOffset(2026, 8, 10, 6, 0, 0, TimeSpan.Zero); // 09:00 İstanbul

        var due = ReminderScheduleCalculator.GetDueOccurrenceUtc(schedule, now, Istanbul);
        Assert.Equal(new DateTimeOffset(2026, 8, 10, 6, 0, 0, TimeSpan.Zero), due);

        // Bir dakika öncesinde henüz vakti gelmemiştir
        Assert.Null(ReminderScheduleCalculator.GetDueOccurrenceUtc(schedule, now.AddMinutes(-1), Istanbul));
    }

    [Fact]
    public void Utc_DailyKeepsLocalWallClockAcrossDstTransition()
    {
        // Berlin 2026-03-29'da yaz saatine geçer (+01:00 → +02:00).
        var berlin = ReminderTimeZones.Resolve("Europe/Berlin");
        if (berlin.BaseUtcOffset != TimeSpan.FromHours(1)) return; // tzdata yoksa atla

        var schedule = Schedule("2026-03-25", hour: 9, repeat: RepeatFrequency.Daily);

        var beforeDst = ReminderScheduleCalculator.GetNextOccurrenceUtc(
            schedule, new DateTimeOffset(2026, 3, 26, 0, 0, 0, TimeSpan.Zero), berlin);
        var afterDst = ReminderScheduleCalculator.GetNextOccurrenceUtc(
            schedule, new DateTimeOffset(2026, 3, 31, 0, 0, 0, TimeSpan.Zero), berlin);

        Assert.Equal(8, beforeDst!.Value.Hour);  // 09:00 yerel = 08:00 UTC (+1)
        Assert.Equal(7, afterDst!.Value.Hour);   // 09:00 yerel = 07:00 UTC (+2) — duvar saati korundu
    }

    [Fact]
    public void Utc_NonExistentLocalTimeInDstGapIsShiftedForward()
    {
        var berlin = ReminderTimeZones.Resolve("Europe/Berlin");
        if (berlin.BaseUtcOffset != TimeSpan.FromHours(1)) return;

        // 2026-03-29 02:30 Berlin'de var olmayan bir saat.
        var converted = ReminderScheduleCalculator.ToUtc(new DateTime(2026, 3, 29, 2, 30, 0), berlin);
        Assert.Equal(new DateTimeOffset(2026, 3, 29, 1, 0, 0, TimeSpan.Zero), converted);
    }

    [Fact]
    public void UnknownTimeZoneFallsBackToUtcPlusThree()
    {
        var resolved = ReminderTimeZones.Resolve("Mars/Olympus_Mons");
        Assert.Equal(TimeSpan.FromHours(3), resolved.BaseUtcOffset);
        Assert.False(ReminderTimeZones.IsKnown("Mars/Olympus_Mons"));
    }
}
