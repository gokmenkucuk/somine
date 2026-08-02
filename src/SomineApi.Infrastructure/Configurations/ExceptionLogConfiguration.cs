using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SomineApi.Domain.Entities;

namespace SomineApi.Infrastructure.Configurations;

public class ExceptionLogConfiguration : IEntityTypeConfiguration<ExceptionLog>
{
    public void Configure(EntityTypeBuilder<ExceptionLog> builder)
    {
        builder.ToTable("exception_logs");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(x => x.RequestLogId).HasColumnName("request_log_id");
        builder.Property(x => x.TraceId).HasColumnName("trace_id").HasMaxLength(128);
        builder.Property(x => x.UserId).HasColumnName("user_id");
        builder.Property(x => x.ExceptionType).HasColumnName("exception_type").HasMaxLength(256).IsRequired();
        builder.Property(x => x.Message).HasColumnName("message").IsRequired();
        builder.Property(x => x.StackTrace).HasColumnName("stack_trace");
        builder.Property(x => x.InnerExceptionJson).HasColumnName("inner_exception_json");
        builder.Property(x => x.Source).HasColumnName("source").HasMaxLength(32);
        builder.Property(x => x.Path).HasColumnName("path");
        builder.Property(x => x.Method).HasColumnName("method").HasMaxLength(16);
        builder.Property(x => x.QueryString).HasColumnName("query_string");
        builder.Property(x => x.IpAddress).HasColumnName("ip_address").HasMaxLength(64);
        builder.Property(x => x.UserAgent).HasColumnName("user_agent");
        builder.Property(x => x.ClientId).HasColumnName("client_id").HasMaxLength(128);
        builder.Property(x => x.IsHandled).HasColumnName("is_handled").IsRequired();
        builder.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");
        builder.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("NOW()");

        builder.HasIndex(x => x.CreatedAt);
        builder.HasIndex(x => x.UserId);
        builder.HasIndex(x => x.TraceId);
        builder.HasIndex(x => x.ExceptionType);
        builder.HasIndex(x => x.RequestLogId);

        builder.HasOne(x => x.RequestLog)
            .WithMany(r => r.ExceptionLogs)
            .HasForeignKey(x => x.RequestLogId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
