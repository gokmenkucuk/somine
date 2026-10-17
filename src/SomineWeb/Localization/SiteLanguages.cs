using System.Globalization;

namespace SomineWeb.Localization;

/// <summary>
/// Sitenin desteklediği diller ve dile bağlı sabitler tek yerden yönetilir.
/// Yeni bir dil eklemek için yalnızca burası ve resx dosyaları değişir.
/// </summary>
public static class SiteLanguages
{
    public const string Default = "tr";
    public const string English = "en";

    /// <summary>Sıralama önemli: dil değiştiricide bu sırayla gösterilir.</summary>
    public static readonly string[] Supported = [Default, English];

    public static readonly CultureInfo[] SupportedCultures =
        [.. Supported.Select(c => new CultureInfo(c))];

    /// <summary>Kullanıcıdan gelen serbest metni desteklenen bir dil koduna indirger; tanımadığını atar.</summary>
    public static string? Normalize(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return null;

        var candidate = value.Trim();

        // "en-US", "tr-TR" gibi bölgeli kodların yalnızca dil kısmı bizi ilgilendiriyor.
        var dash = candidate.IndexOf('-');
        if (dash > 0)
            candidate = candidate[..dash];

        foreach (var supported in Supported)
        {
            if (string.Equals(candidate, supported, StringComparison.OrdinalIgnoreCase))
                return supported;
        }

        return null;
    }

    /// <summary>Verilen dilin geçerli olduğundan emin olur; değilse varsayılana düşer.</summary>
    public static string NormalizeOrDefault(string? value) => Normalize(value) ?? Default;

    /// <summary>Aktif isteğin dili (UI culture'dan türetilir).</summary>
    public static string Current => NormalizeOrDefault(CultureInfo.CurrentUICulture.TwoLetterISOLanguageName);

    /// <summary>og:locale / og:locale:alternate için Facebook'un beklediği biçim.</summary>
    public static string OpenGraphLocale(string language) => language switch
    {
        English => "en_US",
        _ => "tr_TR",
    };

    /// <summary>hreflang ve &lt;html lang&gt; için kullanılan kod.</summary>
    public static string HtmlLang(string language) => language;

    /// <summary>Dil değiştiricide gösterilen kısa etiket.</summary>
    public static string ShortLabel(string language) => language.ToUpperInvariant();
}
