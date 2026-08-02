using SomineApi.Domain.Enums;

namespace SomineApi.Application.DTOs.Items;

public record CreateItemRequest(
    string? Url,
    string? Note,
    string? ImageUrl,
    ItemType Type,
    Guid? CategoryId,
    string? OgTitle,
    string? OgDescription,
    string? OgImageUrl,
    string? OgSiteName,
    string? OgFaviconUrl,
    int? OgImageWidth = null,
    int? OgImageHeight = null
);

public record UpdateItemRequest(
    string? Url,
    string? Note,
    string? ImageUrl,
    Guid? CategoryId,
    bool? ClearCategory,
    string? OgTitle,
    string? OgDescription,
    string? OgImageUrl,
    string? OgSiteName,
    string? OgFaviconUrl,
    bool? IsFavorite,
    int? OgImageWidth = null,
    int? OgImageHeight = null
);

public record BatchMoveRequest(
    List<Guid> ItemIds,
    Guid TargetCategoryId
);

public record BatchDeleteRequest(
    List<Guid> ItemIds
);

public record BatchReorderRequest(
    List<ItemOrderItem> Items
);

public record ItemOrderItem(
    Guid Id,
    int SortOrder
);

public record CopyItemsRequest(
    List<Guid> ItemIds,
    Guid TargetCategoryId
);

public record ItemDto(
    Guid Id,
    Guid? CategoryId,
    ItemType Type,
    string? Url,
    string? Note,
    string? ImageUrl,
    string? OgTitle,
    string? OgDescription,
    string? OgImageUrl,
    string? OgSiteName,
    string? OgFaviconUrl,
    int? OgImageWidth,
    int? OgImageHeight,
    bool IsFavorite,
    bool HasReminder,
    int SortOrder,
    DateTime CreatedAt,
    DateTime UpdatedAt,
    DateTime? LastOpenedAt
);

public record PagedResult<T>(
    List<T> Items,
    int TotalCount,
    int Page,
    int Limit
);
