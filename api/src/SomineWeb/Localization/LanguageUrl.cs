using Microsoft.AspNetCore.Http.Extensions;

namespace SomineWeb.Localization;

/// <summary>
/// hreflang, canonical ve dil değiştirici bağlantılarını tek yerden üretir.
/// Mutlak adresler her zaman kanonik ana bilgisayar üzerinden kurulur; site arkasında
/// proxy olduğu için Request.Host'a güvenilmez.
/// </summary>
public static class LanguageUrl
{
    public const string CanonicalOrigin = "https://somineapp.com";
    public const string QueryKey = "lang";

    /// <summary>Geçerli yolun, dil parametresi arındırılmış hali (sorgu dizesi korunur).</summary>
    public static string PathWithoutLanguage(HttpRequest request)
    {
        var query = QueryString.Empty;

        foreach (var pair in request.Query)
        {
            if (string.Equals(pair.Key, QueryKey, StringComparison.OrdinalIgnoreCase))
                continue;

            foreach (var value in pair.Value)
                query = query.Add(pair.Key, value ?? string.Empty);
        }

        return request.Path.ToUriComponent() + query.ToUriComponent();
    }

    /// <summary>Geçerli sayfanın belirtilen dildeki göreli adresi (dil değiştirici için).</summary>
    public static string RelativeFor(HttpRequest request, string language)
    {
        var basePath = PathWithoutLanguage(request);
        var separator = basePath.Contains('?') ? '&' : '?';
        return $"{basePath}{separator}{QueryKey}={language}";
    }

    /// <summary>Geçerli sayfanın belirtilen dildeki mutlak adresi (hreflang / canonical için).</summary>
    public static string AbsoluteFor(HttpRequest request, string language)
        => CanonicalOrigin + RelativeFor(request, language);

    /// <summary>Dil pazarlığı yapan, parametresiz mutlak adres (hreflang="x-default").</summary>
    public static string AbsoluteNeutral(HttpRequest request)
        => CanonicalOrigin + PathWithoutLanguage(request);
}
