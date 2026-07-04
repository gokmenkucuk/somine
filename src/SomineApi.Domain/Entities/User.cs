using SomineApi.Domain.Interfaces;

namespace SomineApi.Domain.Entities;

public class User : IAuditableEntity
{
    public Guid Id { get; set; }
    public string FirebaseUid { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string? DisplayName { get; set; }
    public string? Username { get; set; }
    public string? PhotoUrl { get; set; }
    public string? PhotoBase64 { get; set; }
    public string? SearchHistoryJson { get; set; }
    public DateTime? PremiumExpiresAtUtc { get; set; }
    public DateTime? PremiumCheckedAtUtc { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public ICollection<Category> Categories { get; set; } = [];
    public ICollection<Item> Items { get; set; } = [];
    public ICollection<Notification> Notifications { get; set; } = [];
    public ICollection<AuthSession> AuthSessions { get; set; } = [];
    public ICollection<UploadedFile> UploadedFiles { get; set; } = [];
}
