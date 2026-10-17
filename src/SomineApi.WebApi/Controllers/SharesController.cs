using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SomineApi.Application;
using SomineApi.Application.DTOs.Items;
using SomineApi.Application.DTOs.Shares;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Domain.Notifications;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Extensions;
using SomineApi.WebApi.Hubs;
using SomineApi.WebApi.Options;
using System.Security.Cryptography;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("api/shares")]
[Authorize]
public class SharesController : ControllerBase
{
    private readonly SomineDbContext _dbContext;
    private readonly IUserRealtimeEventPublisher _realtimeEventPublisher;
    private readonly ISubscriptionTierService _subscriptionTierService;
    private readonly PublicWebOptions _publicWebOptions;

    public SharesController(
        SomineDbContext dbContext,
        IUserRealtimeEventPublisher realtimeEventPublisher,
        ISubscriptionTierService subscriptionTierService,
        IOptions<PublicWebOptions> publicWebOptions)
    {
        _dbContext = dbContext;
        _realtimeEventPublisher = realtimeEventPublisher;
        _subscriptionTierService = subscriptionTierService;
        _publicWebOptions = publicWebOptions.Value;
    }

    [HttpPost]
    public async Task<ActionResult<ShareDto>> CreateShare([FromBody] CreateShareRequest request)
    {
        var userId = HttpContext.GetUserId();

        if (!await _subscriptionTierService.IsPremiumForEnforcementAsync(userId, HttpContext.RequestAborted))
        {
            var current = await _dbContext.CollectionShares
                .CountAsync(s => s.FromUserId == userId && s.Status != ShareStatus.Rejected);
            if (current >= SubscriptionLimits.FreeMaxActiveShares)
                return StatusCode(403, new
                {
                    error = "limit_reached",
                    message = "Ücretsiz planda aynı anda 1 aktif paylaşımınız olabilir. Daha fazlası için Premium'a geçin.",
                    limit = SubscriptionLimits.FreeMaxActiveShares,
                    current
                });
        }

        var fromUser = await _dbContext.Users.FindAsync(userId);
        if (fromUser == null) return Unauthorized();

        User? toUser = null;
        if (request.ToUserId.HasValue)
        {
            toUser = await _dbContext.Users.FirstOrDefaultAsync(u => u.Id == request.ToUserId.Value);
        }

        if (toUser == null && !string.IsNullOrWhiteSpace(request.ToUserEmail))
        {
            var normalizedEmail = request.ToUserEmail.Trim().ToLowerInvariant();
            toUser = await _dbContext.Users.FirstOrDefaultAsync(u => u.Email != null && u.Email.ToLower() == normalizedEmail);
        }

        if (!request.ToUserId.HasValue && string.IsNullOrWhiteSpace(request.ToUserEmail))
            return BadRequest(new { error = "Target user identifier is required" });

        if (toUser == null) return NotFound(new { error = "Target user not found" });

        if (toUser.Id == userId)
            return BadRequest(new { error = "Cannot share with yourself" });

        var category = await _dbContext.Categories.FirstOrDefaultAsync(c => c.Id == request.CategoryId && c.UserId == userId);
        if (category == null) return NotFound(new { error = "Category not found" });

        if (category.IsVault)
            return BadRequest(new { error = "Vault categories cannot be shared" });

        var existingShare = await _dbContext.CollectionShares
            .AnyAsync(s => s.FromUserId == userId && s.ToUserId == toUser.Id && s.CategoryId == request.CategoryId && s.Status == ShareStatus.Pending);

        if (existingShare)
            return Conflict(new { error = "Share request already exists" });

        var share = new CollectionShare
        {
            Id = Guid.NewGuid(),
            FromUserId = userId,
            ToUserId = toUser.Id,
            CategoryId = request.CategoryId,
            FromUserName = fromUser.DisplayName,
            FromUserEmail = fromUser.Email,
            ToUserEmail = toUser.Email,
            CategoryName = category.Name,
            Status = ShareStatus.Pending,
            CreatedAt = DateTime.UtcNow
        };

        _dbContext.CollectionShares.Add(share);

        var notification = new Domain.Entities.Notification
        {
            Id = Guid.NewGuid(),
            UserId = toUser.Id,
            Type = NotificationTypes.ShareRequest,
            // Title/Message Türkçe kalıyor: bu sürümü tanımayan istemciler onları
            // olduğu gibi gösteriyor. Yeni istemciler metni aşağıdaki yapısal
            // alanlardan kendi dilinde kuruyor.
            Title = "Yeni Paylaşım İsteği",
            Message = $"{fromUser.DisplayName ?? fromUser.Email} \"{category.Name}\" koleksiyonunu sizinle paylaşmak istiyor.",
            Data = System.Text.Json.JsonSerializer.SerializeToDocument(new
            {
                shareId = share.Id,
                categoryId = category.Id,
                fromUserName = fromUser.DisplayName ?? fromUser.Email,
                categoryName = category.Name
            }),
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };
        _dbContext.Notifications.Add(notification);

        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishNotificationsChangedAsync(toUser.Id, "created", notification.Id, HttpContext.RequestAborted);

        return Ok(new ShareDto(share.Id, share.FromUserId, share.ToUserId, share.CategoryId,
            share.FromUserName, share.FromUserEmail, share.ToUserEmail, share.CategoryName,
            share.Status.ToString(), share.CreatedAt, share.AcceptedAt, share.RejectedAt));
    }

