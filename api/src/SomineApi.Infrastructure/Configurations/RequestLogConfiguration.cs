using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SomineApi.Domain.Entities;

namespace SomineApi.Infrastructure.Configurations;

public class RequestLogConfiguration : IEntityTypeConfiguration<RequestLog>
{
    public void Configure(EntityTypeBuilder<RequestLog> builder)
    {
        builder.ToTable("request_logs");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(x => x.TraceId).HasColumnName("trace_id").HasMaxLength(128).IsRequired();
        builder.Property(x => x.RequestId).HasColumnName("request_id").HasMaxLength(128);
        builder.Property(x => x.UserId).HasColumnName("user_id");
        builder.Property(x => x.Method).HasColumnName("method").HasMaxLength(16).IsRequired();
        builder.Property(x => x.Path).HasColumnName("path").IsRequired();
        builder.Property(x => x.QueryString).HasColumnName("query_string");
        builder.Property(x => x.RouteTemplate).HasColumnName("route_template");
        builder.Property(x => x.ControllerName).HasColumnName("controller_name").HasMaxLength(128);
        builder.Property(x => x.ActionName).HasColumnName("action_name").HasMaxLength(128);
        builder.Property(x => x.StatusCode).HasColumnName("status_code").IsRequired();
        builder.Property(x => x.DurationMs).HasColumnName("duration_ms").IsRequired();
        builder.Property(x => x.IpAddress).HasColumnName("ip_address").HasMaxLength(64);
        builder.Property(x => x.UserAgent).HasColumnName("user_agent");
        builder.Property(x => x.ClientId).HasColumnName("client_id").HasMaxLength(128);
        builder.Property(x => x.Source).HasColumnName("source").HasMaxLength(32);
        builder.Property(x => x.RequestSizeBytes).HasColumnName("request_size_bytes");
        builder.Property(x => x.ResponseSizeBytes).HasColumnName("response_size_bytes");
        builder.Property(x => x.RequestHeadersJson).HasColumnName("request_headers_json");
        builder.Property(x => x.RequestBodyPreview).HasColumnName("request_body_preview");
        builder.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("NOW()");
        builder.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("NOW()");

        builder.HasIndex(x => x.CreatedAt);
        builder.HasIndex(x => x.UserId);
        builder.HasIndex(x => x.TraceId);
        builder.HasIndex(x => new { x.Path, x.CreatedAt });
    }
}
