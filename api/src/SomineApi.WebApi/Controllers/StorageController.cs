using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Extensions;

namespace SomineApi.WebApi.Controllers;

[ApiController]
[Route("api/storage")]
[Authorize]
public class StorageController : ControllerBase
{
    private readonly IStorageService _storageService;
    private readonly SomineDbContext _dbContext;
    private static readonly HashSet<string> AllowedContentTypes = new(StringComparer.OrdinalIgnoreCase)
    {
        "image/jpeg",
        "image/png",
        "image/webp",
        "image/gif",
        "image/heic",
        "image/heif",
        "application/pdf",
        "video/mp4",
        "video/quicktime"
    };

    public StorageController(IStorageService storageService, SomineDbContext dbContext)
    {
        _storageService = storageService;
        _dbContext = dbContext;
    }

    [HttpPost("upload")]
    public async Task<ActionResult<object>> Upload(IFormFile file)
    {
        var userId = HttpContext.GetUserId();

        if (file == null || file.Length == 0)
            return BadRequest(new { error = "No file provided" });

        if (file.Length > 10 * 1024 * 1024)
            return BadRequest(new { error = "File size exceeds 10MB limit" });

        if (string.IsNullOrWhiteSpace(file.ContentType) || !AllowedContentTypes.Contains(file.ContentType))
            return BadRequest(new { error = "Unsupported file type" });

        var fileName = await _storageService.UploadAsync(file.OpenReadStream(), file.FileName, file.ContentType);
        var url = _storageService.GetUrl(fileName);

        var uploadedFile = new UploadedFile
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            StoredFileName = fileName,
            OriginalFileName = Path.GetFileName(file.FileName),
            ContentType = file.ContentType,
            SizeBytes = file.Length,
            StorageProvider = "Local",
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        _dbContext.UploadedFiles.Add(uploadedFile);
        await _dbContext.SaveChangesAsync();

        return Ok(new { fileName, url });
    }

    [HttpGet("{fileName}")]
    public async Task<IActionResult> GetFile(string fileName)
    {
        var userId = HttpContext.GetUserId();
        var safeFileName = Path.GetFileName(fileName);

        var uploadedFile = await _dbContext.UploadedFiles
            .FirstOrDefaultAsync(f => f.StoredFileName == safeFileName);

        if (uploadedFile == null)
            return NotFound(new { error = "File not found or access denied" });

        // Access: file owner, an own item referencing the file (copied from a share),
        // or an item inside a category actively shared with this user
        var hasAccess = uploadedFile.UserId == userId
            || await _dbContext.Items.AnyAsync(i =>
                i.UserId == userId && i.ImageUrl != null && i.ImageUrl.Contains(safeFileName))
            || await _dbContext.CollectionShares.AnyAsync(s =>
                s.ToUserId == userId && s.Status == ShareStatus.Accepted &&
                _dbContext.Items.Any(i =>
                    i.UserId == s.FromUserId && i.CategoryId == s.CategoryId &&
                    i.ImageUrl != null && i.ImageUrl.Contains(safeFileName)));

        if (!hasAccess)
            return NotFound(new { error = "File not found or access denied" });

        var fileStream = _storageService.GetStream(safeFileName);
        if (fileStream == null)
            return NotFound(new { error = "File not found on disk" });

        return File(fileStream, uploadedFile.ContentType, enableRangeProcessing: true);
    }

    [HttpDelete("{fileName}")]
    public async Task<IActionResult> Delete(string fileName)
    {
        var userId = HttpContext.GetUserId();
        var safeFileName = Path.GetFileName(fileName);

        var uploadedFile = await _dbContext.UploadedFiles
            .FirstOrDefaultAsync(f => f.StoredFileName == safeFileName && f.UserId == userId);

        if (uploadedFile == null)
            return NotFound(new { error = "File not found" });

        _dbContext.UploadedFiles.Remove(uploadedFile);
        await _dbContext.SaveChangesAsync();

        await _storageService.DeleteAsync(safeFileName);
        return NoContent();
    }
}
