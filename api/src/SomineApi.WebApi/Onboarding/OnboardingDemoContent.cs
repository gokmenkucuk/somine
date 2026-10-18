using System.Text.Json;
using System.Text.Json.Serialization;

namespace SomineApi.WebApi.Onboarding;

public sealed record OnboardingDemoItemDto(string Collection, string Url);

public sealed record OnboardingDemoContentDto(string Version, IReadOnlyList<OnboardingDemoItemDto> Items);

/// <summary>Yönetim paneli görünümü: notlar dahil, içeriğin nereden geldiği ve dosyanın yazılabilirliği.</summary>
public sealed record OnboardingDemoAdminItemDto(string Collection, string Url, string? Note);

public sealed record OnboardingDemoAdminContentDto(
    string Version,
    IReadOnlyList<OnboardingDemoAdminItemDto> Items,
    string Source,
    bool Writable)
{
    /// <summary>Panelin seçim listesi için yazılabilir koleksiyon anahtarları.</summary>
    public IReadOnlyList<string> Collections { get; init; } = ["music", "places", "restaurants", "inspiration"];

    public int MaxItems { get; init; } = OnboardingDemoContentProvider.MaxItems;
}

public sealed record OnboardingDemoAdminUpdateRequest(IReadOnlyList<OnboardingDemoAdminItemDto>? Items);

public sealed class OnboardingDemoContentValidationException(string message) : Exception(message);

public sealed class OnboardingOptions
{
    public const string SectionName = "Onboarding";

    /// <summary>
    /// Sunucudaki JSON dosyası (ör. /app/config/onboarding-demo-content.json). Boşsa ya da
    /// okunamazsa API'ye gömülü liste kullanılır. Dosya her istekte değişiklik zamanına göre
    /// yeniden okunur; içerik yeni sürüm yayınlamadan güncellenebilir.
    /// </summary>
    public string? DemoContentPath { get; set; }
}

/// <summary>
/// Yeni kullanıcıya kayıtta eklenen örnek içerik listesi. Biçim
/// docs/onboarding-demo-content.json ile aynı: { version, items: [{ collection, url, note }] }.
/// Yalnızca bilinen koleksiyon anahtarları ve http(s) bağlantıları döner.
/// </summary>
public sealed class OnboardingDemoContentProvider
{
    public static readonly IReadOnlySet<string> Collections =
        new HashSet<string>(StringComparer.Ordinal) { "music", "places", "restaurants", "inspiration", "recipes" /* eski anahtar */ };

    /// <summary>Panelden yazılabilen koleksiyonlar ("recipes" yalnızca eski dosyalar için okunur).</summary>
    public static readonly IReadOnlySet<string> WritableCollections =
        new HashSet<string>(StringComparer.Ordinal) { "music", "places", "restaurants", "inspiration" };

