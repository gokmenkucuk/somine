using Microsoft.Extensions.Configuration;
using SomineApi.Application.Interfaces;

namespace SomineApi.Infrastructure.Services;

public class LocalStorageService : IStorageService
{
    private readonly string _storagePath;
    private readonly string _baseUrl;
    private static readonly HashSet<string> AllowedExtensions = new(StringComparer.OrdinalIgnoreCase)
    {
        ".jpg", ".jpeg", ".png", ".webp", ".gif", ".heic", ".heif", ".pdf", ".mp4", ".mov"
    };

    public LocalStorageService(IConfiguration configuration)
    {
        _storagePath = configuration["Storage:LocalPath"] ?? "./uploads";
        _baseUrl = configuration["Storage:BaseUrl"] ?? "http://localhost:5000/storage";
        Directory.CreateDirectory(_storagePath);
    }

    public async Task<string> UploadAsync(Stream fileStream, string fileName, string contentType)
    {
        var safeOriginalName = Path.GetFileName(fileName);
        var extension = Path.GetExtension(safeOriginalName);
        if (string.IsNullOrWhiteSpace(extension) || !AllowedExtensions.Contains(extension))
        {
            throw new ArgumentException("Unsupported file extension.");
        }

        var baseName = Path.GetFileNameWithoutExtension(safeOriginalName);
        var safeBaseName = string.Concat(baseName.Select(ch =>
            char.IsLetterOrDigit(ch) || ch is '-' or '_' ? ch : '_')).Trim('_');

        if (string.IsNullOrWhiteSpace(safeBaseName))
        {
            safeBaseName = "file";
        }

        var uniqueName = $"{Guid.NewGuid():N}_{safeBaseName}{extension.ToLowerInvariant()}";
        var filePath = Path.Combine(_storagePath, uniqueName);

        using var stream = new FileStream(filePath, FileMode.Create);
        await fileStream.CopyToAsync(stream);

        return uniqueName;
    }

    public Task DeleteAsync(string fileName)
    {
        var safeFileName = Path.GetFileName(fileName);
        var filePath = Path.Combine(_storagePath, safeFileName);
        if (File.Exists(filePath))
        {
            File.Delete(filePath);
        }
        return Task.CompletedTask;
    }

    public string GetUrl(string fileName)
    {
        // URL now points to authenticated endpoint instead of static /storage
        // Strip /storage suffix from baseUrl if present, use /api/storage instead
        var baseUrlClean = _baseUrl.TrimEnd('/');
        if (baseUrlClean.EndsWith("/storage", StringComparison.OrdinalIgnoreCase))
            baseUrlClean = baseUrlClean[..^"/storage".Length];
        return $"{baseUrlClean}/api/storage/{fileName}";
    }

    public Stream? GetStream(string fileName)
    {
        var safeFileName = Path.GetFileName(fileName);
        var filePath = Path.Combine(_storagePath, safeFileName);
        if (!File.Exists(filePath))
            return null;
        return new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read);
    }
}
