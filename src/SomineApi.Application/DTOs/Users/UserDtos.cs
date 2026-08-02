namespace SomineApi.Application.DTOs.Users;

public record UpdateUserRequest(
    string? DisplayName,
    string? Username,
    string? PhotoUrl,
    string? PhotoBase64,
    bool? ClearPhoto = null,
    // IANA zaman dilimi kimliği (örn. "Europe/Istanbul"). Sunucu hatırlatıcı tetikleme anını buna göre hesaplar.
    string? TimeZoneId = null
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
