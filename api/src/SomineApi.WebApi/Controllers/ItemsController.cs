using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Pgvector;
using Pgvector.EntityFrameworkCore;
using SomineApi.Application;
using SomineApi.Application.DTOs.Items;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using SomineApi.Infrastructure.Entities;
using SomineApi.Infrastructure.Options;
using SomineApi.WebApi.Embeddings;
using SomineApi.WebApi.Extensions;
using SomineApi.WebApi.Hubs;
using SomineApi.WebApi.ImageCache;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("api/items")]
[Authorize]
public class ItemsController : ControllerBase
{
    private readonly SomineDbContext _dbContext;
    private readonly IUserRealtimeEventPublisher _realtimeEventPublisher;
    private readonly ISubscriptionTierService _subscriptionTierService;
    private readonly IEmbeddingService _embeddingService;
    private readonly IEmbeddingQueue _embeddingQueue;
    private readonly IOptions<EmbeddingOptions> _embeddingOptions;
    private readonly IOptions<SearchOptions> _searchOptions;
    private readonly ILogger<ItemsController> _logger;
    private readonly IOgImageCacheQueue _ogImageCacheQueue;
    private readonly OgImageUrlPolicy _ogImageUrlPolicy;

    public ItemsController(
        SomineDbContext dbContext,
        IUserRealtimeEventPublisher realtimeEventPublisher,
        ISubscriptionTierService subscriptionTierService,
        IEmbeddingService embeddingService,
        IEmbeddingQueue embeddingQueue,
        IOptions<EmbeddingOptions> embeddingOptions,
        IOptions<SearchOptions> searchOptions,
        ILogger<ItemsController> logger,
        IOgImageCacheQueue ogImageCacheQueue,
        OgImageUrlPolicy ogImageUrlPolicy)
    {
        _ogImageCacheQueue = ogImageCacheQueue;
        _ogImageUrlPolicy = ogImageUrlPolicy;
        _searchOptions = searchOptions;
        _dbContext = dbContext;
        _realtimeEventPublisher = realtimeEventPublisher;
        _subscriptionTierService = subscriptionTierService;
        _embeddingService = embeddingService;
        _embeddingQueue = embeddingQueue;
        _embeddingOptions = embeddingOptions;
        _logger = logger;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<ItemDto>>> GetItems(
        [FromQuery] Guid? categoryId,
        [FromQuery] int page = 1,
        [FromQuery] int limit = 50,
        [FromQuery] bool includeDeleted = false,
        [FromQuery] bool includeVault = false)
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

        query = ApplyVaultVisibility(query, includeVault);

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
                i.OgImageWidth, i.OgImageHeight,
                i.IsFavorite, i.HasReminder, i.SortOrder, i.CreatedAt, i.UpdatedAt, i.LastOpenedAt))
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
                i.OgImageWidth, i.OgImageHeight,
                i.IsFavorite, i.HasReminder, i.SortOrder, i.CreatedAt, i.UpdatedAt, i.LastOpenedAt))
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
            OgImageWidth = SanitizeImageDimension(request.OgImageWidth),
            OgImageHeight = SanitizeImageDimension(request.OgImageHeight),
            SortOrder = 0,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _dbContext.Items.Add(item);
        await _dbContext.SaveChangesAsync();
        _embeddingQueue.Enqueue(item.Id);
        // Harici OG görseli (imzalı CDN adresleri birkaç günde ölüyor) arka planda sunucuya kopyalanır.
        if (_ogImageUrlPolicy.ShouldCache(item.OgImageUrl))
            _ogImageCacheQueue.Enqueue(item.Id);
        await _realtimeEventPublisher.PublishItemsChangedAsync(userId, "created", item.Id, HttpContext.RequestAborted);

        return CreatedAtAction(nameof(GetItem), new { id = item.Id }, new ItemDto(
            item.Id, item.CategoryId, item.Type, item.Url, item.Note, item.ImageUrl,
            item.OgTitle, item.OgDescription, item.OgImageUrl, item.OgSiteName, item.OgFaviconUrl,
            item.OgImageWidth, item.OgImageHeight,
            item.IsFavorite, item.HasReminder, item.SortOrder, item.CreatedAt, item.UpdatedAt, item.LastOpenedAt));
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
        var ogImageChanged = false;
        if (request.OgImageUrl != null && request.OgImageUrl != item.OgImageUrl)
        {
            // İstemci, sunucunun zaten kopyaladığı orijinal (süresi dolabilecek) adresi geri
            // gönderiyorsa kopyayı koru. Gerçekten yeni bir görselse kopya bilgisi sıfırlanır.
            if (item.OgImageSourceUrl == null || request.OgImageUrl != item.OgImageSourceUrl)
            {
                item.OgImageUrl = request.OgImageUrl;
                item.OgImageSourceUrl = null;
                item.OgImageCacheFailedAt = null;
                ogImageChanged = true;
            }
        }
        if (request.OgSiteName != null) item.OgSiteName = request.OgSiteName;
        if (request.OgFaviconUrl != null) item.OgFaviconUrl = request.OgFaviconUrl;
        if (request.OgImageWidth != null) item.OgImageWidth = SanitizeImageDimension(request.OgImageWidth);
        if (request.OgImageHeight != null) item.OgImageHeight = SanitizeImageDimension(request.OgImageHeight);
        if (request.IsFavorite.HasValue) item.IsFavorite = request.IsFavorite.Value;

        item.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        _embeddingQueue.Enqueue(item.Id);
        if (ogImageChanged && _ogImageUrlPolicy.ShouldCache(item.OgImageUrl))
            _ogImageCacheQueue.Enqueue(item.Id);
        await _realtimeEventPublisher.PublishItemsChangedAsync(userId, "updated", item.Id, HttpContext.RequestAborted);

        return Ok(new ItemDto(
            item.Id, item.CategoryId, item.Type, item.Url, item.Note, item.ImageUrl,
            item.OgTitle, item.OgDescription, item.OgImageUrl, item.OgSiteName, item.OgFaviconUrl,
            item.OgImageWidth, item.OgImageHeight,
            item.IsFavorite, item.HasReminder, item.SortOrder, item.CreatedAt, item.UpdatedAt, item.LastOpenedAt));
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
    public async Task<ActionResult<List<ItemDto>>> GetFavorites([FromQuery] bool includeVault = false)
    {
        var userId = HttpContext.GetUserId();

        var items = await ApplyVaultVisibility(
                _dbContext.Items.Where(i => i.UserId == userId && i.IsFavorite),
                includeVault)
            .OrderByDescending(i => i.UpdatedAt)
            .Select(i => new ItemDto(
                i.Id, i.CategoryId, i.Type, i.Url, i.Note, i.ImageUrl,
                i.OgTitle, i.OgDescription, i.OgImageUrl, i.OgSiteName, i.OgFaviconUrl,
                i.OgImageWidth, i.OgImageHeight,
                i.IsFavorite, i.HasReminder, i.SortOrder, i.CreatedAt, i.UpdatedAt, i.LastOpenedAt))
            .ToListAsync();

        return Ok(items);
    }

    [HttpGet("search")]
    [EnableRateLimiting("search")]
    public async Task<ActionResult<PagedResult<ItemDto>>> SearchItems(
        [FromQuery] string? q,
        [FromQuery] string? mode,
        [FromQuery] Guid? categoryId,
        [FromQuery] Guid[]? excludeCategoryIds,
        [FromQuery] string? platform,
        [FromQuery] int page = 1,
        [FromQuery] int limit = 20,
        [FromQuery] bool includeVault = false)
    {
        if (page < 1 || limit < 1 || limit > 100)
            return BadRequest(new { error = "Invalid pagination values" });

        var useSemantic = false;
        if (!string.IsNullOrWhiteSpace(mode))
        {
            if (string.Equals(mode, "semantic", StringComparison.OrdinalIgnoreCase))
                useSemantic = true;
            else if (!string.Equals(mode, "keyword", StringComparison.OrdinalIgnoreCase))
                return BadRequest(new { error = "Invalid search mode" });
        }

        var userId = HttpContext.GetUserId();

        var query = ApplyVaultVisibility(_dbContext.Items.Where(i => i.UserId == userId), includeVault);

        if (categoryId.HasValue)
            query = query.Where(i => i.CategoryId == categoryId.Value);

        if (excludeCategoryIds is { Length: > 0 })
            query = query.Where(i => i.CategoryId == null || !excludeCategoryIds.Contains(i.CategoryId.Value));

        if (!string.IsNullOrWhiteSpace(platform))
        {
            var filteredQuery = ApplyPlatformFilter(query, platform);
            if (filteredQuery == null)
                return BadRequest(new { error = "Invalid platform filter" });
            query = filteredQuery;
        }

        if (useSemantic && !string.IsNullOrWhiteSpace(q) && _embeddingOptions.Value.IsConfigured)
        {
            var semanticResult = await TrySemanticSearchAsync(query, q, page, limit);
            if (semanticResult != null)
                return Ok(semanticResult);
        }

        // Keyword arama — API sözleşmesi ve mode belirtilmediğindeki davranış aynen korunur;
        // semantic istenip embedding kapalı/başarısız olduğunda da buraya düşülür.
        var searchOptions = _searchOptions.Value;
        var useTrigram = ItemSearchQuery.ShouldUseTrigram(
            _dbContext.Database.IsNpgsql(),
            searchOptions.TrigramEnabled,
            q,
            searchOptions.EffectiveMinQueryLength);

        if (!string.IsNullOrWhiteSpace(q))
        {
            query = useTrigram
                ? ItemSearchQuery.ApplyTrigramFilter(query, q, searchOptions.EffectiveThreshold)
                : ItemSearchQuery.ApplyLikeFilter(query, q);
        }

        var totalCount = await query.CountAsync();

        var orderedQuery = useTrigram
            ? ItemSearchQuery.ApplyRelevanceOrder(query, q!)
            : query.OrderByDescending(i => i.UpdatedAt);

        var items = await orderedQuery
            .Skip((page - 1) * limit)
            .Take(limit)
            .Select(i => new ItemDto(
                i.Id, i.CategoryId, i.Type, i.Url, i.Note, i.ImageUrl,
                i.OgTitle, i.OgDescription, i.OgImageUrl, i.OgSiteName, i.OgFaviconUrl,
                i.OgImageWidth, i.OgImageHeight,
                i.IsFavorite, i.HasReminder, i.SortOrder, i.CreatedAt, i.UpdatedAt, i.LastOpenedAt))
            .ToListAsync();

        return Ok(new PagedResult<ItemDto>(items, totalCount, page, limit));
    }

    /// <summary>
    /// Semantik arama: sorgu embed edilir ve pgvector cosine mesafesine göre sıralanır.
    /// Embedding üretilemez veya sorgu başarısız olursa null döner (keyword fallback).
    /// </summary>
    private async Task<PagedResult<ItemDto>?> TrySemanticSearchAsync(
        IQueryable<Item> query,
        string q,
        int page,
        int limit)
    {
        var queryVectors = await _embeddingService.EmbedAsync([q], HttpContext.RequestAborted);
        if (queryVectors.Count != 1)
            return null;

        try
        {
            var queryVector = new Vector(queryVectors[0]);

            var joined = query.Join(
                _dbContext.Set<ItemEmbedding>(),
                i => i.Id,
                e => e.ItemId,
                (i, e) => new { Item = i, e.Embedding });

            var totalCount = await joined.CountAsync();

            var items = await joined
                .OrderBy(x => x.Embedding.CosineDistance(queryVector))
                .Skip((page - 1) * limit)
                .Take(limit)
                .Select(x => new ItemDto(
                    x.Item.Id, x.Item.CategoryId, x.Item.Type, x.Item.Url, x.Item.Note, x.Item.ImageUrl,
                    x.Item.OgTitle, x.Item.OgDescription, x.Item.OgImageUrl, x.Item.OgSiteName, x.Item.OgFaviconUrl,
                    x.Item.OgImageWidth, x.Item.OgImageHeight,
                    x.Item.IsFavorite, x.Item.HasReminder, x.Item.SortOrder, x.Item.CreatedAt, x.Item.UpdatedAt, x.Item.LastOpenedAt))
                .ToListAsync();

            return new PagedResult<ItemDto>(items, totalCount, page, limit);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Semantic search failed; falling back to keyword search.");
            return null;
        }
    }

    /// <summary>
    /// İstemcideki ItemModel.platform türetimiyle birebir aynı URL-domain eşlemesi.
    /// Bilinmeyen platform değerinde null döner (400'e çevrilir).
    /// </summary>
    private static IQueryable<Item>? ApplyPlatformFilter(IQueryable<Item> query, string platform)
    {
        return platform.ToLowerInvariant() switch
        {
            "instagram" => query.Where(i => i.Url != null && i.Url.ToLower().Contains("instagram.com")),
            "youtube" => query.Where(i => i.Url != null &&
                (i.Url.ToLower().Contains("youtube.com") || i.Url.ToLower().Contains("youtu.be"))),
            "x" => query.Where(i => i.Url != null &&
                (i.Url.ToLower().Contains("twitter.com") || i.Url.ToLower().Contains("x.com"))),
            "tiktok" => query.Where(i => i.Url != null && i.Url.ToLower().Contains("tiktok.com")),
            "linkedin" => query.Where(i => i.Url != null && i.Url.ToLower().Contains("linkedin.com")),
            "spotify" => query.Where(i => i.Url != null && i.Url.ToLower().Contains("spotify.com")),
            "pinterest" => query.Where(i => i.Url != null && i.Url.ToLower().Contains("pinterest.com")),
            "reddit" => query.Where(i => i.Url != null && i.Url.ToLower().Contains("reddit.com")),
            "medium" => query.Where(i => i.Url != null && i.Url.ToLower().Contains("medium.com")),
            "behance" => query.Where(i => i.Url != null && i.Url.ToLower().Contains("behance.net")),
            "dribbble" => query.Where(i => i.Url != null && i.Url.ToLower().Contains("dribbble.com")),
            "web" => query.Where(i => i.Url == null || (
                !i.Url.ToLower().Contains("instagram.com") &&
                !i.Url.ToLower().Contains("youtube.com") &&
                !i.Url.ToLower().Contains("youtu.be") &&
                !i.Url.ToLower().Contains("twitter.com") &&
                !i.Url.ToLower().Contains("x.com") &&
                !i.Url.ToLower().Contains("tiktok.com") &&
                !i.Url.ToLower().Contains("linkedin.com") &&
                !i.Url.ToLower().Contains("spotify.com") &&
                !i.Url.ToLower().Contains("pinterest.com") &&
                !i.Url.ToLower().Contains("reddit.com") &&
                !i.Url.ToLower().Contains("medium.com") &&
                !i.Url.ToLower().Contains("behance.net") &&
                !i.Url.ToLower().Contains("dribbble.com"))),
            _ => null
        };
    }

    [HttpGet("deleted")]
    public async Task<ActionResult<List<ItemDto>>> GetDeletedItems([FromQuery] bool includeVault = false)
    {
        var userId = HttpContext.GetUserId();

        var items = await ApplyVaultVisibility(
                _dbContext.Items
                    .IgnoreQueryFilters()
                    .Where(i => i.UserId == userId && i.IsDeleted),
                includeVault)
            .OrderByDescending(i => i.DeletedAt)
            .Select(i => new ItemDto(
                i.Id, i.CategoryId, i.Type, i.Url, i.Note, i.ImageUrl,
                i.OgTitle, i.OgDescription, i.OgImageUrl, i.OgSiteName, i.OgFaviconUrl,
                i.OgImageWidth, i.OgImageHeight,
                i.IsFavorite, i.HasReminder, i.SortOrder, i.CreatedAt, i.UpdatedAt, i.LastOpenedAt))
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

    [HttpPost("{id}/opened")]
    public async Task<IActionResult> MarkItemOpened(Guid id)
    {
        var userId = HttpContext.GetUserId();
        var item = await _dbContext.Items.FirstOrDefaultAsync(i => i.Id == id && i.UserId == userId);

        if (item == null)
            return NotFound(new { error = "Item not found" });

        item.LastOpenedAt = DateTime.UtcNow;
        item.OpenCount += 1;
        await _dbContext.SaveChangesAsync();

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

        var copies = new List<Item>();
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
                OgImageWidth = source.OgImageWidth,
                OgImageHeight = source.OgImageHeight,
                OgImageSourceUrl = source.OgImageSourceUrl,
                OgImageCacheFailedAt = source.OgImageCacheFailedAt,
                IsFavorite = false,
                SortOrder = 0,
                CreatedAt = DateTime.UtcNow,
                UpdatedAt = DateTime.UtcNow
            };
            _dbContext.Items.Add(copy);
            copies.Add(copy);
        }

        await _dbContext.SaveChangesAsync();
        foreach (var copy in copies)
        {
            if (copy.OgImageCacheFailedAt == null && _ogImageUrlPolicy.ShouldCache(copy.OgImageUrl))
                _ogImageCacheQueue.Enqueue(copy.Id);
        }
        await _realtimeEventPublisher.PublishItemsChangedAsync(userId, "copied", null, HttpContext.RequestAborted);
        return NoContent();
    }

    /// <summary>
    /// Kasa (vault) görünürlüğü. Vault kategorisindeki item'lar listeleme/arama uçlarında
    /// VARSAYILAN OLARAK dönmez; istemcinin `includeVault=true` ile açıkça istemesi gerekir.
    ///
    /// DİKKAT — BU BİR GÜVENLİK SINIRI DEĞİLDİR. Parametre yalnızca bir "niyet beyanı"dır:
    /// kullanıcı zaten authenticated olduğu için `includeVault=true` gönderen herkes (ör.
    /// yeniden paketlenmiş bir istemci) veriyi alabilir. Biyometrik doğrulama sunucuya
    /// kanıtlanamaz, o yüzden burada ek bir sunucu-tarafı kontrol YOK — sahte güvenlik
    /// hissi yaratmamak için bilinçli tercih. Amaç: vault verisinin varsayılan akışta
    /// cihaza inmemesi (defense in depth). Gerçek sınır ancak client-side şifrelemeyle kurulur.
    /// </summary>
    private static IQueryable<Item> ApplyVaultVisibility(IQueryable<Item> query, bool includeVault)
    {
        if (includeVault)
            return query;

        // Kategorisiz ("uncategorized") item'lar hiçbir zaman vault olamaz, dolayısıyla dahil kalır.
        return query.Where(i => i.Category == null || !i.Category.IsVault);
    }

    /// <summary>
    /// Toplam (silinmemiş) item sayısı — kota göstergesi için. Vault item'ları DAHİLDİR;
    /// CreateItem/RestoreItem/CopyItems'daki 500'lük ücretsiz plan kontrolü de vault'u saydığı
    /// için istemci sayacının onunla birebir tutarlı olması gerekir. Listeleme uçlarındaki
    /// vault filtresi bu sayacı etkilemez.
    /// </summary>
    [HttpGet("count")]
    public async Task<IActionResult> GetItemCount()
    {
        var userId = HttpContext.GetUserId();
        var total = await _dbContext.Items.CountAsync(i => i.UserId == userId);
        return Ok(new { total });
    }

    /// <summary>
    /// İstemcinin ölçüp gönderdiği OG görsel boyutu. Sunucu görseli asla indirmez/probe etmez;
    /// yalnızca makul aralıktaki değerleri saklar. Negatif/sıfır/absürt değerler 400 yerine
    /// sessizce null'a düşer — eski veya hatalı istemciler bozulmasın diye.
    /// </summary>
    private static int? SanitizeImageDimension(int? value) => value is > 0 and <= 20000 ? value : null;

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
