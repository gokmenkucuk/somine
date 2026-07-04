using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SomineApi.Domain.Entities;

namespace SomineApi.Infrastructure.Configurations;

public class UploadedFileConfiguration : IEntityTypeConfiguration<UploadedFile>
{
    public void Configure(EntityTypeBuilder<UploadedFile> builder)
    {
        builder.ToTable("uploaded_files");

        builder.HasKey(f => f.Id);

        builder.Property(f => f.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(f => f.UserId).HasColumnName("user_id").IsRequired();
        builder.Property(f => f.StoredFileName).HasColumnName("stored_file_name").IsRequired().HasMaxLength(512);
        builder.Property(f => f.OriginalFileName).HasColumnName("original_file_name").IsRequired().HasMaxLength(512);
        builder.Property(f => f.ContentType).HasColumnName("content_type").IsRequired().HasMaxLength(256);
        builder.Property(f => f.SizeBytes).HasColumnName("size_bytes").IsRequired();
        builder.Property(f => f.StorageProvider).HasColumnName("storage_provider").IsRequired().HasMaxLength(32).HasDefaultValue("Local");
        builder.Property(f => f.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");
        builder.Property(f => f.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("NOW()");

        builder.HasIndex(f => f.UserId);
        builder.HasIndex(f => f.StoredFileName).IsUnique();

        builder.HasOne(f => f.User)
            .WithMany(u => u.UploadedFiles)
            .HasForeignKey(f => f.UserId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
