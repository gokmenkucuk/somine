using System.Net;
using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.RazorPages;

namespace SomineWeb.Pages;

public class ShareModel : PageModel
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;

    private static readonly JsonSerializerOptions JsonOptions = new(JsonSerializerDefaults.Web);

    public ShareModel(IHttpClientFactory httpClientFactory, IConfiguration configuration)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
    }

    public bool Found { get; private set; }
    public PublicShare? Share { get; private set; }
    public string Token { get; private set; } = string.Empty;
    public string AppStoreUrl => _configuration["AppStoreUrl"] ?? "https://apps.apple.com/app/somine";
    public string AppStoreId => _configuration["AppStoreId"] ?? string.Empty;

    private const string FallbackOgImage = "https://somineapp.com/images/logo-gradient.png";

    // 404 (Found=false) durumunda koleksiyon bilgisi sızdırmayan nötr metinler döner.
    public string OgTitle => Found && Share != null
        ? $"{Share.CategoryName} — Somine"
        : "Somine";

    public string OgDescription => Found && Share != null
        ? (Share.Items.Count > 0
            ? $"{Share.Items.Count} içerik içeren bir Somine koleksiyonu."
            : "Somine'de paylaşılan bir koleksiyon.")
        : "Beğendiğin içerikleri Somine ile tek bir yerde topla.";

    // İlk görseli olan item'ın OG görseli (mutlak http/https URL); yoksa landing OG görseli.
    public string OgImage
    {
        get
        {
            if (Found && Share != null)
            {
                foreach (var item in Share.Items)
                {
                    var candidate = ResolveImageUrl(item.OgImageUrl) ?? ResolveImageUrl(item.ImageUrl);
                    if (!string.IsNullOrWhiteSpace(candidate)
                        && Uri.TryCreate(candidate, UriKind.Absolute, out var uri)
                        && (uri.Scheme == Uri.UriSchemeHttp || uri.Scheme == Uri.UriSchemeHttps))
                    {
                        return candidate;
                    }
                }
            }

            return FallbackOgImage;
        }
    }

    private string ApiBaseUrl => (_configuration["Api:BaseUrl"] ?? "http://localhost:5181").TrimEnd('/');

    public async Task<IActionResult> OnGetAsync(string token, CancellationToken cancellationToken)
    {
        Token = token;

        var client = _httpClientFactory.CreateClient("SomineApi");

        try
        {
            using var response = await client.GetAsync($"/public/shares/{Uri.EscapeDataString(token)}", cancellationToken);

            if (response.StatusCode == HttpStatusCode.OK)
            {
                var payload = await response.Content.ReadAsStringAsync(cancellationToken);
                Share = JsonSerializer.Deserialize<PublicShare>(payload, JsonOptions);
                Found = Share != null;
            }
            else
            {
                Found = false;
            }
        }
        catch (HttpRequestException)
        {
            Found = false;
        }

        if (!Found)
        {
            Response.StatusCode = StatusCodes.Status404NotFound;
        }

        return Page();
    }

    // /api/storage/... yetkili URL'leri public files ucuna yonlendirir; harici URL'ler oldugu gibi kalir.
    public string? ResolveImageUrl(string? url)
    {
        if (string.IsNullOrWhiteSpace(url))
            return null;

        const string marker = "/api/storage/";
        var index = url.IndexOf(marker, StringComparison.OrdinalIgnoreCase);
        if (index >= 0)
        {
            var fileName = url[(index + marker.Length)..];
            var slash = fileName.IndexOf('/');
            if (slash >= 0) fileName = fileName[..slash];
            var query = fileName.IndexOf('?');
            if (query >= 0) fileName = fileName[..query];
            if (string.IsNullOrWhiteSpace(fileName))
                return null;
            return $"{ApiBaseUrl}/public/shares/{Uri.EscapeDataString(Token)}/files/{fileName}";
        }

        return url;
    }

    public class PublicShare
    {
        public string CategoryName { get; set; } = string.Empty;
        public string? FromUserName { get; set; }
        public List<PublicItem> Items { get; set; } = [];
    }

    public class PublicItem
    {
        public Guid Id { get; set; }
        public int Type { get; set; } // 0=Link, 1=Note, 2=Image
        public string? Url { get; set; }
        public string? Note { get; set; }
        public string? ImageUrl { get; set; }
        public string? OgTitle { get; set; }
        public string? OgDescription { get; set; }
        public string? OgImageUrl { get; set; }
        public string? OgSiteName { get; set; }
        public string? OgFaviconUrl { get; set; }
        public DateTime CreatedAt { get; set; }
    }
}
