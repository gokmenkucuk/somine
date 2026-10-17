using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SomineApi.Application.DTOs.Auth;
using SomineApi.Application.DTOs.Moderation;
using SomineApi.Application.DTOs.Users;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Domain.Reminders;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Extensions;
using System.Text.Json;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("api/users")]
[Authorize]
public class UsersController : ControllerBase
{
    private const int SearchHistoryLimit = 10;
    private readonly SomineDbContext _dbContext;
    private readonly IStorageService _storageService;

    public UsersController(SomineDbContext dbContext, IStorageService storageService)
    {
        _dbContext = dbContext;
        _storageService = storageService;
    }

    [HttpGet("me")]
    public async Task<ActionResult<UserDto>> GetCurrentUser()
    {
        var userId = HttpContext.GetUserId();
        var user = await _dbContext.Users.FindAsync(userId);

        if (user == null)
            return NotFound(new { error = "User not found" });

        return Ok(new UserDto(user.Id, user.Email, user.DisplayName, user.Username, user.PhotoUrl, user.PhotoBase64, user.TimeZoneId));
    }

    [HttpGet("me/search-history")]
    public async Task<ActionResult<SearchHistoryDto>> GetCurrentUserSearchHistory()
    {
        var userId = HttpContext.GetUserId();
        var user = await _dbContext.Users.FindAsync(userId);

        if (user == null)
            return NotFound(new { error = "User not found" });

        return Ok(new SearchHistoryDto(ParseSearchHistory(user.SearchHistoryJson)));
    }

    [HttpPut("me/search-history")]
    public async Task<ActionResult<SearchHistoryDto>> UpdateCurrentUserSearchHistory([FromBody] SearchHistoryDto request)
    {
        var userId = HttpContext.GetUserId();
        var user = await _dbContext.Users.FindAsync(userId);

        if (user == null)
            return NotFound(new { error = "User not found" });

        var normalizedTerms = NormalizeSearchHistory(request.Terms);
        user.SearchHistoryJson = normalizedTerms.Count == 0
            ? null
            : JsonSerializer.Serialize(normalizedTerms);
        user.UpdatedAt = DateTime.UtcNow;

        await _dbContext.SaveChangesAsync();

        return Ok(new SearchHistoryDto(normalizedTerms));
    }

    // Push bildirimleri için cihazın FCM token'ını kaydeder / yeniler. Oturum açıldığında ve
    // token yenilendiğinde çağrılır. Token başka bir hesaba kayıtlıysa (aynı cihazda hesap
    // değişimi) bu kullanıcıya taşınır; böylece eski hesabın bildirimi bu cihaza düşmez.
    [HttpPut("me/device-token")]
    public async Task<IActionResult> RegisterDeviceToken([FromBody] RegisterDeviceTokenRequest request)
    {
        var userId = HttpContext.GetUserId();
        var token = request.Token?.Trim();

        if (string.IsNullOrEmpty(token) || token.Length > DeviceToken.MaxTokenLength)
            return BadRequest(new { error = "Invalid device token" });

        var platform = NormalizeDeviceField(request.Platform, DeviceToken.MaxPlatformLength)?.ToLowerInvariant();
        var locale = NormalizeDeviceField(request.Locale, DeviceToken.MaxLocaleLength);

        var userExists = await _dbContext.Users.AnyAsync(u => u.Id == userId);
        if (!userExists)
            return NotFound(new { error = "User not found" });

        for (var attempt = 0; ; attempt++)
        {
            var now = DateTime.UtcNow;
            var existing = await _dbContext.DeviceTokens.FirstOrDefaultAsync(t => t.Token == token);

            if (existing == null)
            {
                _dbContext.DeviceTokens.Add(new DeviceToken
                {
                    Id = Guid.NewGuid(),
                    UserId = userId,
                    Token = token,
                    Platform = platform,
                    Locale = locale,
                    CreatedAt = now,
                    UpdatedAt = now,
                    LastSeenAt = now
                });
            }
            else
            {
                existing.UserId = userId;
                existing.Platform = platform ?? existing.Platform;
                existing.Locale = locale ?? existing.Locale;
                existing.LastSeenAt = now;
            }

            try
            {
                await _dbContext.SaveChangesAsync();
                return NoContent();
            }
            catch (DbUpdateException) when (attempt == 0)
            {
                // Aynı token eşzamanlı iki istekle eklendi (benzersiz index); bir kez güncelleme olarak yeniden dene.
                _dbContext.ChangeTracker.Clear();
            }
        }
    }

