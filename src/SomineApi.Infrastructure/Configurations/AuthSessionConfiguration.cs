using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SomineApi.Domain.Entities;

namespace SomineApi.Infrastructure.Configurations;

public class AuthSessionConfiguration : IEntityTypeConfiguration<AuthSession>
{
    public void Configure(EntityTypeBuilder<AuthSession> builder)
    {
        builder.ToTable("auth_sessions");

        builder.HasKey(s => s.Id);

        builder.Property(s => s.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(s => s.UserId).HasColumnName("user_id").IsRequired();
        builder.Property(s => s.RefreshTokenHash).HasColumnName("refresh_token_hash").IsRequired().HasMaxLength(128);
        builder.Property(s => s.ClientId).HasColumnName("client_id").HasMaxLength(128);
        builder.Property(s => s.Platform).HasColumnName("platform").HasMaxLength(64);
        builder.Property(s => s.DeviceName).HasColumnName("device_name").HasMaxLength(128);
        builder.Property(s => s.UserAgent).HasColumnName("user_agent").HasMaxLength(1024);
        builder.Property(s => s.IpAddress).HasColumnName("ip_address").HasMaxLength(64);
        builder.Property(s => s.ExpiresAt).HasColumnName("expires_at").IsRequired();
        builder.Property(s => s.LastUsedAt).HasColumnName("last_used_at");
        builder.Property(s => s.RevokedAt).HasColumnName("revoked_at");
        builder.Property(s => s.ReplacedBySessionId).HasColumnName("replaced_by_session_id");
        builder.Property(s => s.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");
        builder.Property(s => s.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("NOW()");

        builder.HasIndex(s => s.UserId);
        builder.HasIndex(s => s.RefreshTokenHash).IsUnique();
        builder.HasIndex(s => s.ExpiresAt);

        builder.HasOne(s => s.User)
            .WithMany(u => u.AuthSessions)
            .HasForeignKey(s => s.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(s => s.ReplacedBySession)
            .WithMany()
            .HasForeignKey(s => s.ReplacedBySessionId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
