using System.Net;
using System.Net.Sockets;
using System.Security.Cryptography;
using Microsoft.Extensions.Options;
using SomineApi.Application.Interfaces;

namespace SomineApi.WebApi.ImageCache;

public enum ImageCacheStatus
{
    Cached,
    /// <summary>Kaynak kalıcı olarak alınamaz (403/404/410, SSRF engeli, geçersiz içerik, boyut aşımı). Yeniden denenmez.</summary>
    PermanentFailure,
    /// <summary>Geçici sorun (zaman aşımı, 5xx, ağ hatası). Sonraki backfill turunda yeniden denenebilir.</summary>
    TransientFailure
}

public sealed record ImageCacheResult(ImageCacheStatus Status, string? Url, string? Reason)
{
    public static ImageCacheResult Ok(string url) => new(ImageCacheStatus.Cached, url, null);
    public static ImageCacheResult Permanent(string reason) => new(ImageCacheStatus.PermanentFailure, null, reason);
    public static ImageCacheResult Transient(string reason) => new(ImageCacheStatus.TransientFailure, null, reason);
}

public interface IImageCacheService
{
    /// <summary>Harici görseli indirir, doğrular, içerik özetiyle saklar ve kendi public adresimizi döner. Asla fırlatmaz (iptal hariç).</summary>
    Task<ImageCacheResult> CacheAsync(string sourceUrl, CancellationToken cancellationToken);
}

public sealed class ImageCacheService : IImageCacheService
{
    public const string HttpClientName = "ImageCache";
    public const string ObjectPrefix = "og";

    private const string UserAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1";

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IHostAddressResolver _resolver;
    private readonly IStorageService _storage;
    private readonly IOptions<ImageCacheOptions> _options;
    private readonly ILogger<ImageCacheService> _logger;

    public ImageCacheService(
        IHttpClientFactory httpClientFactory,
        IHostAddressResolver resolver,
        IStorageService storage,
        IOptions<ImageCacheOptions> options,
        ILogger<ImageCacheService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _resolver = resolver;
        _storage = storage;
        _options = options;
        _logger = logger;
    }

    public async Task<ImageCacheResult> CacheAsync(string sourceUrl, CancellationToken cancellationToken)
    {
        var options = _options.Value;
        using var timeout = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken);
        timeout.CancelAfter(options.Timeout);

        try
        {
            var download = await DownloadAsync(sourceUrl, options, timeout.Token);
            if (download.Failure != null)
                return download.Failure;

            var bytes = download.Bytes!;
            var extension = DetectImageExtension(bytes);
            if (extension == null)
                return ImageCacheResult.Permanent("unrecognized_image_signature");

            var hash = Convert.ToHexStringLower(SHA256.HashData(bytes));
            var relativePath = $"{ObjectPrefix}/{hash}.{extension}";
            // İçerik adresli: aynı görsel (farklı imzalı URL'lerle de gelse) tek dosya olarak paylaşılır.
            if (!_storage.PublicObjectExists(relativePath))
                await _storage.SavePublicObjectAsync(relativePath, bytes, timeout.Token);

            return ImageCacheResult.Ok(_storage.GetPublicObjectUrl(relativePath));
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (OperationCanceledException)
        {
            return ImageCacheResult.Transient("timeout");
        }
        catch (HttpRequestException ex) when (ex.InnerException is BlockedAddressException)
        {
            return ImageCacheResult.Permanent("blocked_address");
        }
        catch (HttpRequestException ex)
        {
            _logger.LogInformation("OG image download failed for host {Host}: {Message}", SafeHost(sourceUrl), ex.Message);
            return ImageCacheResult.Transient("network_error");
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Unexpected error caching OG image from host {Host}", SafeHost(sourceUrl));
            return ImageCacheResult.Transient("unexpected_error");
        }
    }

    private sealed record DownloadResult(byte[]? Bytes, ImageCacheResult? Failure);

