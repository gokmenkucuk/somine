using SomineApi.Domain.Interfaces;

namespace SomineApi.Domain.Entities;

public class Category : IAuditableEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Icon { get; set; }
    public string? Color { get; set; }
    public int SortOrder { get; set; }
    public bool IsVault { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Alıcısız ("link ile paylaş") public link. base64url, 128-bit; null = link kapalı.
    // Koleksiyon başına tek link olduğu için token doğrudan burada tutulur.
    public string? PublicLinkToken { get; set; }
    public DateTime? PublicLinkCreatedAtUtc { get; set; }

    // Navigation properties
    public User User { get; set; } = null!;
    public ICollection<Item> Items { get; set; } = [];
    public ICollection<CollectionShare> Shares { get; set; } = [];
}
