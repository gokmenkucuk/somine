using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SomineApi.Domain.Entities;

namespace SomineApi.Infrastructure.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("users");

        builder.HasKey(u => u.Id);

        builder.Property(u => u.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(u => u.FirebaseUid).HasColumnName("firebase_uid").IsRequired().HasMaxLength(128);
        builder.Property(u => u.Email).HasColumnName("email").HasMaxLength(256);
        builder.Property(u => u.DisplayName).HasColumnName("display_name").HasMaxLength(128);
        builder.Property(u => u.Username).HasColumnName("username").HasMaxLength(64);
        builder.Property(u => u.PhotoUrl).HasColumnName("photo_url");
        builder.Property(u => u.PhotoBase64).HasColumnName("photo_base64");
        builder.Property(u => u.SearchHistoryJson).HasColumnName("search_history_json");
        builder.Property(u => u.TimeZoneId).HasColumnName("time_zone_id").HasMaxLength(64);
        builder.Property(u => u.PremiumExpiresAtUtc).HasColumnName("premium_expires_at_utc");
        builder.Property(u => u.PremiumCheckedAtUtc).HasColumnName("premium_checked_at_utc");
        builder.Property(u => u.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");
        builder.Property(u => u.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("NOW()");

        builder.HasIndex(u => u.FirebaseUid).IsUnique();
        builder.HasIndex(u => u.Username).IsUnique();
    }
}
