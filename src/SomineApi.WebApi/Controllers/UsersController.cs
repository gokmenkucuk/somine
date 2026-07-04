using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SomineApi.Application.DTOs.Auth;
using SomineApi.Application.DTOs.Users;
using SomineApi.Application.Interfaces;
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

        return Ok(new UserDto(user.Id, user.Email, user.DisplayName, user.Username, user.PhotoUrl, user.PhotoBase64));
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
        if (request.PhotoUrl != null) user.PhotoUrl = request.PhotoUrl;
        if (request.PhotoBase64 != null) user.PhotoBase64 = request.PhotoBase64;
        if (request.ClearPhoto == true)
        {
            user.PhotoUrl = null;
            user.PhotoBase64 = null;
        }

        user.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();

        return Ok(new UserDto(user.Id, user.Email, user.DisplayName, user.Username, user.PhotoUrl, user.PhotoBase64));
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
        await _dbContext.AuthSessions
            .Where(s => s.UserId == userId)
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
