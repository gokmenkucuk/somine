using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SomineApi.Domain.Entities;

namespace SomineApi.Infrastructure.Configurations;

public class CategoryConfiguration : IEntityTypeConfiguration<Category>
{
    public void Configure(EntityTypeBuilder<Category> builder)
    {
        builder.ToTable("categories");

        builder.HasKey(c => c.Id);

        builder.Property(c => c.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(c => c.UserId).HasColumnName("user_id");
        builder.Property(c => c.Name).HasColumnName("name").IsRequired().HasMaxLength(128);
        builder.Property(c => c.Icon).HasColumnName("icon").HasMaxLength(64);
        builder.Property(c => c.Color).HasColumnName("color").HasMaxLength(32);
        builder.Property(c => c.SortOrder).HasColumnName("sort_order").HasDefaultValue(0);
        builder.Property(c => c.IsVault).HasColumnName("is_vault").HasDefaultValue(false);
        builder.Property(c => c.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");
        builder.Property(c => c.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("NOW()");
        builder.Property(c => c.PublicLinkToken).HasColumnName("public_link_token").HasMaxLength(64);
        builder.Property(c => c.PublicLinkCreatedAtUtc).HasColumnName("public_link_created_at_utc");

        builder.HasIndex(c => c.UserId);
        builder.HasIndex(c => c.PublicLinkToken).IsUnique();

        builder.HasOne(c => c.User)
            .WithMany(u => u.Categories)
            .HasForeignKey(c => c.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
