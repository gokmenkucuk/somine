using SomineApi.Domain.Enums;

namespace SomineApi.Domain.Entities;

public class CollectionShare
{
    public Guid Id { get; set; }
    public Guid FromUserId { get; set; }
    public Guid ToUserId { get; set; }
    public Guid CategoryId { get; set; }
    public string? FromUserName { get; set; }
    public string? FromUserEmail { get; set; }
    public string? ToUserEmail { get; set; }
    public string? CategoryName { get; set; }
    public ShareStatus Status { get; set; } = ShareStatus.Pending;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? AcceptedAt { get; set; }
    public DateTime? RejectedAt { get; set; }
    public string? PublicLinkToken { get; set; }   // base64url, 128-bit; null = link kapalı
    public DateTime? PublicLinkCreatedAtUtc { get; set; }

    // Navigation properties
    public User FromUser { get; set; } = null!;
    public User ToUser { get; set; } = null!;
    public Category Category { get; set; } = null!;
}
