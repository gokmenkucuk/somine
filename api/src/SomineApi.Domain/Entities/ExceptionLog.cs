using SomineApi.Domain.Interfaces;

namespace SomineApi.Domain.Entities;

public class ExceptionLog : IAuditableEntity
{
    public Guid Id { get; set; }
    public Guid? RequestLogId { get; set; }
    public string? TraceId { get; set; }
    public Guid? UserId { get; set; }
    public string ExceptionType { get; set; } = string.Empty;
    public string Message { get; set; } = string.Empty;
    public string? StackTrace { get; set; }
    public string? InnerExceptionJson { get; set; }
    public string? Source { get; set; }
    public string? Path { get; set; }
    public string? Method { get; set; }
    public string? QueryString { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
    public string? ClientId { get; set; }
    public bool IsHandled { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public RequestLog? RequestLog { get; set; }
}