    private async Task<DownloadResult> DownloadAsync(string sourceUrl, ImageCacheOptions options, CancellationToken ct)
    {
        if (!Uri.TryCreate(sourceUrl, UriKind.Absolute, out var uri))
            return new(null, ImageCacheResult.Permanent("invalid_url"));

        var client = _httpClientFactory.CreateClient(HttpClientName);

        for (var hop = 0; ; hop++)
        {
            var blocked = await ValidateTargetAsync(uri, ct);
            if (blocked != null)
                return new(null, blocked);

            using var request = new HttpRequestMessage(HttpMethod.Get, uri);
            request.Headers.TryAddWithoutValidation("User-Agent", UserAgent);
            request.Headers.TryAddWithoutValidation("Accept", "image/webp,image/png,image/jpeg,image/gif;q=0.9,image/*;q=0.8");
            request.Headers.Referrer = RefererFor(uri);

            using var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, ct);

            if (IsRedirect(response.StatusCode))
            {
                if (hop >= options.MaxRedirects)
                    return new(null, ImageCacheResult.Permanent("too_many_redirects"));
                var location = response.Headers.Location;
                if (location == null)
                    return new(null, ImageCacheResult.Permanent("redirect_without_location"));
                uri = location.IsAbsoluteUri ? location : new Uri(uri, location);
                continue;
            }

            if (response.StatusCode is HttpStatusCode.Forbidden or HttpStatusCode.NotFound or HttpStatusCode.Gone
                or HttpStatusCode.Unauthorized or HttpStatusCode.BadRequest)
                return new(null, ImageCacheResult.Permanent($"http_{(int)response.StatusCode}"));

            if (!response.IsSuccessStatusCode)
                return new(null, ImageCacheResult.Transient($"http_{(int)response.StatusCode}"));

            var mediaType = response.Content.Headers.ContentType?.MediaType;
            if (mediaType == null || !mediaType.StartsWith("image/", StringComparison.OrdinalIgnoreCase) ||
                mediaType.Contains("svg", StringComparison.OrdinalIgnoreCase))
                return new(null, ImageCacheResult.Permanent("unsupported_content_type"));

            if (response.Content.Headers.ContentLength is { } declared && declared > options.MaxBytes)
                return new(null, ImageCacheResult.Permanent("too_large"));

            var bytes = await ReadWithLimitAsync(response.Content, options.MaxBytes, ct);
            if (bytes == null)
                return new(null, ImageCacheResult.Permanent("too_large"));
            if (bytes.Length == 0)
                return new(null, ImageCacheResult.Permanent("empty_body"));

            return new(bytes, null);
        }
    }

    /// <summary>Her hop'ta şema ve hedef host'un çözümlenen TÜM adresleri denetlenir.</summary>
    private async Task<ImageCacheResult?> ValidateTargetAsync(Uri uri, CancellationToken ct)
    {
        if (uri.Scheme != Uri.UriSchemeHttp && uri.Scheme != Uri.UriSchemeHttps)
            return ImageCacheResult.Permanent("unsupported_scheme");
        if (!string.IsNullOrEmpty(uri.UserInfo))
            return ImageCacheResult.Permanent("userinfo_not_allowed");

        IPAddress[] addresses;
        try
        {
            addresses = await _resolver.ResolveAsync(uri.DnsSafeHost, ct);
        }
        catch (SocketException)
        {
            return ImageCacheResult.Permanent("dns_failure");
        }

        if (addresses.Length == 0)
            return ImageCacheResult.Permanent("dns_failure");
        if (addresses.Any(a => !IpAddressPolicy.IsPublic(a)))
            return ImageCacheResult.Permanent("blocked_address");
        return null;
    }

    private static async Task<byte[]?> ReadWithLimitAsync(HttpContent content, long maxBytes, CancellationToken ct)
    {
        await using var stream = await content.ReadAsStreamAsync(ct);
        using var buffer = new MemoryStream();
        var chunk = new byte[81920];
        int read;
        while ((read = await stream.ReadAsync(chunk, ct)) > 0)
        {
            if (buffer.Length + read > maxBytes)
                return null;
            buffer.Write(chunk, 0, read);
        }

        return buffer.ToArray();
    }

    private static bool IsRedirect(HttpStatusCode code) => code is HttpStatusCode.MovedPermanently
        or HttpStatusCode.Found or HttpStatusCode.SeeOther or HttpStatusCode.TemporaryRedirect
        or HttpStatusCode.PermanentRedirect;

    /// <summary>Gerçek baytlardan biçim tespiti — Content-Type'a güvenilmez. SVG ve diğer her şey reddedilir.</summary>
    public static string? DetectImageExtension(ReadOnlySpan<byte> b)
    {
        if (b.Length >= 3 && b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF)
            return "jpg";
        if (b.Length >= 8 && b[..8].SequenceEqual(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }))
            return "png";
        if (b.Length >= 6 && (b[..6].SequenceEqual("GIF87a"u8) || b[..6].SequenceEqual("GIF89a"u8)))
            return "gif";
        if (b.Length >= 12 && b[..4].SequenceEqual("RIFF"u8) && b[8..12].SequenceEqual("WEBP"u8))
            return "webp";
        return null;
    }

    // Bazı CDN'ler hotlink koruması uygular; mobil istemcinin gönderdiği Referer eşlemesinin aynısı.
    private static Uri RefererFor(Uri uri)
    {
        var host = uri.Host;
        (string Suffix, string Referer)[] map =
        [
            ("pinimg.com", "https://www.pinterest.com/"),
            ("cdninstagram.com", "https://www.instagram.com/"),
            ("fbcdn.net", "https://www.facebook.com/"),
            ("twimg.com", "https://twitter.com/"),
            ("tiktokcdn.com", "https://www.tiktok.com/")
        ];
        foreach (var (suffix, referer) in map)
        {
            if (host.EndsWith(suffix, StringComparison.OrdinalIgnoreCase))
                return new Uri(referer);
        }

        return new Uri($"{uri.Scheme}://{uri.Authority}/");
    }

    private static string SafeHost(string url)
        => Uri.TryCreate(url, UriKind.Absolute, out var uri) ? uri.Host : "invalid";

    /// <summary>
    /// Prod HTTP handler'ı: bağlantı anında DNS yeniden çözülür ve yalnız public adreslere bağlanılır.
    /// Ön denetim ile bağlantı arasındaki DNS rebinding saldırısını kapatır. Proxy ve otomatik
    /// yönlendirme kapalıdır (yönlendirmeler her hop'ta yeniden denetlenerek elle izlenir).
    /// </summary>
    public static SocketsHttpHandler CreatePrimaryHandler() => new()
    {
        AllowAutoRedirect = false,
        UseProxy = false,
        UseCookies = false,
        AutomaticDecompression = DecompressionMethods.None,
        ConnectTimeout = TimeSpan.FromSeconds(5),
        ConnectCallback = async (context, ct) =>
        {
            var host = context.DnsEndPoint.Host;
            var addresses = IPAddress.TryParse(host, out var literal)
                ? [literal]
                : await Dns.GetHostAddressesAsync(host, ct);
            if (addresses.Length == 0 || addresses.Any(a => !IpAddressPolicy.IsPublic(a)))
                throw new BlockedAddressException(host);

            var socket = new Socket(SocketType.Stream, ProtocolType.Tcp) { NoDelay = true };
            try
            {
                await socket.ConnectAsync(addresses, context.DnsEndPoint.Port, ct);
                return new NetworkStream(socket, ownsSocket: true);
            }
            catch
            {
                socket.Dispose();
                throw;
            }
        }
    };

    private sealed class BlockedAddressException(string host)
        : Exception($"Connection to non-public address of '{host}' blocked.");
}
