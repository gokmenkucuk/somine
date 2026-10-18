using SomineApi.Domain.Interfaces;

namespace SomineApi.Domain.Entities;

public class RequestLog : IAuditableEntity
{
    public Guid Id { get; set; }
    public string TraceId { get; set; } = string.Empty;
    public string? RequestId { get; set; }
    public Guid? UserId { get; set; }
    public string Method { get; set; } = string.Empty;
    public string Path { get; set; } = string.Empty;
    public string? QueryString { get; set; }
    public string? RouteTemplate { get; set; }
    public string? ControllerName { get; set; }
    public string? ActionName { get; set; }
    public int StatusCode { get; set; }
    public long DurationMs { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? ClientId { get; set; }
    public string? Source { get; set; }
    public long? RequestSizeBytes { get; set; }
    public long? ResponseSizeBytes { get; set; }
    public string? RequestHeadersJson { get; set; }
    public string? RequestBodyPreview { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<ExceptionLog> ExceptionLogs { get; set; } = [];
}
