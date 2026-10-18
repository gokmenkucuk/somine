using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using SomineApi.Application.DTOs.Shares;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("public/shares")]
[AllowAnonymous]
[EnableRateLimiting("public")]
public class PublicSharesController : ControllerBase
{
    private readonly SomineDbContext _dbContext;
    private readonly IStorageService _storageService;

    public PublicSharesController(SomineDbContext dbContext, IStorageService storageService)
    {
        _dbContext = dbContext;
        _storageService = storageService;
    }

    // Bir public token'ın çözümlenmiş hali. Token iki kaynaktan gelebilir:
    // (1) kişiye özel paylaşım satırı (CollectionShare), (2) koleksiyonun alıcısız linki (Category).
    // Her iki kaynak da aynı şekle indirgenir; aşağıdaki uçlar kaynağı bilmez.
    private sealed record PublicCollectionRef(
        Guid OwnerUserId,
        Guid CategoryId,
        string CategoryName,
        string? FromUserName);

    // Token çözümleme tek noktada. Vault'a çevrilmiş koleksiyonun linki her iki kaynakta da ölür.
    private async Task<PublicCollectionRef?> ResolvePublicCollectionAsync(string token)
    {
        var share = await _dbContext.CollectionShares
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.PublicLinkToken == token && s.Status != ShareStatus.Rejected);

        if (share != null)
        {
            var sharedCategoryIsVault = await _dbContext.Categories
                .AsNoTracking()
                .AnyAsync(c => c.Id == share.CategoryId && c.IsVault);

            if (sharedCategoryIsVault)
                return null;

            return new PublicCollectionRef(
                share.FromUserId, share.CategoryId, share.CategoryName ?? string.Empty, share.FromUserName);
        }

        var category = await _dbContext.Categories
            .AsNoTracking()
            .Where(c => c.PublicLinkToken == token && !c.IsVault)
            .Select(c => new
            {
                c.Id,
                c.Name,
                c.UserId,
                OwnerDisplayName = c.User.DisplayName
            })
            .FirstOrDefaultAsync();

        if (category == null)
            return null;

        return new PublicCollectionRef(
            category.UserId, category.Id, category.Name, category.OwnerDisplayName);
    }

    // Anonim ziyaretçi: token ile koleksiyonu görüntüler.
    // Reddedilmiş paylaşım veya geçersiz/boş token → nötr 404.
    [HttpGet("{token}")]
    public async Task<ActionResult<PublicShareDto>> GetPublicShare(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
            return NotFound(new { error = "Not found" });

        var share = await ResolvePublicCollectionAsync(token);

        if (share == null)
            return NotFound(new { error = "Not found" });

        var items = await _dbContext.Items
            .AsNoTracking()
            .Where(i => i.UserId == share.OwnerUserId && i.CategoryId == share.CategoryId)
            .OrderBy(i => i.SortOrder).ThenByDescending(i => i.CreatedAt)
            .Select(i => new PublicItemDto(
                i.Id, i.Type, i.Url, i.Note, i.ImageUrl,
                i.OgTitle, i.OgDescription, i.OgImageUrl, i.OgSiteName, i.OgFaviconUrl,
                i.CreatedAt))
            .ToListAsync();

        return Ok(new PublicShareDto(share.CategoryName, share.FromUserName, items));
    }

    // Anonim ziyaretçi: paylaşımdaki bir item'ın görseline (ImageUrl / OgImageUrl) ait dosyayı stream eder.
    // Dosya paylaşımın kategorisindeki bir item'da geçmiyorsa → 404.
    [HttpGet("{token}/files/{fileName}")]
    public async Task<IActionResult> GetPublicFile(string token, string fileName)
    {
        if (string.IsNullOrWhiteSpace(token))
            return NotFound(new { error = "Not found" });

        var safeFileName = Path.GetFileName(fileName);
        if (string.IsNullOrWhiteSpace(safeFileName))
            return NotFound(new { error = "Not found" });

        var share = await ResolvePublicCollectionAsync(token);

        if (share == null)
            return NotFound(new { error = "Not found" });

        // Dosya adı, URL'in tam bir yol segmenti olarak eşleşmeli (substring değil).
        // Aksi halde "a.jpg" gibi bir ad "photo-a.jpg-x.png" içinde yanlışlıkla eşleşebilir
        // veya manipülasyona açık kalırdı. Depolanan URL biçimi ".../api/storage/{fileName}".
        var fileNameSuffix = "/" + safeFileName;
        var referenced = await _dbContext.Items
            .AsNoTracking()
            .AnyAsync(i => i.UserId == share.OwnerUserId && i.CategoryId == share.CategoryId &&
                ((i.ImageUrl != null && (i.ImageUrl == safeFileName || i.ImageUrl.EndsWith(fileNameSuffix))) ||
                 (i.OgImageUrl != null && (i.OgImageUrl == safeFileName || i.OgImageUrl.EndsWith(fileNameSuffix)))));

        if (!referenced)
            return NotFound(new { error = "Not found" });

        var uploadedFile = await _dbContext.UploadedFiles
            .AsNoTracking()
            .FirstOrDefaultAsync(f => f.StoredFileName == safeFileName);

        var fileStream = _storageService.GetStream(safeFileName);
        if (fileStream == null)
            return NotFound(new { error = "Not found" });

        var contentType = uploadedFile?.ContentType ?? "application/octet-stream";
        return File(fileStream, contentType, enableRangeProcessing: true);
    }
}
