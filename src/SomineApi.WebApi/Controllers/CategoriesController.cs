using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using SomineApi.Application;
using SomineApi.Application.DTOs.Categories;
using SomineApi.Application.DTOs.Shares;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Entities;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Extensions;
using SomineApi.WebApi.Hubs;
using SomineApi.WebApi.Options;
using System.Security.Cryptography;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("api/categories")]
[Authorize]
public class CategoriesController : ControllerBase
{
    private readonly SomineDbContext _dbContext;
    private readonly IUserRealtimeEventPublisher _realtimeEventPublisher;
    private readonly ISubscriptionTierService _subscriptionTierService;
    private readonly PublicWebOptions _publicWebOptions;

    public CategoriesController(
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

    [HttpGet]
    public async Task<ActionResult<List<CategoryDto>>> GetCategories()
    {
        var userId = HttpContext.GetUserId();

        var categories = await _dbContext.Categories
            .Where(c => c.UserId == userId)
            .OrderBy(c => c.SortOrder)
            // Sorgu zaten c.UserId == userId ile sınırlı; token yalnızca sahibine döner.
            .Select(c => new CategoryDto(c.Id, c.Name, c.Icon, c.Color, c.SortOrder, c.IsVault, c.CreatedAt, c.UpdatedAt,
                c.PublicLinkToken))
            .ToListAsync();

        return Ok(categories);
    }

    [HttpPost]
    public async Task<ActionResult<CategoryDto>> CreateCategory([FromBody] CreateCategoryRequest request)
    {
        var userId = HttpContext.GetUserId();

        if (!await _subscriptionTierService.IsPremiumForEnforcementAsync(userId, HttpContext.RequestAborted))
        {
            var current = await _dbContext.Categories.CountAsync(c => c.UserId == userId);
            if (current >= SubscriptionLimits.FreeMaxCategories)
                return StatusCode(403, new
                {
                    error = "limit_reached",
                    message = "Ücretsiz planda en fazla 10 koleksiyon oluşturabilirsiniz. Sınırsız koleksiyon için Premium'a geçin.",
                    limit = SubscriptionLimits.FreeMaxCategories,
                    current
                });
        }

        var existingCategories = await _dbContext.Categories
            .Where(c => c.UserId == userId)
            .ToListAsync();

        foreach (var existingCategory in existingCategories)
        {
            existingCategory.SortOrder += 1;
            existingCategory.UpdatedAt = DateTime.UtcNow;
        }

        var category = new Category
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Name = request.Name,
            Icon = request.Icon,
            Color = request.Color,
            SortOrder = 0,
            IsVault = request.IsVault,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _dbContext.Categories.Add(category);
        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishCategoriesChangedAsync(userId, "created", category.Id, HttpContext.RequestAborted);

        return CreatedAtAction(nameof(GetCategories), new CategoryDto(
            category.Id, category.Name, category.Icon, category.Color,
            category.SortOrder, category.IsVault, category.CreatedAt, category.UpdatedAt));
    }

    [HttpPut("{id}")]
    public async Task<ActionResult<CategoryDto>> UpdateCategory(Guid id, [FromBody] UpdateCategoryRequest request)
    {
        var userId = HttpContext.GetUserId();
        var category = await _dbContext.Categories.FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId);

        if (category == null)
            return NotFound(new { error = "Category not found" });

        if (request.Name != null) category.Name = request.Name;
        if (request.Icon != null) category.Icon = request.Icon;
        if (request.Color != null) category.Color = request.Color;
        if (request.IsVault.HasValue) category.IsVault = request.IsVault.Value;

        // Kasaya alınan koleksiyonun açık linki kalamaz: vault'a çevrilirse link iptal edilir.
        if (category.IsVault && category.PublicLinkToken != null)
        {
            category.PublicLinkToken = null;
            category.PublicLinkCreatedAtUtc = null;
        }

        category.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishCategoriesChangedAsync(userId, "updated", category.Id, HttpContext.RequestAborted);

        return Ok(new CategoryDto(category.Id, category.Name, category.Icon, category.Color,
            category.SortOrder, category.IsVault, category.CreatedAt, category.UpdatedAt,
            category.PublicLinkToken));
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> DeleteCategory(Guid id)
    {
        var userId = HttpContext.GetUserId();
        var category = await _dbContext.Categories.FirstOrDefaultAsync(c => c.Id == id && c.UserId == userId);

        if (category == null)
            return NotFound(new { error = "Category not found" });

        _dbContext.Categories.Remove(category);
        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishCategoriesChangedAsync(userId, "deleted", category.Id, HttpContext.RequestAborted);
        await _realtimeEventPublisher.PublishItemsChangedAsync(userId, "category_deleted", category.Id, HttpContext.RequestAborted);

        return NoContent();
    }

    // Sahibi için: koleksiyona alıcısız ("link ile paylaş") public link üretir.
    // IDEMPOTENT — link zaten varsa mevcut token aynen döner, rotate EDİLMEZ.
    // (Rotate davranışı share bazlı POST /api/shares/{id}/public-link ucunda kalır.)
    [HttpPost("{categoryId}/public-link")]
    public async Task<ActionResult<PublicLinkDto>> CreateCategoryPublicLink(Guid categoryId)
    {
        var userId = HttpContext.GetUserId();
        var category = await _dbContext.Categories.FirstOrDefaultAsync(c => c.Id == categoryId && c.UserId == userId);

        if (category == null)
            return NotFound(new { error = "Category not found" });

        if (category.IsVault)
            return BadRequest(new { error = "Vault categories cannot be shared publicly" });

        if (category.PublicLinkToken == null)
        {
            category.PublicLinkToken = await GenerateUniqueTokenAsync();
            category.PublicLinkCreatedAtUtc = DateTime.UtcNow;
            await _dbContext.SaveChangesAsync();
            await _realtimeEventPublisher.PublishCategoriesChangedAsync(userId, "updated", category.Id, HttpContext.RequestAborted);
        }

        var url = $"{_publicWebOptions.BaseUrl.TrimEnd('/')}/s/{category.PublicLinkToken}";
        return Ok(new PublicLinkDto(category.PublicLinkToken, url));
    }

    // Sahibi için: koleksiyonun public linkini iptal eder. Link zaten yoksa da 204 (idempotent).
    [HttpDelete("{categoryId}/public-link")]
    public async Task<IActionResult> DeleteCategoryPublicLink(Guid categoryId)
    {
        var userId = HttpContext.GetUserId();
        var category = await _dbContext.Categories.FirstOrDefaultAsync(c => c.Id == categoryId && c.UserId == userId);

        if (category == null)
            return NotFound(new { error = "Category not found" });

        if (category.PublicLinkToken != null)
        {
            category.PublicLinkToken = null;
            category.PublicLinkCreatedAtUtc = null;
            await _dbContext.SaveChangesAsync();
            await _realtimeEventPublisher.PublishCategoriesChangedAsync(userId, "updated", category.Id, HttpContext.RequestAborted);
        }

        return NoContent();
    }

    // Public token uzayı iki tablo arasında ORTAK: /public/shares/{token} önce CollectionShare'e,
    // sonra Category'ye bakar. İki ayrı unique index tablolar arası tekliği garanti etmediği için
    // (128-bit'te olasılık ihmal edilebilir olsa da) token üretirken her iki kaynak da kontrol edilir.
    private async Task<string> GenerateUniqueTokenAsync()
    {
        while (true)
        {
            // 128-bit rastgele token, base64url (padding'siz)
            var token = ToBase64Url(RandomNumberGenerator.GetBytes(16));

            var taken = await _dbContext.Categories.AnyAsync(c => c.PublicLinkToken == token)
                || await _dbContext.CollectionShares.AnyAsync(s => s.PublicLinkToken == token);

            if (!taken)
                return token;
        }
    }

    private static string ToBase64Url(byte[] bytes) =>
        Convert.ToBase64String(bytes)
            .Replace('+', '-')
            .Replace('/', '_')
            .TrimEnd('=');

    [HttpPatch("reorder")]
    public async Task<IActionResult> ReorderCategories([FromBody] ReorderCategoriesRequest request)
    {
        var userId = HttpContext.GetUserId();

        var categoryIds = request.Items.Select(i => i.Id).ToList();
        var categories = await _dbContext.Categories
            .Where(c => c.UserId == userId && categoryIds.Contains(c.Id))
            .ToListAsync();

        foreach (var item in request.Items)
        {
            var category = categories.FirstOrDefault(c => c.Id == item.Id);
            if (category != null)
            {
                category.SortOrder = item.SortOrder;
                category.UpdatedAt = DateTime.UtcNow;
            }
        }

        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishCategoriesChangedAsync(userId, "reordered", null, HttpContext.RequestAborted);
        return NoContent();
    }
}
