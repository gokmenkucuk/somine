using SomineApi.Domain.Enums;
using SomineApi.Domain.Interfaces;

namespace SomineApi.Domain.Entities;

public class Item : IAuditableEntity
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public Guid? CategoryId { get; set; }
    public ItemType Type { get; set; } = ItemType.Link;
    public string? Url { get; set; }
    public string? Note { get; set; }
    public string? ImageUrl { get; set; }

    // OG Metadata (owned entity)
    public string? OgTitle { get; set; }
    public string? OgDescription { get; set; }
    public string? OgImageUrl { get; set; }
    public string? OgSiteName { get; set; }
    public string? OgFaviconUrl { get; set; }

    // OG görselinin piksel boyutları — istemci ölçer ve gönderir, sunucu ASLA indirmez/probe etmez.
    // İlk render'da en-boy oranı bilindiği için masonry düzeninde zıplama olmaz.
    public int? OgImageWidth { get; set; }
    public int? OgImageHeight { get; set; }

    public bool IsFavorite { get; set; }
    public bool IsDeleted { get; set; }
    public DateTime? DeletedAt { get; set; }
    public int SortOrder { get; set; }
    public bool HasReminder { get; set; }
    public Guid? ReminderId { get; set; }
    public DateTime? LastOpenedAt { get; set; }
    public int OpenCount { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    // Navigation properties
    public User User { get; set; } = null!;
    public Category? Category { get; set; }
    public Reminder? Reminder { get; set; }
}