    public const int MaxItems = 50;
    public const int MaxNoteLength = 500;
    public const int MaxUrlLength = 2048;
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };
    private static readonly Lazy<OnboardingDemoContentDto> Embedded = new(LoadEmbedded);

    private readonly Microsoft.Extensions.Options.IOptionsMonitor<OnboardingOptions> _options;
    private readonly ILogger<OnboardingDemoContentProvider> _logger;
    private readonly object _gate = new();
    private (string Path, DateTime Modified, OnboardingDemoContentDto Content)? _fileCache;

    public OnboardingDemoContentProvider(
        Microsoft.Extensions.Options.IOptionsMonitor<OnboardingOptions> options,
        ILogger<OnboardingDemoContentProvider> logger)
    {
        _options = options;
        _logger = logger;
    }

    public OnboardingDemoContentDto Get()
    {
        var path = _options.CurrentValue.DemoContentPath;
        if (string.IsNullOrWhiteSpace(path) || !File.Exists(path))
        {
            return Embedded.Value;
        }

        try
        {
            var modified = File.GetLastWriteTimeUtc(path);
            lock (_gate)
            {
                if (_fileCache is { } cached && cached.Path == path && cached.Modified == modified)
                {
                    return cached.Content;
                }
            }

            var content = Parse(File.ReadAllText(path));
            if (content.Items.Count == 0)
            {
                _logger.LogWarning("Onboarding demo content file {Path} has no valid items; using the built-in list.", path);
                return Embedded.Value;
            }

            lock (_gate)
            {
                _fileCache = (path, modified, content);
            }

            return content;
        }
        catch (Exception ex) when (ex is IOException or JsonException or UnauthorizedAccessException)
        {
            _logger.LogWarning(ex, "Onboarding demo content file {Path} could not be read; using the built-in list.", path);
            return Embedded.Value;
        }
    }

    /// <summary>Yönetim paneli için notlarıyla birlikte geçerli liste.</summary>
    public OnboardingDemoAdminContentDto GetForAdmin()
    {
        var path = _options.CurrentValue.DemoContentPath;
        var writable = !string.IsNullOrWhiteSpace(path);
        if (writable && File.Exists(path))
        {
            try
            {
                var fromFile = ParseAdmin(File.ReadAllText(path));
                if (fromFile.Items.Count > 0)
                {
                    return fromFile with { Source = "file", Writable = true };
                }
            }
            catch (Exception ex) when (ex is IOException or JsonException or UnauthorizedAccessException)
            {
                _logger.LogWarning(ex, "Onboarding demo content file {Path} could not be read for admin.", path);
            }
        }

        return ParseAdmin(ReadEmbeddedJson()) with { Source = "embedded", Writable = writable };
    }

    /// <summary>
    /// Listeyi doğrular ve <see cref="OnboardingOptions.DemoContentPath"/> dosyasına atomik yazar
    /// (aynı klasörde geçici dosya + yeniden adlandırma). Sürüm UTC zaman damgasıdır.
    /// </summary>
    public OnboardingDemoAdminContentDto Save(IReadOnlyList<OnboardingDemoAdminItemDto>? items, DateTimeOffset now)
    {
        var path = _options.CurrentValue.DemoContentPath;
        if (string.IsNullOrWhiteSpace(path))
        {
            throw new InvalidOperationException("Onboarding:DemoContentPath is not configured.");
        }

        var clean = Validate(items);
        var version = now.UtcDateTime.ToString("yyyy-MM-dd'T'HH:mm:ss'Z'", System.Globalization.CultureInfo.InvariantCulture);
        var json = JsonSerializer.Serialize(
            new { version, items = clean.Select(i => new { collection = i.Collection, url = i.Url, note = i.Note }) },
            new JsonSerializerOptions
            {
                WriteIndented = true,
                Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping
            });

        var fullPath = Path.GetFullPath(path);
        var directory = Path.GetDirectoryName(fullPath)!;
        Directory.CreateDirectory(directory);
        var temp = Path.Combine(directory, $".{Path.GetFileName(fullPath)}.{Guid.NewGuid():N}.tmp");
        try
        {
            File.WriteAllText(temp, json + "\n");
            File.Move(temp, fullPath, overwrite: true);
        }
        finally
        {
            if (File.Exists(temp)) File.Delete(temp);
        }

        lock (_gate)
        {
            _fileCache = null;
        }

        _logger.LogInformation("Onboarding demo content saved: {Count} items, version {Version}.", clean.Count, version);
        return new OnboardingDemoAdminContentDto(version, clean, "file", true);
    }

    internal static IReadOnlyList<OnboardingDemoAdminItemDto> Validate(IReadOnlyList<OnboardingDemoAdminItemDto>? items)
    {
        if (items == null || items.Count == 0)
            throw new OnboardingDemoContentValidationException("At least one item is required.");
        if (items.Count > MaxItems)
            throw new OnboardingDemoContentValidationException($"At most {MaxItems} items are allowed.");

        var result = new List<OnboardingDemoAdminItemDto>(items.Count);
        for (var index = 0; index < items.Count; index++)
        {
            var item = items[index];
            var collection = item?.Collection?.Trim();
            var url = item?.Url?.Trim();
            if (collection == null || !WritableCollections.Contains(collection))
                throw new OnboardingDemoContentValidationException($"Item {index}: unknown collection.");
            if (string.IsNullOrEmpty(url) || url.Length > MaxUrlLength
                || !Uri.TryCreate(url, UriKind.Absolute, out var uri)
                || (uri.Scheme != Uri.UriSchemeHttps && uri.Scheme != Uri.UriSchemeHttp)
                || string.IsNullOrEmpty(uri.Host))
                throw new OnboardingDemoContentValidationException($"Item {index}: url must be an absolute http(s) URL.");
            var note = string.IsNullOrWhiteSpace(item!.Note) ? null : item.Note.Trim();
            if (note is { Length: > MaxNoteLength })
                throw new OnboardingDemoContentValidationException($"Item {index}: note is longer than {MaxNoteLength} characters.");
            result.Add(new OnboardingDemoAdminItemDto(collection, url, note));
        }

        return result;
    }

    private static OnboardingDemoAdminContentDto ParseAdmin(string json)
    {
        var raw = JsonSerializer.Deserialize<RawContent>(json, JsonOptions) ?? new RawContent();
        var items = (raw.Items ?? [])
            .Where(i => i.Collection != null && Collections.Contains(i.Collection))
            .Where(i => Uri.TryCreate(i.Url, UriKind.Absolute, out var uri)
                && (uri.Scheme == Uri.UriSchemeHttps || uri.Scheme == Uri.UriSchemeHttp))
            .Take(MaxItems)
            .Select(i => new OnboardingDemoAdminItemDto(i.Collection!, i.Url!, i.Note))
            .ToList();
        return new OnboardingDemoAdminContentDto(raw.Version ?? "unknown", items, "file", false);
    }

    internal static OnboardingDemoContentDto Parse(string json)
    {
        var raw = JsonSerializer.Deserialize<RawContent>(json, JsonOptions) ?? new RawContent();
        var items = (raw.Items ?? [])
            .Where(i => i.Collection != null && Collections.Contains(i.Collection))
            .Where(i => Uri.TryCreate(i.Url, UriKind.Absolute, out var uri)
                && (uri.Scheme == Uri.UriSchemeHttps || uri.Scheme == Uri.UriSchemeHttp))
            .Take(MaxItems)
            .Select(i => new OnboardingDemoItemDto(i.Collection!, i.Url!))
            .ToList();
        return new OnboardingDemoContentDto(raw.Version ?? "unknown", items);
    }

    private static OnboardingDemoContentDto LoadEmbedded() => Parse(ReadEmbeddedJson());

    private static string ReadEmbeddedJson()
    {
        using var stream = typeof(OnboardingDemoContentProvider).Assembly.GetManifestResourceStream("SomineApi.OnboardingDemoContent")
            ?? throw new InvalidOperationException("Onboarding demo content resource is missing.");
        using var reader = new StreamReader(stream);
        return reader.ReadToEnd();
    }

    private sealed class RawContent
    {
        public string? Version { get; set; }
        public List<RawItem>? Items { get; set; }
    }

    private sealed class RawItem
    {
        public string? Collection { get; set; }
        public string? Url { get; set; }

        [JsonPropertyName("note")]
        public string? Note { get; set; }
    }
}
