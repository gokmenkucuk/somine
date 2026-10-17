using System.Globalization;
using System.Text;
using System.Xml.Linq;
using Microsoft.AspNetCore.Localization;
using SomineWeb.Localization;

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddRazorPages();

// Kısa arayüz metinleri Resources/SharedResource[.en].resx içinde; uzun hukuki metinler
// dile göre ayrı Razor parçalarında (Pages/Shared/_*Body.{tr,en}.cshtml).
builder.Services.AddLocalization(options => options.ResourcesPath = "Resources");

// Ekran görüntüleri de dile bağlı ("_en" ekli dosyalar); İngilizcesi olmayan
// görsellerde Türkçesine düşer.
builder.Services.AddSingleton<SomineWeb.Localization.LocalizedAssets>();

builder.Services.Configure<RequestLocalizationOptions>(options =>
{
    options.DefaultRequestCulture = new RequestCulture(SiteLanguages.Default);
    options.SupportedCultures = SiteLanguages.SupportedCultures;
    options.SupportedUICultures = SiteLanguages.SupportedCultures;
    options.ApplyCurrentCultureToResponseHeaders = true;

    // Sıra bilinçli:
    //  1) ?lang=en|tr        → kullanıcının/paylaşanın açık seçimi her şeyi ezer
    //  2) OG kazıyıcıları    → bot ise (ve açık seçim yoksa) dili tr'ye sabitle, kart
    //                          ile sayfanın dili her koşulda aynı olsun
    //  3) çerez              → daha önce yapılmış seçim kalıcı olsun
    //  4) Accept-Language    → tarayıcının tercihi
    //  5) (zincir boşsa)     → DefaultRequestCulture = tr
    options.RequestCultureProviders =
    [
        new QueryStringRequestCultureProvider
        {
            QueryStringKey = LanguageUrl.QueryKey,
            UIQueryStringKey = LanguageUrl.QueryKey,
        },
        new OgScraperCultureProvider(),
        new CookieRequestCultureProvider(),
        new AcceptLanguageHeaderRequestCultureProvider(),
    ];
});

// API HttpClient — public uçlar için API key gerekmez.
builder.Services.AddHttpClient("SomineApi", (sp, client) =>
{
    var baseUrl = sp.GetRequiredService<IConfiguration>()["Api:BaseUrl"] ?? "http://localhost:5181";
    client.BaseAddress = new Uri(baseUrl);
});

var app = builder.Build();

if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Error");
    app.UseHsts();
}

app.UseHttpsRedirection();

app.UseRequestLocalization();

// QueryStringRequestCultureProvider yalnızca okur, yazmaz. Kullanıcı TR/EN'e bastığında
// seçimin sonraki isteklerde de geçerli olması için çerezi burada kuruyoruz.
app.Use(async (context, next) =>
{
    var requested = SiteLanguages.Normalize(context.Request.Query[LanguageUrl.QueryKey]);
    if (requested is not null)
    {
        context.Response.Cookies.Append(
            CookieRequestCultureProvider.DefaultCookieName,
            CookieRequestCultureProvider.MakeCookieValue(new RequestCulture(requested)),
            new CookieOptions
            {
                Path = "/",
                Expires = DateTimeOffset.UtcNow.AddYears(1),
                IsEssential = true,
                SameSite = SameSiteMode.Lax,
                HttpOnly = false,
                Secure = context.Request.IsHttps,
            });
    }

    await next();
});

app.UseRouting();
app.UseAuthorization();

app.MapStaticAssets();
app.MapRazorPages()
   .WithStaticAssets();

// robots.txt sitemap.xml'e işaret ediyordu ama dosya hiç yoktu (404). Artık iki dili de
// xhtml:link alternatifleriyle listeleyen gerçek bir sitemap var.
// /s/{token} bilinçli olarak DIŞARIDA: o sayfalar noindex.
app.MapGet("/sitemap.xml", () =>
{
    string[] paths = ["/", "/privacy", "/terms", "/support", "/delete-account"];

    XNamespace sm = "http://www.sitemaps.org/schemas/sitemap/0.9";
    XNamespace xhtml = "http://www.w3.org/1999/xhtml";

    var lastModified = DateTime.UtcNow.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture);

    var urlset = new XElement(sm + "urlset", new XAttribute(XNamespace.Xmlns + "xhtml", xhtml));

    foreach (var path in paths)
    {
        foreach (var language in SiteLanguages.Supported)
        {
            var url = new XElement(sm + "url",
                new XElement(sm + "loc", $"{LanguageUrl.CanonicalOrigin}{path}?{LanguageUrl.QueryKey}={language}"),
                new XElement(sm + "lastmod", lastModified),
                new XElement(sm + "changefreq", path == "/" ? "weekly" : "monthly"),
                new XElement(sm + "priority", path == "/" ? "1.0" : "0.6"));

            foreach (var alternate in SiteLanguages.Supported)
            {
                url.Add(new XElement(xhtml + "link",
                    new XAttribute("rel", "alternate"),
                    new XAttribute("hreflang", alternate),
                    new XAttribute("href", $"{LanguageUrl.CanonicalOrigin}{path}?{LanguageUrl.QueryKey}={alternate}")));
            }

            url.Add(new XElement(xhtml + "link",
                new XAttribute("rel", "alternate"),
                new XAttribute("hreflang", "x-default"),
                new XAttribute("href", $"{LanguageUrl.CanonicalOrigin}{path}")));

            urlset.Add(url);
        }
    }

    var document = new XDocument(new XDeclaration("1.0", "utf-8", null), urlset);

    return Results.Text(document.ToString(), "application/xml", Encoding.UTF8);
});

app.Run();
