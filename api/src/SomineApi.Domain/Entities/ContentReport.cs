using SomineApi.Domain.Enums;

namespace SomineApi.Domain.Entities;

/// <summary>
/// Kullanıcının paylaşılan bir içeriği şikâyet etmesi (App Store 1.2 / UGC).
/// ShareId/CategoryId bilerek FK değildir: paylaşım geri çekilse ya da koleksiyon
/// silinse bile şikâyet kaydı inceleme için kalmalı.
/// </summary>
public class ContentReport
{
    public const int MaxNoteLength = 500;

    public Guid Id { get; set; }
    public Guid ReporterId { get; set; }
    public Guid ReportedUserId { get; set; }
    public Guid? ShareId { get; set; }
    public Guid? CategoryId { get; set; }
    public ReportReason Reason { get; set; }
    public string? Note { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public ReportStatus Status { get; set; } = ReportStatus.Open;

    // Navigation properties
    public User Reporter { get; set; } = null!;
    public User ReportedUser { get; set; } = null!;
}
