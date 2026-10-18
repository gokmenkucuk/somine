using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;

namespace SomineApi.Infrastructure.Configurations;

public class ContentReportConfiguration : IEntityTypeConfiguration<ContentReport>
{
    public void Configure(EntityTypeBuilder<ContentReport> builder)
    {
        builder.ToTable("content_reports");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(r => r.ReporterId).HasColumnName("reporter_id");
        builder.Property(r => r.ReportedUserId).HasColumnName("reported_user_id");
        builder.Property(r => r.ShareId).HasColumnName("share_id");
        builder.Property(r => r.CategoryId).HasColumnName("category_id");
        builder.Property(r => r.Reason).HasColumnName("reason").HasConversion<string>().HasMaxLength(32);
        builder.Property(r => r.Note).HasColumnName("note").HasMaxLength(ContentReport.MaxNoteLength);
        builder.Property(r => r.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");
        builder.Property(r => r.Status).HasColumnName("status").HasConversion<string>().HasMaxLength(32)
            .HasDefaultValue(ReportStatus.Open);

        builder.HasIndex(r => new { r.Status, r.CreatedAt });
        builder.HasIndex(r => r.ReportedUserId);
        builder.HasIndex(r => r.ReporterId);

        builder.HasOne(r => r.Reporter)
            .WithMany()
            .HasForeignKey(r => r.ReporterId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(r => r.ReportedUser)
            .WithMany()
            .HasForeignKey(r => r.ReportedUserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
