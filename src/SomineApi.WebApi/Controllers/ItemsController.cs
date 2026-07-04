using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SomineApi.Application;
using SomineApi.Application.DTOs.Items;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Extensions;
using SomineApi.WebApi.Hubs;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("api/items")]
[Authorize]
public class ItemsController : ControllerBase
{
    private readonly SomineDbContext _dbContext;
    private readonly IUserRealtimeEventPublisher _realtimeEventPublisher;
    private readonly ISubscriptionTierService _subscriptionTierService;

    public ItemsController(
        SomineDbContext dbContext,
        IUserRealtimeEventPublisher realtimeEventPublisher,
        ISubscriptionTierService subscriptionTierService)
    {
        _dbContext = dbContext;
        _realtimeEventPublisher = realtimeEventPublisher;
        _subscriptionTierService = subscriptionTierService;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<ItemDto>>> GetItems(
        [FromQuery] Guid? categoryId,
        [FromQuery] int page = 1,
        [FromQuery] int limit = 50,
        [FromQuery] bool includeDeleted = false)
    {
        var userId = HttpContext.GetUserId();

        if (page < 1 || limit < 1 || limit > 100)
            return BadRequest(new { error = "Invalid pagination values" });

        if (categoryId.HasValue && !await CategoryBelongsToUserAsync(categoryId.Value, userId))
            return NotFound(new { error = "Category not found" });

        var query = _dbContext.Items
            .IgnoreQueryFilters()
            .Where(i => i.UserId == userId);

        if (!includeDeleted)
            query = query.Where(i => !i.IsDeleted);

        if (categoryId.HasValue)
            query = query.Where(i => i.CategoryId == categoryId.Value);

        var totalCount = await query.CountAsync();

        IOrderedQueryable<Item> orderedQuery;
        if (categoryId.HasValue)
            orderedQuery = query.OrderBy(i => i.SortOrder).ThenByDescending(i => i.CreatedAt);
        else
            orderedQuery = query.OrderByDescending(i => i.CreatedAt);

        var items = await orderedQuery
            .Skip((page - 1) * limit)
            .Take(limit)
            .Select(i => new ItemDto(
                i.Id, i.CategoryId, i.Type, i.Url, i.Note, i.ImageUrl,
                i.OgTitle, i.OgDescription, i.OgImageUrl, i.OgSiteName, i.OgFaviconUrl,
                i.IsFavorite, i.HasReminder, i.SortOrder, i.CreatedAt, i.UpdatedAt))
            .ToListAsync();

        return Ok(new PagedResult<ItemDto>(items, totalCount, page, limit));
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<ItemDto>> GetItem(Guid id)
    {
        var userId = HttpContext.GetUserId();
        var item = await _dbContext.Items
            .IgnoreQueryFilters()
            .Where(i => i.Id == id && i.UserId == userId)
            .Select(i => new ItemDto(
                i.Id, i.CategoryId, i.Type, i.Url, i.Note, i.ImageUrl,
                i.OgTitle, i.OgDescription, i.OgImageUrl, i.OgSiteName, i.OgFaviconUrl,
                i.IsFavorite, i.HasReminder, i.SortOrder, i.CreatedAt, i.UpdatedAt))
            .FirstOrDefaultAsync();

        if (item == null)
            return NotFound(new { error = "Item not found" });

        return Ok(item);
    }

    [HttpPost]
    public async Task<ActionResult<ItemDto>> CreateItem([FromBody] CreateItemRequest request)
    {
        var userId = HttpContext.GetUserId();

        if (!await _subscriptionTierService.IsPremiumForEnforcementAsync(userId, HttpContext.RequestAborted))
        {
            var current = await _dbContext.Items.CountAsync(i => i.UserId == userId);
            if (current >= SubscriptionLimits.FreeMaxItems)
                return StatusCode(403, new
                {
                    error = "limit_reached",
                    message = "Ücretsiz planda en fazla 500 içerik kaydedebilirsiniz. Sınırsız içerik için Premium'a geçin.",
                    limit = SubscriptionLimits.FreeMaxItems,
                    current
                });
        }

        if (request.CategoryId.HasValue && !await CategoryBelongsToUserAsync(request.CategoryId.Value, userId))
            return BadRequest(new { error = "Target category is invalid" });

        if (!await IsOwnedStorageUrlAsync(request.ImageUrl, userId))
            return BadRequest(new { error = "ImageUrl must reference a file owned by the current user" });

        var siblingItems = await _dbContext.Items
            .IgnoreQueryFilters()
            .Where(i => i.UserId == userId && i.CategoryId == request.CategoryId)
            .ToListAsync();

        foreach (var siblingItem in siblingItems)
        {
            siblingItem.SortOrder += 1;
            siblingItem.UpdatedAt = DateTime.UtcNow;
        }

        var item = new Item
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CategoryId = request.CategoryId,
            Type = request.Type,
            Url = request.Url,
            Note = request.Note,
            ImageUrl = request.ImageUrl,
            OgTitle = request.OgTitle,
            OgDescription = request.OgDescription,
            OgImageUrl = request.OgImageUrl,
            OgSiteName = request.OgSiteName,
            OgFaviconUrl = request.OgFaviconUrl,
            SortOrder = 0,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _dbContext.Items.Add(item);
        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishItemsChangedAsync(userId, "created", item.Id, HttpContext.RequestAborted);

        return CreatedAtAction(nameof(GetItem), new { id = item.Id }, new ItemDto(
            item.Id, item.CategoryId, item.Type, item.Url, item.Note, item.ImageUrl,
            item.OgTitle, item.OgDescription, item.OgImageUrl, item.OgSiteName, item.OgFaviconUrl,
            item.IsFavorite, item.HasReminder, item.SortOrder, item.CreatedAt, item.UpdatedAt));
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<ItemDto>> UpdateItem(Guid id, [FromBody] UpdateItemRequest request)
    {
        var userId = HttpContext.GetUserId();
        var item = await _dbContext.Items.FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId);

        if (item == null)
            return NotFound(new { error = "Item not found" });

        if (request.CategoryId.HasValue && !await CategoryBelongsToUserAsync(request.CategoryId.Value, userId))
            return BadRequest(new { error = "Target category is invalid" });

        if (!await IsOwnedStorageUrlAsync(request.ImageUrl, userId))
            return BadRequest(new { error = "ImageUrl must reference a file owned by the current user" });

        if (request.Url != null) item.Url = request.Url;
        if (request.Note != null) item.Note = request.Note;
        if (request.ImageUrl != null) item.ImageUrl = request.ImageUrl;
        if (request.ClearCategory == true)
        {
            item.CategoryId = null;
        }
        else if (request.CategoryId.HasValue)
        {
            item.CategoryId = request.CategoryId;
        }
        if (request.OgTitle != null) item.OgTitle = request.OgTitle;
        if (request.OgDescription != null) item.OgDescription = request.OgDescription;
        if (request.OgImageUrl != null) item.OgImageUrl = request.OgImageUrl;
        if (request.OgSiteName != null) item.OgSiteName = request.OgSiteName;
        if (request.OgFaviconUrl != null) item.OgFaviconUrl = request.OgFaviconUrl;
        if (request.IsFavorite.HasValue) item.IsFavorite = request.IsFavorite.Value;

        item.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishItemsChangedAsync(userId, "updated", item.Id, HttpContext.RequestAborted);

        return Ok(new ItemDto(
            item.Id, item.CategoryId, item.Type, item.Url, item.Note, item.ImageUrl,
            item.OgTitle, item.OgDescription, item.OgImageUrl, item.OgSiteName, item.OgFaviconUrl,
            item.IsFavorite, item.HasReminder, item.SortOrder, item.CreatedAt, item.UpdatedAt));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> SoftDeleteItem(Guid id)
    {
        var userId = HttpContext.GetUserId();
        var item = await _dbContext.Items
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId);

        if (item == null)
            return NotFound(new { error = "Item not found" });

        item.IsDeleted = true;
        item.DeletedAt = DateTime.UtcNow;
        item.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishItemsChangedAsync(userId, "deleted", item.Id, HttpContext.RequestAborted);

        return NoContent();
    }

    [HttpPost("batch-move")]
    public async Task<IActionResult> BatchMove([FromBody] BatchMoveRequest request)
    {
        var userId = HttpContext.GetUserId();

        if (request.ItemIds.Count == 0)
            return BadRequest(new { error = "No items provided" });

        if (!await CategoryBelongsToUserAsync(request.TargetCategoryId, userId))
            return BadRequest(new { error = "Target category is invalid" });

        var items = await _dbContext.Items
            .IgnoreQueryFilters()
            .Where(i => request.ItemIds.Contains(i.Id) && i.UserId == userId)
            .ToListAsync();

        if (items.Count != request.ItemIds.Distinct().Count())
            return NotFound(new { error = "One or more items were not found" });

        foreach (var item in items)
        {
            item.CategoryId = request.TargetCategoryId;
            item.UpdatedAt = DateTime.UtcNow;
        }

        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishItemsChangedAsync(userId, "batch_moved", null, HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPost("batch-delete")]
    public async Task<IActionResult> BatchDelete([FromBody] BatchDeleteRequest request)
    {
        var userId = HttpContext.GetUserId();

        if (request.ItemIds.Count == 0)
            return BadRequest(new { error = "No items provided" });

        var items = await _dbContext.Items
            .IgnoreQueryFilters()
            .Where(i => request.ItemIds.Contains(i.Id) && i.UserId == userId)
            .ToListAsync();

        if (items.Count != request.ItemIds.Distinct().Count())
            return NotFound(new { error = "One or more items were not found" });

        foreach (var item in items)
        {
            item.IsDeleted = true;
            item.DeletedAt = DateTime.UtcNow;
            item.UpdatedAt = DateTime.UtcNow;
        }

        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishItemsChangedAsync(userId, "batch_deleted", null, HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpPatch("batch-reorder")]
    public async Task<IActionResult> BatchReorder([FromBody] BatchReorderRequest request)
    {
        var userId = HttpContext.GetUserId();

        if (request.Items.Count == 0)
            return BadRequest(new { error = "No items provided" });

        var itemIds = request.Items.Select(i => i.Id).ToList();
        var items = await _dbContext.Items
            .Where(i => itemIds.Contains(i.Id) && i.UserId == userId)
            .ToListAsync();

        if (items.Count != itemIds.Distinct().Count())
            return NotFound(new { error = "One or more items were not found" });

        foreach (var orderItem in request.Items)
        {
            var item = items.FirstOrDefault(i => i.Id == orderItem.Id);
            if (item != null)
            {
                item.SortOrder = orderItem.SortOrder;
                item.UpdatedAt = DateTime.UtcNow;
            }
        }

        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishItemsChangedAsync(userId, "reordered", null, HttpContext.RequestAborted);
        return NoContent();
    }

    [HttpGet("favorites")]
    public async Task<ActionResult<List<ItemDto>>> GetFavorites()
    {
        var userId = HttpContext.GetUserId();

        var items = await _dbContext.Items
            .Where(i => i.UserId == userId && i.IsFavorite)
            .OrderByDescending(i => i.UpdatedAt)
            .Select(i => new ItemDto(
                i.Id, i.CategoryId, i.Type, i.Url, i.Note, i.ImageUrl,
                i.OgTitle, i.OgDescription, i.OgImageUrl, i.OgSiteName, i.OgFaviconUrl,
                i.IsFavorite, i.HasReminder, i.SortOrder, i.CreatedAt, i.UpdatedAt))
            .ToListAsync();

        return Ok(items);
    }

    [HttpGet("search")]
    public async Task<ActionResult<PagedResult<ItemDto>>> SearchItems(
        [FromQuery] string? q,
        [FromQuery] int page = 1,
        [FromQuery] int limit = 20)
    {
        if (page < 1 || limit < 1 || limit > 100)
            return BadRequest(new { error = "Invalid pagination values" });

        var userId = HttpContext.GetUserId();

        var query = _dbContext.Items.Where(i => i.UserId == userId);

        if (!string.IsNullOrWhiteSpace(q))
        {
            var searchTerm = q.ToLower();
            query = query.Where(i =>
                 (i.Url != null && i.Url.ToLower().Contains(searchTerm)) ||
                 (i.Note != null && i.Note.ToLower().Contains(searchTerm)) ||
                 (i.OgTitle != null && i.OgTitle.ToLower().Contains(searchTerm)) ||
                 (i.OgDescription != null && i.OgDescription.ToLower().Contains(searchTerm)));
        }

        var totalCount = await query.CountAsync();

        var items = await query
            .OrderByDescending(i => i.UpdatedAt)
            .Skip((page - 1) * limit)
            .Take(limit)
            .Select(i => new ItemDto(
                i.Id, i.CategoryId, i.Type, i.Url, i.Note, i.ImageUrl,
                i.OgTitle, i.OgDescription, i.OgImageUrl, i.OgSiteName, i.OgFaviconUrl,
                i.IsFavorite, i.HasReminder, i.SortOrder, i.CreatedAt, i.UpdatedAt))
            .ToListAsync();

        return Ok(new PagedResult<ItemDto>(items, totalCount, page, limit));
    }

    [HttpGet("deleted")]
    public async Task<ActionResult<List<ItemDto>>> GetDeletedItems()
    {
        var userId = HttpContext.GetUserId();

        var items = await _dbContext.Items
            .IgnoreQueryFilters()
            .Where(i => i.UserId == userId && i.IsDeleted)
            .OrderByDescending(i => i.DeletedAt)
            .Select(i => new ItemDto(
                i.Id, i.CategoryId, i.Type, i.Url, i.Note, i.ImageUrl,
                i.OgTitle, i.OgDescription, i.OgImageUrl, i.OgSiteName, i.OgFaviconUrl,
                i.IsFavorite, i.HasReminder, i.SortOrder, i.CreatedAt, i.UpdatedAt))
            .ToListAsync();

        return Ok(items);
    }

    [HttpPost("{id}/restore")]
    public async Task<IActionResult> RestoreItem(Guid id)
    {
        var userId = HttpContext.GetUserId();
        var item = await _dbContext.Items
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId);

        if (item == null)
            return NotFound(new { error = "Item not found" });

        if (!await _subscriptionTierService.IsPremiumForEnforcementAsync(userId, HttpContext.RequestAborted))
        {
            var current = await _dbContext.Items.CountAsync(i => i.UserId == userId);
            if (current >= SubscriptionLimits.FreeMaxItems)
                return StatusCode(403, new
                {
                    error = "limit_reached",
                    message = "Ücretsiz planda en fazla 500 içerik kaydedebilirsiniz. Sınırsız içerik için Premium'a geçin.",
                    limit = SubscriptionLimits.FreeMaxItems,
                    current
                });
        }

        item.IsDeleted = false;
        item.DeletedAt = null;
        item.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishItemsChangedAsync(userId, "restored", item.Id, HttpContext.RequestAborted);

        return NoContent();
    }

    [HttpDelete("{id}/permanent")]
    public async Task<IActionResult> PermanentDeleteItem(Guid id)
    {
        var userId = HttpContext.GetUserId();
        var item = await _dbContext.Items
            .IgnoreQueryFilters()
            .FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId);

        if (item == null)
            return NotFound(new { error = "Item not found" });

        _dbContext.Items.Remove(item);
        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishItemsChangedAsync(userId, "permanently_deleted", item.Id, HttpContext.RequestAborted);

        return NoContent();
    }

    [HttpPost("copy")]
    public async Task<IActionResult> CopyItems([FromBody] CopyItemsRequest request)
    {
        var userId = HttpContext.GetUserId();
        var distinctItemCount = request.ItemIds.Distinct().Count();

        if (!await _subscriptionTierService.IsPremiumForEnforcementAsync(userId, HttpContext.RequestAborted))
        {
            var current = await _dbContext.Items.CountAsync(i => i.UserId == userId);
            if (current + distinctItemCount > SubscriptionLimits.FreeMaxItems)
                return StatusCode(403, new
                {
                    error = "limit_reached",
                    message = "Ücretsiz planda en fazla 500 içerik kaydedebilirsiniz. Sınırsız içerik için Premium'a geçin.",
                    limit = SubscriptionLimits.FreeMaxItems,
                    current
                });
        }

        if (request.ItemIds.Count == 0)
            return BadRequest(new { error = "No items provided" });

        if (!await CategoryBelongsToUserAsync(request.TargetCategoryId, userId))
            return BadRequest(new { error = "Target category is invalid" });

        var sharedCategoryIds = await _dbContext.CollectionShares
            .Where(s => s.ToUserId == userId && s.Status == ShareStatus.Accepted)
            .Select(s => (Guid?)s.CategoryId)
            .ToListAsync();

        var sourceItems = await _dbContext.Items
            .IgnoreQueryFilters()
            .Where(i => request.ItemIds.Contains(i.Id) && !i.IsDeleted &&
                (i.UserId == userId || (i.CategoryId != null && sharedCategoryIds.Contains(i.CategoryId))))
            .ToListAsync();

        if (sourceItems.Count != request.ItemIds.Distinct().Count())
            return NotFound(new { error = "One or more items were not found" });

        foreach (var source in sourceItems)
        {
            var copy = new Item
            {
                Id = Guid.NewGuid(),
                UserId = userId,
                CategoryId = request.TargetCategoryId,
                Type = source.Type,
                Url = source.Url,
                Note = source.Note,
                ImageUrl = source.ImageUrl,
                OgTitle = source.OgTitle,
                OgDescription = source.OgDescription,
                OgImageUrl = source.OgImageUrl,
                OgSiteName = source.OgSiteName,
                OgFaviconUrl = source.OgFaviconUrl,
                IsFavorite = false,
                SortOrder = 0,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            _dbContext.Items.Add(copy);
        }

        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishItemsChangedAsync(userId, "copied", null, HttpContext.RequestAborted);
        return NoContent();
    }

    private async Task<bool> CategoryBelongsToUserAsync(Guid categoryId, Guid userId)
    {
        return await _dbContext.Categories.AnyAsync(c => c.Id == categoryId && c.UserId == userId);
    }

    private async Task<bool> IsOwnedStorageUrlAsync(string? url, Guid userId)
    {
        var storedFileName = TryExtractStoredFileName(url);
        if (storedFileName == null)
            return true;

        return await _dbContext.UploadedFiles.AnyAsync(f => f.StoredFileName == storedFileName && f.UserId == userId);
    }

    private static string? TryExtractStoredFileName(string? url)
    {
        if (string.IsNullOrWhiteSpace(url))
            return null;

        const string storageSegment = "/storage/";
        var markerIndex = url.IndexOf(storageSegment, StringComparison.OrdinalIgnoreCase);
        if (markerIndex < 0)
            return null;

        var fileName = url[(markerIndex + storageSegment.Length)..];
        var queryIndex = fileName.IndexOfAny(['?', '#']);
        if (queryIndex >= 0)
        {
            fileName = fileName[..queryIndex];
        }

        fileName = Path.GetFileName(fileName);
        return string.IsNullOrWhiteSpace(fileName) ? null : fileName;
    }
}
