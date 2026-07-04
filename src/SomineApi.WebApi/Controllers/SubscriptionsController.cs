using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SomineApi.Application.DTOs.Subscriptions;
using SomineApi.Application.Interfaces;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Extensions;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("api/subscriptions")]
[Authorize]
public class SubscriptionsController : ControllerBase
{
    private readonly ISubscriptionStatusService _subscriptionStatusService;
    private readonly SomineDbContext _dbContext;

    public SubscriptionsController(ISubscriptionStatusService subscriptionStatusService, SomineDbContext dbContext)
    {
        _subscriptionStatusService = subscriptionStatusService;
        _dbContext = dbContext;
    }

    [HttpGet("status")]
    public async Task<ActionResult<SubscriptionStatusDto>> GetSubscriptionStatus([FromQuery] string? platform = null)
    {
        var userId = HttpContext.GetUserId();
        var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
            return NotFound(new { error = "User not found" });

        var status = await _subscriptionStatusService.GetStatusAsync(user, platform, HttpContext.RequestAborted);
        return Ok(status);
    }

    [HttpPost("verify")]
    public async Task<ActionResult<SubscriptionStatusDto>> VerifyReceipt([FromBody] VerifyReceiptRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Platform))
            return BadRequest(new { error = "Platform is required" });

        var userId = HttpContext.GetUserId();
        var user = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == userId);
        if (user == null)
            return NotFound(new { error = "User not found" });

        var normalizedPlatform = request.Platform.Trim().ToLowerInvariant();
        if (normalizedPlatform is not ("apple" or "ios" or "google" or "android"))
            return BadRequest(new { error = "Unsupported platform" });

        var status = await _subscriptionStatusService.GetStatusAsync(user, normalizedPlatform, HttpContext.RequestAborted);
        return Ok(status);
    }
}
