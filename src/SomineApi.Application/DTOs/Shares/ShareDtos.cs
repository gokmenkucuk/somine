namespace SomineApi.Application.DTOs.Shares;

public record CreateShareRequest(
    Guid CategoryId,
    string? ToUserEmail,
    Guid? ToUserId
);

public record ShareDto(
    Guid Id,
    Guid FromUserId,
    Guid ToUserId,
    Guid CategoryId,
    string? FromUserName,
    string? FromUserEmail,
    string? ToUserEmail,
    string? CategoryName,
    string Status,
    DateTime CreatedAt,
    DateTime? AcceptedAt,
    DateTime? RejectedAt,
    // Yalnızca paylaşımın sahibine (outgoing) gönderilir; alıcıya null gider
    string? PublicLinkToken = null
);
