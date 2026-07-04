using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;

namespace SomineApi.Infrastructure.Configurations;

public class CollectionShareConfiguration : IEntityTypeConfiguration<CollectionShare>
{
    public void Configure(EntityTypeBuilder<CollectionShare> builder)
    {
        builder.ToTable("collection_shares");

        builder.HasKey(cs => cs.Id);

        builder.Property(cs => cs.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(cs => cs.FromUserId).HasColumnName("from_user_id");
        builder.Property(cs => cs.ToUserId).HasColumnName("to_user_id");
        builder.Property(cs => cs.CategoryId).HasColumnName("category_id");
        builder.Property(cs => cs.FromUserName).HasColumnName("from_user_name").HasMaxLength(128);
        builder.Property(cs => cs.FromUserEmail).HasColumnName("from_user_email").HasMaxLength(256);
        builder.Property(cs => cs.ToUserEmail).HasColumnName("to_user_email").HasMaxLength(256);
        builder.Property(cs => cs.CategoryName).HasColumnName("category_name").HasMaxLength(128);
        builder.Property(cs => cs.Status).HasColumnName("status").HasConversion<string>().HasDefaultValue(ShareStatus.Pending);
        builder.Property(cs => cs.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");
        builder.Property(cs => cs.AcceptedAt).HasColumnName("accepted_at");
        builder.Property(cs => cs.RejectedAt).HasColumnName("rejected_at");
        builder.Property(cs => cs.PublicLinkToken).HasColumnName("public_link_token").HasMaxLength(64);
        builder.Property(cs => cs.PublicLinkCreatedAtUtc).HasColumnName("public_link_created_at_utc");

        builder.HasIndex(cs => new { cs.ToUserId, cs.Status });
        builder.HasIndex(cs => cs.FromUserId);
        builder.HasIndex(cs => cs.PublicLinkToken).IsUnique();

        builder.HasOne(cs => cs.FromUser)
            .WithMany()
            .HasForeignKey(cs => cs.FromUserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(cs => cs.ToUser)
            .WithMany()
            .HasForeignKey(cs => cs.ToUserId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(cs => cs.Category)
            .WithMany(c => c.Shares)
            .HasForeignKey(cs => cs.CategoryId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
