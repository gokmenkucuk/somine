using Microsoft.Extensions.Options;
using SomineApi.Infrastructure.Services;

namespace SomineApi.WebApi.ImageCache;

/// <summary>Bir OG görsel adresinin sunucuya kopyalanması gerekip gerekmediğine karar verir.</summary>
public sealed class OgImageUrlPolicy
{
    private readonly IOptions<ImageCacheOptions> _options;
    private readonly string? _ownHost;

    public OgImageUrlPolicy(IOptions<ImageCacheOptions> options, IConfiguration configuration)
    {
        _options = options;
        var apiBaseUrl = LocalStorageService.ResolveApiBaseUrl(configuration["Storage:BaseUrl"]);
        _ownHost = Uri.TryCreate(apiBaseUrl, UriKind.Absolute, out var baseUri) ? baseUri.Host : null;
    }

    public bool Enabled => _options.Value.Enabled;

    /// <summary>Özellik açık ve adres harici bir http(s) görseliyse true.</summary>
    public bool ShouldCache(string? url) => Enabled && IsExternal(url);

    public bool IsExternal(string? url)
    {
        if (string.IsNullOrWhiteSpace(url))
            return false;
        if (!Uri.TryCreate(url, UriKind.Absolute, out var uri))
            return false;
        if (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps)
            return false;
        // Kendi adreslerimiz (önbelleğe alınmış OG görseli, kullanıcı yüklemesi) asla yeniden indirilmez.
        if (_ownHost != null && string.Equals(uri.Host, _ownHost, StringComparison.OrdinalIgnoreCase))
            return false;
        if (uri.AbsolutePath.Contains("/api/storage/", StringComparison.OrdinalIgnoreCase) ||
            uri.AbsolutePath.StartsWith("/public/og/", StringComparison.OrdinalIgnoreCase))
            return false;
        return true;
    }
}
