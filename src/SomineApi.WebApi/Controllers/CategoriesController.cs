using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SomineApi.Application;
using SomineApi.Application.DTOs.Categories;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Entities;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Extensions;
using SomineApi.WebApi.Hubs;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("api/categories")]
[Authorize]
public class CategoriesController : ControllerBase
{
    private readonly SomineDbContext _dbContext;
    private readonly IUserRealtimeEventPublisher _realtimeEventPublisher;
    private readonly ISubscriptionTierService _subscriptionTierService;

    public CategoriesController(
        SomineDbContext dbContext,
        IUserRealtimeEventPublisher realtimeEventPublisher,
        ISubscriptionTierService subscriptionTierService)
    {
        _dbContext = dbContext;
        _realtimeEventPublisher = realtimeEventPublisher;
        _subscriptionTierService = subscriptionTierService;
    }

    [HttpGet]
    public async Task<ActionResult<List<CategoryDto>>> GetCategories()
    {
        var userId = HttpContext.GetUserId();

        var categories = await _dbContext.Categories
            .Where(c => c.UserId == userId)
            .OrderBy(c => c.SortOrder)
            .Select(c => new CategoryDto(c.Id, c.Name, c.Icon, c.Color, c.SortOrder, c.IsVault, c.CreatedAt, c.UpdatedAt))
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

        category.UpdatedAt = DateTime.UtcNow;
        await _dbContext.SaveChangesAsync();
        await _realtimeEventPublisher.PublishCategoriesChangedAsync(userId, "updated", category.Id, HttpContext.RequestAborted);

        return Ok(new CategoryDto(category.Id, category.Name, category.Icon, category.Color,
            category.SortOrder, category.IsVault, category.CreatedAt, category.UpdatedAt));
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
