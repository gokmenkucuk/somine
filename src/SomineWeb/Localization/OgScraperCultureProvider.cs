using Microsoft.AspNetCore.Localization;

namespace SomineWeb.Localization;

/// <summary>
/// Paylaşım kartlarını üreten kazıyıcılar (facebookexternalhit, Twitterbot, WhatsApp…) için
/// dili deterministik hale getirir.
///
/// Sorun: bu botların çoğu Accept-Language göndermez, gönderenlerin başlığı da paylaşan ya da
/// linki açacak kişiyle ilgisizdir (sunucu konumuna göre "en-US" gelebilir). Sonuçta aynı
/// bağlantının OG kartı ile sayfanın gerçek dili birbirini tutmayabilir.
///
/// Çözüm: bot olduğunu anladığımızda — kullanıcı bağlantıya açıkça ?lang= koymadıysa — dili
/// varsayılana (tr) sabitliyoruz. Bu sağlayıcı zincirde QueryString'ten SONRA durduğu için
/// açık seçim her zaman kazanır; ondan sonrası (çerez / Accept-Language) bot için atlanır.
/// </summary>
public sealed class OgScraperCultureProvider : RequestCultureProvider
{
    // Paylaşım önizlemesi üreten yaygın istemciler. Eksiği zarar vermez: eşleşmeyen bir bot
    // yalnızca normal zincire düşer ve orada da büyük olasılıkla tr'ye iner.
    private static readonly string[] ScraperTokens =
    [
        "facebookexternalhit",
        "facebookcatalog",
        "twitterbot",
        "whatsapp",
        "telegrambot",
        "slackbot",
        "slack-imgproxy",
        "discordbot",
        "linkedinbot",
        "pinterest",
        "redditbot",
        "skypeuripreview",
        "applebot",
        "googlebot",
        "bingbot",
        "bingpreview",
        "embedly",
        "iframely",
        "quora link preview",
        "vkshare",
        "flipboard",
        "tumblr",
        "viber",
        "signal",
        "mastodon",
        "bitlybot",
        "nuzzel",
        "outbrain",
        "w3c_validator",
        "developers.google.com/+/web/snippet",
    ];

    public override Task<ProviderCultureResult?> DetermineProviderCultureResult(HttpContext httpContext)
    {
        ArgumentNullException.ThrowIfNull(httpContext);

        var userAgent = httpContext.Request.Headers.UserAgent.ToString();
        if (string.IsNullOrWhiteSpace(userAgent))
            return Task.FromResult<ProviderCultureResult?>(null);

        foreach (var token in ScraperTokens)
        {
            if (userAgent.Contains(token, StringComparison.OrdinalIgnoreCase))
            {
                return Task.FromResult<ProviderCultureResult?>(
                    new ProviderCultureResult(SiteLanguages.Default, SiteLanguages.Default));
            }
        }

        return Task.FromResult<ProviderCultureResult?>(null);
    }
}