    [HttpGet("incoming")]
    public async Task<ActionResult<List<ShareDto>>> GetIncomingShares()
    {
        var userId = HttpContext.GetUserId();

        var shares = await _dbContext.CollectionShares
            .Where(s => s.ToUserId == userId)
            .OrderByDescending(s => s.CreatedAt)
            .Select(s => new ShareDto(s.Id, s.FromUserId, s.ToUserId, s.CategoryId,
                s.FromUserName, s.FromUserEmail, s.ToUserEmail, s.CategoryName,
                s.Status.ToString(), s.CreatedAt, s.AcceptedAt, s.RejectedAt))
            .ToListAsync();

        return Ok(shares);
    }

    [HttpGet("outgoing")]
    public async Task<ActionResult<List<ShareDto>>> GetOutgoingShares()
    {
        var userId = HttpContext.GetUserId();

        var shares = await _dbContext.CollectionShares
            .Where(s => s.FromUserId == userId)
            .OrderByDescending(s => s.CreatedAt)
            .Select(s => new ShareDto(s.Id, s.FromUserId, s.ToUserId, s.CategoryId,
                s.FromUserName, s.FromUserEmail, s.ToUserEmail, s.CategoryName,
                s.Status.ToString(), s.CreatedAt, s.AcceptedAt, s.RejectedAt,
                s.PublicLinkToken))
            .ToListAsync();

        return Ok(shares);
    }

    [HttpGet("{id}/items")]
    public async Task<ActionResult<List<ItemDto>>> GetShareItems(Guid id)
    {
        var userId = HttpContext.GetUserId();

        var share = await _dbContext.CollectionShares
            .FirstOrDefaultAsync(s => s.Id == id && (s.FromUserId == userId || s.ToUserId == userId));

        if (share == null) return NotFound(new { error = "Share not found" });

        if (share.ToUserId == userId && share.Status != ShareStatus.Accepted)
            return BadRequest(new { error = "Share is not accepted" });

        var items = await _dbContext.Items
            .Where(i => i.UserId == share.FromUserId && i.CategoryId == share.CategoryId)
            .OrderBy(i => i.SortOrder).ThenByDescending(i => i.CreatedAt)
            .Select(i => new ItemDto(
                i.Id, i.CategoryId, i.Type, i.Url, i.Note, i.ImageUrl,
                i.OgTitle, i.OgDescription, i.OgImageUrl, i.OgSiteName, i.OgFaviconUrl,
                i.OgImageWidth, i.OgImageHeight,
                i.IsFavorite, i.HasReminder, i.SortOrder, i.CreatedAt, i.UpdatedAt, i.LastOpenedAt))
            .ToListAsync();

        return Ok(items);
    }

