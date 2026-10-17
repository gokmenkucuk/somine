namespace SomineApi.Application.DTOs.Moderation;

/// <summary>
/// Şikâyet isteği. <c>Reason</c>: "spam", "inappropriate", "harassment", "other"
/// (büyük/küçük harf duyarsız). <c>Note</c> en fazla 500 karakter.
/// </summary>
public record ReportShareRequest(string? Reason, string? Note);

public record ContentReportDto(Guid Id, string Reason, string Status, DateTime CreatedAt);

public record BlockedUserDto(
    Guid UserId,
    string? DisplayName,
    string? Username,
    string? PhotoUrl,
    DateTime BlockedAt);
