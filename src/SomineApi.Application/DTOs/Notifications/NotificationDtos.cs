namespace SomineApi.Application.DTOs.Notifications;

public record NotificationDto(
    Guid Id,
    string Type,
    string Title,
    string Message,
    object? Data,
    bool IsRead,
    DateTime CreatedAt
);
