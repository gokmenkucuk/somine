using System.Text.Json;
using System.Text.Json.Serialization;

namespace SomineApi.WebApi.Onboarding;

public sealed record OnboardingDemoItemDto(string Collection, string Url);

public sealed record OnboardingDemoContentDto(string Version, IReadOnlyList<OnboardingDemoItemDto> Items);

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
        new HashSet<string>(StringComparer.Ordinal) { "music", "places", "recipes", "inspiration" };

    private const int MaxItems = 50;
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

    private static OnboardingDemoContentDto LoadEmbedded()
    {
        using var stream = typeof(OnboardingDemoContentProvider).Assembly.GetManifestResourceStream("SomineApi.OnboardingDemoContent")
            ?? throw new InvalidOperationException("Onboarding demo content resource is missing.");
        using var reader = new StreamReader(stream);
        return Parse(reader.ReadToEnd());
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
