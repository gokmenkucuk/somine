using System.Text.RegularExpressions;
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
        _baseUrl = ResolveApiBaseUrl(configuration["Storage:BaseUrl"]);
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
        return $"{_baseUrl}/api/storage/{fileName}";
    }

    /// <summary>
    /// Storage:BaseUrl değerinden API kök adresini üretir ("/storage" son eki ve sondaki "/" atılır).
    /// Ör. "https://api.somineapp.com/storage" → "https://api.somineapp.com".
    /// </summary>
    public static string ResolveApiBaseUrl(string? configuredBaseUrl)
    {
        var baseUrlClean = (string.IsNullOrWhiteSpace(configuredBaseUrl)
            ? "http://localhost:5000/storage"
            : configuredBaseUrl).Trim().TrimEnd('/');
        if (baseUrlClean.EndsWith("/storage", StringComparison.OrdinalIgnoreCase))
            baseUrlClean = baseUrlClean[..^"/storage".Length];
        return baseUrlClean;
    }

    private static readonly Regex PublicPathSegment = new("^[a-z0-9][a-z0-9._-]{0,127}$", RegexOptions.CultureInvariant);

    private string ResolvePublicObjectPath(string relativePath)
    {
        var segments = relativePath.Split('/');
        if (segments.Length is < 1 or > 4 ||
            segments.Any(segment => !PublicPathSegment.IsMatch(segment) || segment.Contains("..")))
        {
            throw new ArgumentException("Invalid public object path.", nameof(relativePath));
        }

        return Path.Combine([_storagePath, .. segments]);
    }

    public async Task SavePublicObjectAsync(string relativePath, ReadOnlyMemory<byte> content, CancellationToken cancellationToken = default)
    {
        var filePath = ResolvePublicObjectPath(relativePath);
        if (File.Exists(filePath))
            return;

        Directory.CreateDirectory(Path.GetDirectoryName(filePath)!);
        // Geçici dosyaya yaz + yeniden adlandır: yarım yazılmış dosya asla servis edilmez,
        // eşzamanlı iki yazım da aynı içeriği üreteceği için yarış zararsızdır.
        var tempPath = $"{filePath}.{Guid.NewGuid():N}.tmp";
        try
        {
            await File.WriteAllBytesAsync(tempPath, content.ToArray(), cancellationToken);
            File.Move(tempPath, filePath, overwrite: true);
        }
        finally
        {
            if (File.Exists(tempPath))
                File.Delete(tempPath);
        }
    }

    public bool PublicObjectExists(string relativePath)
        => File.Exists(ResolvePublicObjectPath(relativePath));

    public Stream? OpenPublicObject(string relativePath)
    {
        var filePath = ResolvePublicObjectPath(relativePath);
        return File.Exists(filePath)
            ? new FileStream(filePath, FileMode.Open, FileAccess.Read, FileShare.Read)
            : null;
    }

    public string GetPublicObjectUrl(string relativePath)
    {
        ResolvePublicObjectPath(relativePath);
        return $"{_baseUrl}/public/{relativePath}";
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