    [HttpPut("{id}/accept")]
    public async Task<IActionResult> AcceptShare(Guid id)
    {
        var userId = HttpContext.GetUserId();
        var share = await _dbContext.CollectionShares.FirstOrDefaultAsync(s => s.Id == id && s.ToUserId == userId);

        if (share == null) return NotFound(new { error = "Share not found" });
        if (share.Status != ShareStatus.Pending) return BadRequest(new { error = "Share is not pending" });

        share.Status = ShareStatus.Accepted;
        share.AcceptedAt = DateTime.UtcNow;

        var notification = new Domain.Entities.Notification
        {
            Id = Guid.NewGuid(),
            UserId = share.FromUserId,
            Type = NotificationTypes.ShareAccepted,
            Title = "Paylaşım Kabul Edildi",
            Message = $"Paylaşım isteğiniz kabul edildi: {share.CategoryName}",
            Data = System.Text.Json.JsonSerializer.SerializeToDocument(new
            {
                shareId = share.Id,
                categoryId = share.CategoryId,
                categoryName = share.CategoryName
            }),
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };
        _dbContext.Notifications.Add(notification);

        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishNotificationsChangedAsync(share.FromUserId, "created", notification.Id, HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPut("{id}/reject")]
    public async Task<IActionResult> RejectShare(Guid id)
    {
        var userId = HttpContext.GetUserId();
        var share = await _dbContext.CollectionShares.FirstOrDefaultAsync(s => s.Id == id && s.ToUserId == userId);

        if (share == null) return NotFound(new { error = "Share not found" });
        if (share.Status != ShareStatus.Pending) return BadRequest(new { error = "Share is not pending" });

        share.Status = ShareStatus.Rejected;
        share.RejectedAt = DateTime.UtcNow;

        var notification = new Domain.Entities.Notification
        {
            Id = Guid.NewGuid(),
            UserId = share.FromUserId,
            Type = NotificationTypes.ShareRejected,
            Title = "Paylaşım Reddedildi",
            Message = $"Paylaşım isteğiniz reddedildi: {share.CategoryName}",
            Data = System.Text.Json.JsonSerializer.SerializeToDocument(new
            {
                shareId = share.Id,
                categoryId = share.CategoryId,
                categoryName = share.CategoryName
            }),
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };
        _dbContext.Notifications.Add(notification);

        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishNotificationsChangedAsync(share.FromUserId, "created", notification.Id, HttpContext.RequestAborted);
        return NoContent();
    }

    // Sahibi için: koleksiyona güvenli, herkese açık paylaşım linki üretir (varsa döndürür değil, rotate eder).
    [HttpPost("{id}/public-link")]
    public async Task<ActionResult<PublicLinkDto>> CreatePublicLink(Guid id)
    {
        var userId = HttpContext.GetUserId();
        var share = await _dbContext.CollectionShares.FirstOrDefaultAsync(s => s.Id == id && s.FromUserId == userId);

        if (share == null) return NotFound(new { error = "Share not found" });

        var category = await _dbContext.Categories.FirstOrDefaultAsync(c => c.Id == share.CategoryId);
        if (category != null && category.IsVault)
            return BadRequest(new { error = "Vault categories cannot be shared publicly" });

        // 128-bit rastgele token, base64url (padding'siz)
        var token = ToBase64Url(RandomNumberGenerator.GetBytes(16));

        share.PublicLinkToken = token;
        share.PublicLinkCreatedAtUtc = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();

        var url = $"{_publicWebOptions.BaseUrl.TrimEnd('/')}/s/{token}";
        return Ok(new PublicLinkDto(token, url));
    }

    // Sahibi için: herkese açık linki iptal eder.
    [HttpDelete("{id}/public-link")]
    public async Task<IActionResult> DeletePublicLink(Guid id)
    {
        var userId = HttpContext.GetUserId();
        var share = await _dbContext.CollectionShares.FirstOrDefaultAsync(s => s.Id == id && s.FromUserId == userId);

        if (share == null) return NotFound(new { error = "Share not found" });

        share.PublicLinkToken = null;
        share.PublicLinkCreatedAtUtc = null;
        await _dbContext.SaveChangesAsync();

        return NoContent();
    }

    private static string ToBase64Url(byte[] bytes) =>
        Convert.ToBase64String(bytes)
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');

    [HttpDelete("{id}")]
    public async Task<IActionResult> RevokeShare(Guid id)
    {
        var userId = HttpContext.GetUserId();
        var share = await _dbContext.CollectionShares.FirstOrDefaultAsync(s => s.Id == id && s.FromUserId == userId);

        if (share == null) return NotFound(new { error = "Share not found" });

        _dbContext.CollectionShares.Remove(share);
        await _dbContext.SaveChangesAsync();

        return NoContent();
    }
}