    // Oturum kapatılırken bu cihazın token'ını siler; çıkış yapılmış cihaza push gitmez.
    // İdempotenttir; yalnız çağıranın kendi token'ı silinir.
    [HttpDelete("me/device-token")]
    public async Task<IActionResult> UnregisterDeviceToken([FromBody] UnregisterDeviceTokenRequest request)
    {
        var userId = HttpContext.GetUserId();
        var token = request.Token?.Trim();

        if (string.IsNullOrEmpty(token))
            return BadRequest(new { error = "Invalid device token" });

        await _dbContext.DeviceTokens
            .Where(t => t.UserId == userId && t.Token == token)
            .ExecuteDeleteAsync();

        return NoContent();
    }

    [HttpPut("me")]
    public async Task<ActionResult<UserDto>> UpdateCurrentUser([FromBody] UpdateUserRequest request)
    {
        var userId = HttpContext.GetUserId();
        var user = await _dbContext.Users.FindAsync(userId);

        if (user == null)
            return NotFound(new { error = "User not found" });

        if (request.DisplayName != null) user.DisplayName = request.DisplayName;
        if (request.Username != null)
        {
            var exists = await _dbContext.Users.AnyAsync(u => u.Username == request.Username && u.Id != userId);
            if (exists) return Conflict(new { error = "Username already taken" });
            user.Username = request.Username;
        }
        if (request.TimeZoneId != null)
        {
            var timeZoneId = request.TimeZoneId.Trim();
            if (timeZoneId.Length > ReminderTimeZones.MaxTimeZoneIdLength)
                return BadRequest(new { error = "Invalid time zone" });
            user.TimeZoneId = timeZoneId.Length == 0 ? null : timeZoneId;
        }
        if (request.PhotoUrl != null) user.PhotoUrl = request.PhotoUrl;
        if (request.PhotoBase64 != null) user.PhotoBase64 = request.PhotoBase64;
        if (request.ClearPhoto == true)
        {
            user.PhotoUrl = null;
            user.PhotoBase64 = null;
        }

        user.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        return Ok(new UserDto(user.Id, user.Email, user.DisplayName, user.Username, user.PhotoUrl, user.PhotoBase64, user.TimeZoneId));
    }

    [HttpDelete("me")]
    public async Task<IActionResult> DeleteCurrentUser()
    {
        var userId = HttpContext.GetUserId();
        var user = await _dbContext.Users.FindAsync(userId);

        if (user == null)
            return NotFound(new { error = "User not found" });

        var itemIds = await _dbContext.Items
            .IgnoreQueryFilters()
            .Where(i => i.UserId == userId)
            .Select(i => i.Id)
            .ToListAsync();

        await _dbContext.Reminders
            .Where(r => itemIds.Contains(r.ItemId))
            .ExecuteDeleteAsync();
        await _dbContext.Items
            .IgnoreQueryFilters()
            .Where(i => i.UserId == userId)
            .ExecuteDeleteAsync();
        await _dbContext.CollectionShares
            .Where(s => s.FromUserId == userId || s.ToUserId == userId)
            .ExecuteDeleteAsync();
        await _dbContext.Categories
            .Where(c => c.UserId == userId)
            .ExecuteDeleteAsync();
        await _dbContext.Notifications
            .Where(n => n.UserId == userId)
            .ExecuteDeleteAsync();
        await _dbContext.UserBlocks
            .Where(b => b.BlockerId == userId || b.BlockedId == userId)
            .ExecuteDeleteAsync();
        await _dbContext.ContentReports
            .Where(r => r.ReporterId == userId || r.ReportedUserId == userId)
            .ExecuteDeleteAsync();
        await _dbContext.AuthSessions
            .Where(s => s.UserId == userId)
            .ExecuteDeleteAsync();
        await _dbContext.DeviceTokens
            .Where(t => t.UserId == userId)
            .ExecuteDeleteAsync();

        var files = await _dbContext.UploadedFiles
            .Where(f => f.UserId == userId)
            .ToListAsync();
        foreach (var file in files)
        {
            try
            {
                await _storageService.DeleteAsync(file.StoredFileName);
            }
            catch
            {
                // Disk cleanup is best-effort; the DB record removal below is authoritative.
            }
        }
        _dbContext.UploadedFiles.RemoveRange(files);

        _dbContext.Users.Remove(user);
        await _dbContext.SaveChangesAsync();

        return NoContent();
    }

