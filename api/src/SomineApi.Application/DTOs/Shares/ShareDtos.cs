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

/// <summary>Bu ayki paylaşım hakkı. Premium'da <c>Unlimited</c> true, sayılar bilgi amaçlı.</summary>
public record ShareQuotaDto(bool Unlimited, int Limit, int Used, int Remaining, DateTime ResetsAtUtc);
