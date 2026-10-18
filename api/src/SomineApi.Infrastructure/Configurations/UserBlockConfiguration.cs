using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SomineApi.Domain.Entities;

namespace SomineApi.Infrastructure.Configurations;

public class UserBlockConfiguration : IEntityTypeConfiguration<UserBlock>
{
    public void Configure(EntityTypeBuilder<UserBlock> builder)
    {
        builder.ToTable("user_blocks");

        // Bileşik anahtar = benzersiz (engelleyen, engellenen) çifti.
        builder.HasKey(b => new { b.BlockerId, b.BlockedId });

        builder.Property(b => b.BlockerId).HasColumnName("blocker_id");
        builder.Property(b => b.BlockedId).HasColumnName("blocked_id");
        builder.Property(b => b.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");

        // "Bu alıcı göndereni engellemiş mi?" sorgusu (BlockerId, BlockedId) PK'sini
        // kullanır; ters yön için ayrı index.
        builder.HasIndex(b => b.BlockedId);

        builder.HasOne(b => b.Blocker)
            .WithMany()
            .HasForeignKey(b => b.BlockerId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(b => b.Blocked)
            .WithMany()
            .HasForeignKey(b => b.BlockedId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
