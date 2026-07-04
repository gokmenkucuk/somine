namespace SomineApi.Application.DTOs.Users;

public record UpdateUserRequest(
    string? DisplayName,
    string? Username,
    string? PhotoUrl,
    string? PhotoBase64,
    bool? ClearPhoto = null
);

public record UserSearchResult(
    Guid Id,
    string? Username,
    string? DisplayName,
    string? PhotoUrl,
    string? Email,
    string? PhotoBase64
);

public record SearchHistoryDto(
    IReadOnlyList<string> Terms
);
