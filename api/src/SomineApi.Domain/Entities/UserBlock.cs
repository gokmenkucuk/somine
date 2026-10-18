namespace SomineApi.Domain.Entities;

/// <summary>
/// Bir kullanıcının başka bir kullanıcıyı engellemesi (App Store 1.2 / UGC).
/// Engellenen kişi engelleyene paylaşım gönderemez; mevcut paylaşımlar engelleme
/// anında iki yönde de kapatılır. (BlockerId, BlockedId) çifti benzersizdir.
/// </summary>
public class UserBlock
{
    public Guid BlockerId { get; set; }
    public Guid BlockedId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public User Blocker { get; set; } = null!;
    public User Blocked { get; set; } = null!;
}