    // App Store 1.2 / UGC: kullanıcı engelleme.
    // Engelleme: (1) engellenenden gelen bekleyen istekleri reddeder, (2) engellenenin
    // daha önce paylaştığı koleksiyonlara erişimi kaldırır, (3) engellenen bundan sonra
    // engelleyene paylaşım gönderemez (SharesController "user not found" döner).
    // İdempotenttir; engellenene bildirim gitmez.
    [HttpPost("{blockedUserId:guid}/block")]
    public async Task<IActionResult> BlockUser(Guid blockedUserId)
    {
        var userId = HttpContext.GetUserId();

        if (blockedUserId == userId)
            return BadRequest(new { error = "Cannot block yourself" });

        var targetExists = await _dbContext.Users.AnyAsync(u => u.Id == blockedUserId);
        if (!targetExists)
            return NotFound(new { error = "User not found" });

        var alreadyBlocked = await _dbContext.UserBlocks
            .AnyAsync(b => b.BlockerId == userId && b.BlockedId == blockedUserId);
        if (!alreadyBlocked)
        {
            _dbContext.UserBlocks.Add(new UserBlock
            {
                BlockerId = userId,
                BlockedId = blockedUserId,
                CreatedAt = DateTime.UtcNow
            });
        }

        var now = DateTime.UtcNow;
        var incomingShares = await _dbContext.CollectionShares
            .Where(s => s.FromUserId == blockedUserId && s.ToUserId == userId && s.Status != ShareStatus.Rejected)
            .ToListAsync();
        foreach (var share in incomingShares)
        {
            share.Status = ShareStatus.Rejected;
            share.RejectedAt = now;
        }

        await _dbContext.SaveChangesAsync();
        return NoContent();
    }

    // Engeli kaldırır. Engelleme sırasında kapatılan paylaşımlar geri açılmaz.
    [HttpDelete("{blockedUserId:guid}/block")]
    public async Task<IActionResult> UnblockUser(Guid blockedUserId)
    {
        var userId = HttpContext.GetUserId();

        await _dbContext.UserBlocks
            .Where(b => b.BlockerId == userId && b.BlockedId == blockedUserId)
            .ExecuteDeleteAsync();

        return NoContent();
    }

    [HttpGet("blocked")]
    public async Task<ActionResult<List<BlockedUserDto>>> GetBlockedUsers()
    {
        var userId = HttpContext.GetUserId();

        var blocked = await _dbContext.UserBlocks
            .AsNoTracking()
            .Where(b => b.BlockerId == userId)
            .OrderByDescending(b => b.CreatedAt)
            .Select(b => new BlockedUserDto(
                b.BlockedId,
                b.Blocked.DisplayName,
                b.Blocked.Username,
                b.Blocked.PhotoUrl,
                b.CreatedAt))
            .ToListAsync();

        return Ok(blocked);
    }

    [HttpGet("search")]
    public async Task<ActionResult<List<UserSearchResult>>> SearchUsers([FromQuery] string q)
    {
        if (string.IsNullOrWhiteSpace(q) || q.Length < 2)
            return BadRequest(new { error = "Search query must be at least 2 characters" });

        var userId = HttpContext.GetUserId();
        var normalizedQuery = q.Trim().ToLower();

        var users = await _dbContext.Users
            .Where(u => u.Id != userId &&
                ((u.Username != null && u.Username.Contains(normalizedQuery)) ||
                 (u.Email != null && u.Email.Contains(normalizedQuery))))
            .Select(u => new UserSearchResult(
                u.Id,
                u.Username,
                u.DisplayName,
                u.PhotoUrl,
                u.Email,
                u.PhotoBase64))
            .Take(20)
            .ToListAsync();

        return Ok(users);
    }

    private static string? NormalizeDeviceField(string? value, int maxLength)
    {
        var trimmed = value?.Trim();
        if (string.IsNullOrEmpty(trimmed)) return null;
        return trimmed.Length <= maxLength ? trimmed : trimmed[..maxLength];
    }

    private static IReadOnlyList<string> ParseSearchHistory(string? searchHistoryJson)
    {
        if (string.IsNullOrWhiteSpace(searchHistoryJson))
        {
            return [];
        }

        try
        {
            return NormalizeSearchHistory(JsonSerializer.Deserialize<List<string>>(searchHistoryJson) ?? []);
        }
        catch (JsonException)
        {
            return [];
        }
    }

    private static List<string> NormalizeSearchHistory(IEnumerable<string>? terms)
    {
        if (terms == null)
        {
            return [];
        }

        var normalizedTerms = new List<string>();

        foreach (var rawTerm in terms)
        {
            var normalizedTerm = rawTerm?.Trim();
            if (string.IsNullOrWhiteSpace(normalizedTerm))
            {
                continue;
            }

            normalizedTerms.RemoveAll(term => string.Equals(term, normalizedTerm, StringComparison.OrdinalIgnoreCase));
            normalizedTerms.Add(normalizedTerm);

            if (normalizedTerms.Count == SearchHistoryLimit)
            {
                break;
            }
        }

        return normalizedTerms;
    }
}
