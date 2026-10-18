using SomineApi.Domain.Enums;

namespace SomineApi.Application.DTOs.Reminders;

public record CreateReminderRequest(
    Guid ItemId,
    DateOnly ReminderDate,
    int ReminderHour,
    int ReminderMinute,
    RepeatFrequency RepeatType = RepeatFrequency.None,
    int? CustomRepeatDays = null,
    int? CustomRepeatMinutes = null
);

public record UpdateReminderRequest(
    DateOnly? ReminderDate,
    int? ReminderHour,
    int? ReminderMinute,
    RepeatFrequency? RepeatType,
    bool? IsActive,
    int? CustomRepeatDays,
    int? CustomRepeatMinutes
);

public record ReminderDto(
    Guid Id,
    Guid ItemId,
    DateOnly ReminderDate,
    int ReminderHour,
    int ReminderMinute,
    RepeatFrequency RepeatType,
    bool IsActive,
    int? CustomRepeatDays,
    int? CustomRepeatMinutes,
    DateTime CreatedAt,
    // Sunucunun bu hatırlatıcı için en son bildirim ürettiği an (UTC). Hiç tetiklenmediyse null.
    DateTime? LastTriggered = null,
    // Sunucunun hesapladığı SIRADAKİ tetikleme anı (UTC). Yalnız okunur — istemci gönderemez;
    // kullanıcının zaman diliminden (users.time_zone_id) türetilir. Tekrarsız ve vakti geçmişse null.
    DateTime? NextTriggerAtUtc = null
);
