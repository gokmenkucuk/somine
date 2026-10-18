using SomineApi.Domain.Enums;

namespace SomineApi.Application.DTOs.Shares;

// Sahibi için üretilen public link yanıtı
public record PublicLinkDto(
    string Token,
    string Url
);

// Anonim ziyaretçiye dönen koleksiyon görünümü. Kullanıcı kimlikleri ASLA yer almaz.
public record PublicShareDto(
    string CategoryName,
    string? FromUserName,
    IReadOnlyList<PublicItemDto> Items
);

// ItemDto'nun herkese açık alt kümesi (userId yok).
public record PublicItemDto(
    Guid Id,
    ItemType Type,
    string? Url,
    string? Note,
    string? ImageUrl,
    string? OgTitle,
    string? OgDescription,
    string? OgImageUrl,
    string? OgSiteName,
    string? OgFaviconUrl,
    DateTime CreatedAt
);
