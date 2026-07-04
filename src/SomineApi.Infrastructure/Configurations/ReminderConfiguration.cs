using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;

namespace SomineApi.Infrastructure.Configurations;

public class ReminderConfiguration : IEntityTypeConfiguration<Reminder>
{
    public void Configure(EntityTypeBuilder<Reminder> builder)
    {
        builder.ToTable("reminders");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(r => r.ItemId).HasColumnName("item_id");
        builder.Property(r => r.ReminderDate).HasColumnName("reminder_date");
        builder.Property(r => r.ReminderHour).HasColumnName("reminder_hour");
        builder.Property(r => r.ReminderMinute).HasColumnName("reminder_minute");
        builder.Property(r => r.RepeatType).HasColumnName("repeat_type").HasConversion<string>().HasDefaultValue(RepeatFrequency.None);
        builder.Property(r => r.IsActive).HasColumnName("is_active").HasDefaultValue(true);
        builder.Property(r => r.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");
        builder.Property(r => r.LastTriggered).HasColumnName("last_triggered");
        builder.Property(r => r.CustomRepeatDays).HasColumnName("custom_repeat_days");
        builder.Property(r => r.CustomRepeatMinutes).HasColumnName("custom_repeat_minutes");

        builder.HasIndex(r => r.ItemId);

        builder.HasOne(r => r.Item)
            .WithOne(i => i.Reminder)
            .HasForeignKey<Reminder>(r => r.ItemId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
