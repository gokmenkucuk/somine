using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;

namespace SomineApi.Infrastructure.Configurations;

public class ItemConfiguration : IEntityTypeConfiguration<Item>
{
    public void Configure(EntityTypeBuilder<Item> builder)
    {
        builder.ToTable("items");

        builder.HasKey(i => i.Id);

        builder.Property(i => i.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(i => i.UserId).HasColumnName("user_id");
        builder.Property(i => i.CategoryId).HasColumnName("category_id");
        builder.Property(i => i.Type).HasColumnName("type").HasConversion<string>().IsRequired().HasDefaultValue(ItemType.Link);
        builder.Property(i => i.Url).HasColumnName("url");
        builder.Property(i => i.Note).HasColumnName("note");
        builder.Property(i => i.ImageUrl).HasColumnName("image_url");
        builder.Property(i => i.OgTitle).HasColumnName("og_title");
        builder.Property(i => i.OgDescription).HasColumnName("og_description");
        builder.Property(i => i.OgImageUrl).HasColumnName("og_image_url");
        builder.Property(i => i.OgSiteName).HasColumnName("og_site_name").HasMaxLength(128);
        builder.Property(i => i.OgFaviconUrl).HasColumnName("og_favicon_url");
        builder.Property(i => i.OgImageWidth).HasColumnName("og_image_width");
        builder.Property(i => i.OgImageHeight).HasColumnName("og_image_height");
        builder.Property(i => i.OgImageSourceUrl).HasColumnName("og_image_source_url");
        builder.Property(i => i.OgImageCacheFailedAt).HasColumnName("og_image_cache_failed_at");
        builder.Property(i => i.IsFavorite).HasColumnName("is_favorite").HasDefaultValue(false);
        builder.Property(i => i.IsDeleted).HasColumnName("is_deleted").HasDefaultValue(false);
        builder.Property(i => i.DeletedAt).HasColumnName("deleted_at");
        builder.Property(i => i.SortOrder).HasColumnName("sort_order").HasDefaultValue(0);
        builder.Property(i => i.HasReminder).HasColumnName("has_reminder").HasDefaultValue(false);
        builder.Property(i => i.ReminderId).HasColumnName("reminder_id");
        builder.Property(i => i.LastOpenedAt).HasColumnName("last_opened_at");
        builder.Property(i => i.OpenCount).HasColumnName("open_count").HasDefaultValue(0);
        builder.Property(i => i.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");
        builder.Property(i => i.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("NOW()");

        builder.HasIndex(i => i.UserId);
        builder.HasIndex(i => i.CategoryId);
        builder.HasIndex(i => new { i.UserId, i.IsDeleted });

        builder.HasOne(i => i.User)
            .WithMany(u => u.Items)
            .HasForeignKey(i => i.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(i => i.Category)
            .WithMany(c => c.Items)
            .HasForeignKey(i => i.CategoryId)
            .OnDelete(DeleteBehavior.SetNull);

        builder.HasOne(i => i.Reminder)
            .WithOne(r => r.Item)
            .HasForeignKey<Item>(i => i.ReminderId);
    }
}
