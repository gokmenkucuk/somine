using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SomineApi.Application;
using SomineApi.Application.DTOs.Reminders;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Extensions;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("api/reminders")]
[Authorize]
public class RemindersController : ControllerBase
{
    private readonly SomineDbContext _dbContext;
    private readonly ISubscriptionTierService _subscriptionTierService;

    public RemindersController(SomineDbContext dbContext, ISubscriptionTierService subscriptionTierService)
    {
        _dbContext = dbContext;
        _subscriptionTierService = subscriptionTierService;
    }

    [HttpGet]
    public async Task<ActionResult<List<ReminderDto>>> GetReminders([FromQuery] Guid? itemId = null)
    {
        var userId = HttpContext.GetUserId();

        var query = _dbContext.Reminders
            .Where(r => r.Item.UserId == userId);

        if (itemId.HasValue)
        {
            query = query.Where(r => r.ItemId == itemId.Value);
        }

        var reminders = await query
            .OrderBy(r => r.CreatedAt)
            .Select(r => new ReminderDto(r.Id, r.ItemId, r.ReminderDate,
                r.ReminderHour, r.ReminderMinute, r.RepeatType,
                r.IsActive, r.CustomRepeatDays, r.CustomRepeatMinutes, r.CreatedAt))
            .ToListAsync();

        return Ok(reminders);
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ReminderDto>> GetReminder(Guid id)
    {
        var userId = HttpContext.GetUserId();

        var reminder = await _dbContext.Reminders
            .Where(r => r.Id == id && r.Item.UserId == userId)
            .Select(r => new ReminderDto(r.Id, r.ItemId, r.ReminderDate,
                r.ReminderHour, r.ReminderMinute, r.RepeatType,
                r.IsActive, r.CustomRepeatDays, r.CustomRepeatMinutes, r.CreatedAt))
            .FirstOrDefaultAsync();

        if (reminder == null) return NotFound(new { error = "Reminder not found" });

        return Ok(reminder);
    }

    [HttpPost]
    public async Task<ActionResult<ReminderDto>> CreateReminder([FromBody] CreateReminderRequest request)
    {
        var userId = HttpContext.GetUserId();

        if (!await _subscriptionTierService.IsPremiumForEnforcementAsync(userId, HttpContext.RequestAborted))
        {
            var current = await _dbContext.Reminders
                .CountAsync(r => r.IsActive && _dbContext.Items.Any(i => i.Id == r.ItemId && i.UserId == userId));
            if (current >= SubscriptionLimits.FreeMaxActiveReminders)
                return StatusCode(403, new
                {
                    error = "limit_reached",
                    message = "Ücretsiz planda en fazla 3 aktif hatırlatıcı kurabilirsiniz. Daha fazlası için Premium'a geçin.",
                    limit = SubscriptionLimits.FreeMaxActiveReminders,
                    current
                });
        }

        if (request.ReminderHour is < 0 or > 23 || request.ReminderMinute is < 0 or > 59)
            return BadRequest(new { error = "Invalid reminder time" });

        if (request.CustomRepeatDays is < 0 || request.CustomRepeatMinutes is < 0)
            return BadRequest(new { error = "Custom repeat values cannot be negative" });

        var item = await _dbContext.Items.FirstOrDefaultAsync(i => i.Id == request.ItemId && i.UserId == userId);
        if (item == null) return NotFound(new { error = "Item not found" });

        if (item.HasReminder)
            return Conflict(new { error = "Item already has a reminder" });

        var reminder = new Reminder
        {
            Id = Guid.NewGuid(),
            ItemId = request.ItemId,
            ReminderDate = request.ReminderDate,
            ReminderHour = request.ReminderHour,
            ReminderMinute = request.ReminderMinute,
            RepeatType = request.RepeatType,
            CustomRepeatDays = request.CustomRepeatDays,
            CustomRepeatMinutes = request.CustomRepeatMinutes,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.Reminders.Add(reminder);

        item.HasReminder = true;
        item.ReminderId = reminder.Id;
        item.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();

        return Ok(new ReminderDto(reminder.Id, reminder.ItemId, reminder.ReminderDate,
            reminder.ReminderHour, reminder.ReminderMinute, reminder.RepeatType,
            reminder.IsActive, reminder.CustomRepeatDays, reminder.CustomRepeatMinutes, reminder.CreatedAt));
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<ReminderDto>> UpdateReminder(Guid id, [FromBody] UpdateReminderRequest request)
    {
        var userId = HttpContext.GetUserId();

        var reminder = await _dbContext.Reminders
            .FirstOrDefaultAsync(r => r.Id == id && r.Item.UserId == userId);

        if (reminder == null) return NotFound(new { error = "Reminder not found" });

        if (request.ReminderHour is < 0 or > 23 || request.ReminderMinute is < 0 or > 59)
            return BadRequest(new { error = "Invalid reminder time" });

        if (request.CustomRepeatDays is < 0 || request.CustomRepeatMinutes is < 0)
            return BadRequest(new { error = "Custom repeat values cannot be negative" });

        if (request.IsActive == true && !reminder.IsActive &&
            !await _subscriptionTierService.IsPremiumForEnforcementAsync(userId, HttpContext.RequestAborted))
        {
            var current = await _dbContext.Reminders
                .CountAsync(r => r.IsActive && _dbContext.Items.Any(i => i.Id == r.ItemId && i.UserId == userId));
            if (current >= SubscriptionLimits.FreeMaxActiveReminders)
                return StatusCode(403, new
                {
                    error = "limit_reached",
                    message = "Ücretsiz planda en fazla 3 aktif hatırlatıcı kurabilirsiniz. Daha fazlası için Premium'a geçin.",
                    limit = SubscriptionLimits.FreeMaxActiveReminders,
                    current
                });
        }

        if (request.ReminderDate.HasValue) reminder.ReminderDate = request.ReminderDate.Value;
        if (request.ReminderHour.HasValue) reminder.ReminderHour = request.ReminderHour.Value;
        if (request.ReminderMinute.HasValue) reminder.ReminderMinute = request.ReminderMinute.Value;
        if (request.RepeatType.HasValue) reminder.RepeatType = request.RepeatType.Value;
        if (request.IsActive.HasValue) reminder.IsActive = request.IsActive.Value;
        if (request.CustomRepeatDays.HasValue) reminder.CustomRepeatDays = request.CustomRepeatDays.Value;
        if (request.CustomRepeatMinutes.HasValue) reminder.CustomRepeatMinutes = request.CustomRepeatMinutes.Value;

        await _dbContext.SaveChangesAsync();

        return Ok(new ReminderDto(reminder.Id, reminder.ItemId, reminder.ReminderDate,
            reminder.ReminderHour, reminder.ReminderMinute, reminder.RepeatType,
            reminder.IsActive, reminder.CustomRepeatDays, reminder.CustomRepeatMinutes, reminder.CreatedAt));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteReminder(Guid id)
    {
        var userId = HttpContext.GetUserId();

        var reminder = await _dbContext.Reminders
            .Include(r => r.Item)
            .FirstOrDefaultAsync(r => r.Id == id && r.Item.UserId == userId);

        if (reminder == null) return NotFound(new { error = "Reminder not found" });

        reminder.Item.HasReminder = false;
        reminder.Item.ReminderId = null;
        reminder.Item.UpdatedAt = DateTime.UtcNow;

        _dbContext.Reminders.Remove(reminder);
        await _dbContext.SaveChangesAsync();

        return NoContent();
    }
}
