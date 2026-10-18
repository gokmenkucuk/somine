namespace SomineApi.Application.DTOs.Subscriptions;

public record SubscriptionStatusDto(
    bool IsActive,
    string? ProductId,
    DateTime? ExpiresAt,
    string? Platform
);

public record VerifyReceiptRequest(
    string ReceiptData,
    string Platform
);
