namespace SomineApi.Application.DTOs.Categories;

public record CreateCategoryRequest(
    string Name,
    string? Icon,
    string? Color,
    bool IsVault = false
);

public record UpdateCategoryRequest(
    string? Name,
    string? Icon,
    string? Color,
    bool? IsVault
);

public record ReorderCategoriesRequest(
    List<CategoryOrderItem> Items
);

public record CategoryOrderItem(
    Guid Id,
    int SortOrder
);

public record CategoryDto(
    Guid Id,
    string Name,
    string? Icon,
    string? Color,
    int SortOrder,
    bool IsVault,
    DateTime CreatedAt,
    DateTime UpdatedAt
);
