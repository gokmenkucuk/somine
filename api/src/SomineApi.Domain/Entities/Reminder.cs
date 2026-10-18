using SomineApi.Domain.Enums;

namespace SomineApi.Domain.Entities;

public class Reminder
{
    public Guid Id { get; set; }
    public Guid ItemId { get; set; }
    public DateOnly ReminderDate { get; set; }
    public int ReminderHour { get; set; }
    public int ReminderMinute { get; set; }
    public RepeatFrequency RepeatType { get; set; } = RepeatFrequency.None;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? LastTriggered { get; set; }
    public int? CustomRepeatDays { get; set; }
    public int? CustomRepeatMinutes { get; set; }

    // Navigation properties
    public Item Item { get; set; } = null!;
}
