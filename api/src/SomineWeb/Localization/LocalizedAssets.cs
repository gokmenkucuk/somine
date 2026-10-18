using System.Collections.Concurrent;

namespace SomineWeb.Localization;

/// <summary>
/// Ekran görüntüleri dile bağlı: uygulama arayüzü Türkçe/İngilizce olduğu için
/// mockup'ların da dili değişiyor. Kural, dosya adının sonuna <c>_en</c> eklemek —
/// <c>home.png</c> → <c>home_en.png</c>.
/// </summary>
/// <remarks>
/// Her görselin İngilizcesi hazır olmayabilir. Bu yüzden yol körlemesine
/// değiştirilmiyor: dosya <c>wwwroot</c> altında gerçekten varsa geçiliyor, yoksa
/// Türkçesine düşülüyor. Böylece eksik bir görsel kırık resme değil, mevcut olana
/// denk gelir. Sonuçlar önbelleğe alınıyor; disk her istekte yoklanmıyor.
/// </remarks>
public sealed class LocalizedAssets(IWebHostEnvironment environment)
{
    private const string EnglishSuffix = "_en";

    private readonly ConcurrentDictionary<string, string> _resolved = new(StringComparer.Ordinal);

    /// <summary>Aktif dile uygun görsel yolunu döndürür.</summary>
    public string Resolve(string path)
    {
        if (string.IsNullOrWhiteSpace(path) || SiteLanguages.Current != SiteLanguages.English)
            return path;

        return _resolved.GetOrAdd(path, ResolveEnglish);
    }

    private string ResolveEnglish(string path)
    {
        var extension = Path.GetExtension(path);
        if (string.IsNullOrEmpty(extension))
            return path;

        var candidate = string.Concat(path.AsSpan(0, path.Length - extension.Length), EnglishSuffix, extension);

        var relative = candidate.TrimStart('/').Replace('/', Path.DirectorySeparatorChar);
        var physical = Path.Combine(environment.WebRootPath, relative);

        return File.Exists(physical) ? candidate : path;
    }
}
