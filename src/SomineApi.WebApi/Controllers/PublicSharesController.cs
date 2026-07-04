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

    // Anonim ziyaretçi: token ile koleksiyonu görüntüler.
    // Reddedilmiş paylaşım veya geçersiz/boş token → nötr 404.
    [HttpGet("{token}")]
    public async Task<ActionResult<PublicShareDto>> GetPublicShare(string token)
    {
        if (string.IsNullOrWhiteSpace(token))
            return NotFound(new { error = "Not found" });

        var share = await _dbContext.CollectionShares
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.PublicLinkToken == token && s.Status != ShareStatus.Rejected);

        if (share == null)
            return NotFound(new { error = "Not found" });

        var items = await _dbContext.Items
            .AsNoTracking()
            .Where(i => i.UserId == share.FromUserId && i.CategoryId == share.CategoryId)
            .OrderBy(i => i.SortOrder).ThenByDescending(i => i.CreatedAt)
            .Select(i => new PublicItemDto(
                i.Id, i.Type, i.Url, i.Note, i.ImageUrl,
                i.OgTitle, i.OgDescription, i.OgImageUrl, i.OgSiteName, i.OgFaviconUrl,
                i.CreatedAt))
            .ToListAsync();

        return Ok(new PublicShareDto(share.CategoryName ?? string.Empty, share.FromUserName, items));
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

        var share = await _dbContext.CollectionShares
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.PublicLinkToken == token && s.Status != ShareStatus.Rejected);

        if (share == null)
            return NotFound(new { error = "Not found" });

        var referenced = await _dbContext.Items
            .AsNoTracking()
            .AnyAsync(i => i.UserId == share.FromUserId && i.CategoryId == share.CategoryId &&
                ((i.ImageUrl != null && i.ImageUrl.Contains(safeFileName)) ||
                 (i.OgImageUrl != null && i.OgImageUrl.Contains(safeFileName))));

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
