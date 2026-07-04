using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SomineApi.Application.DTOs.Notifications;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Extensions;
using SomineApi.WebApi.Hubs;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("api/notifications")]
[Authorize]
public class NotificationsController : ControllerBase
{
    private readonly SomineDbContext _dbContext;
    private readonly IUserRealtimeEventPublisher _realtimeEventPublisher;

    public NotificationsController(
        SomineDbContext dbContext,
        IUserRealtimeEventPublisher realtimeEventPublisher)
    {
        _dbContext = dbContext;
        _realtimeEventPublisher = realtimeEventPublisher;
    }

    [HttpGet]
    public async Task<ActionResult<List<NotificationDto>>> GetNotifications()
    {
        var userId = HttpContext.GetUserId();

        var notifications = await _dbContext.Notifications
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt)
            .Take(50)
            .Select(n => new NotificationDto(
                n.Id, n.Type, n.Title, n.Message,
                n.Data != null ? System.Text.Json.JsonSerializer.Deserialize<object>(n.Data!) : null,
                n.IsRead, n.CreatedAt))
            .ToListAsync();

        return Ok(notifications);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<NotificationDto>> GetNotification(Guid id)
    {
        var userId = HttpContext.GetUserId();

        var notification = await _dbContext.Notifications
            .Where(n => n.Id == id && n.UserId == userId)
            .Select(n => new NotificationDto(
                n.Id, n.Type, n.Title, n.Message,
                n.Data != null ? System.Text.Json.JsonSerializer.Deserialize<object>(n.Data!) : null,
                n.IsRead, n.CreatedAt))
            .FirstOrDefaultAsync();

        if (notification == null)
            return NotFound(new { error = "Notification not found" });

        return Ok(notification);
    }

    [HttpPut("{id}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        var userId = HttpContext.GetUserId();
        var notification = await _dbContext.Notifications.FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId);

        if (notification == null) return NotFound(new { error = "Notification not found" });

        notification.IsRead = true;
        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishNotificationsChangedAsync(userId, "read", notification.Id, HttpContext.RequestAborted);

        return NoContent();
    }

    [HttpPut("read-all")]
    public async Task<IActionResult> MarkAllAsRead()
    {
        var userId = HttpContext.GetUserId();

        await _dbContext.Notifications
            .Where(n => n.UserId == userId && !n.IsRead)
            .ExecuteUpdateAsync(setters => setters.SetProperty(n => n.IsRead, true));
        await _realtimeEventPublisher.PublishNotificationsChangedAsync(userId, "read_all", null, HttpContext.RequestAborted);

        return NoContent();
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteNotification(Guid id)
    {
        var userId = HttpContext.GetUserId();
        var notification = await _dbContext.Notifications.FirstOrDefaultAsync(n => n.Id == id && n.UserId == userId);

        if (notification == null) return NotFound(new { error = "Notification not found" });

        var notificationId = notification.Id;
        _dbContext.Notifications.Remove(notification);
        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishNotificationsChangedAsync(userId, "deleted", notificationId, HttpContext.RequestAborted);

        return NoContent();
    }
}
