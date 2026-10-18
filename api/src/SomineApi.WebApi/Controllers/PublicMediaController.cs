using System.Text.RegularExpressions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using SomineApi.Application.Interfaces;
using SomineApi.WebApi.ImageCache;

namespace SomineApi.WebApi.Controllers;

/// <summary>
/// Sunucuya kopyalanmış OG önizleme görselleri. Kaynakları zaten herkese açık web görselleri ve
/// adları içerik özeti (sha256) olduğu için kimlik doğrulaması istenmez: mobil, paylaşım sayfası ve
/// OG kazıyıcılar başlık eklemeden yükleyebilir. "/public" öneki ApiKey muafiyetine girer.
/// İçerik değişmez olduğundan uzun süre önbelleğe alınabilir; ucuz bir dosya okuması olduğu için
/// (ızgarada çok sayıda görsel aynı anda istenir) hız sınırlayıcıdan muaftır.
/// </summary>
[ApiController]
[Route("public/" + ImageCacheService.ObjectPrefix)]
[AllowAnonymous]
[DisableRateLimiting]
public partial class PublicMediaController : ControllerBase
{
    private readonly IStorageService _storageService;

    public PublicMediaController(IStorageService storageService)
    {
        _storageService = storageService;
    }

    [GeneratedRegex("^[a-f0-9]{64}\\.(jpg|png|webp|gif)$", RegexOptions.CultureInvariant)]
    private static partial Regex OgFileNamePattern();

    [HttpGet("{fileName}")]
    public IActionResult GetOgImage(string fileName)
    {
        if (!OgFileNamePattern().IsMatch(fileName))
            return NotFound();

        var stream = _storageService.OpenPublicObject($"{ImageCacheService.ObjectPrefix}/{fileName}");
        if (stream == null)
            return NotFound();

        var contentType = Path.GetExtension(fileName) switch
        {
            ".jpg" => "image/jpeg",
            ".png" => "image/png",
            ".webp" => "image/webp",
            _ => "image/gif"
        };

        Response.Headers.CacheControl = "public, max-age=31536000, immutable";
        return File(stream, contentType, enableRangeProcessing: true);
    }
}
