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
    DateTime CreatedAt
);
