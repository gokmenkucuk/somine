namespace SomineApi.WebApi.ImageCache;

/// <summary>
/// OG önizleme görsellerinin sunucuda kalıcılaştırılması. Instagram/Facebook CDN adresleri imzalı
/// ve birkaç günde süresi doluyor; görsel bir kez indirilip kendi depolamamızdan servis edilir.
/// Prod env: <c>ImageCache__Enabled</c>, <c>ImageCache__BackfillOnStartup</c> …
/// </summary>
public sealed class ImageCacheOptions
{
    public const string SectionName = "ImageCache";

    public bool Enabled { get; set; } = true;

    /// <summary>İndirilecek görselin üst sınırı (bayt). Aşılırsa kaynak kalıcı hata sayılır.</summary>
    public long MaxBytes { get; set; } = 5 * 1024 * 1024;

    /// <summary>Tüm yönlendirmeler dahil tek bir indirmenin toplam süresi.</summary>
    public TimeSpan Timeout { get; set; } = TimeSpan.FromSeconds(10);

    public int MaxRedirects { get; set; } = 3;

    /// <summary>Açılışta mevcut item'ların harici OG görsellerini işle (tek seferlik, tekrar çalışması güvenli).</summary>
    public bool BackfillOnStartup { get; set; }

    public int BackfillBatchSize { get; set; } = 20;

    /// <summary>Uygulama açılışından sonra backfill'e başlamadan önce bekleme.</summary>
    public TimeSpan BackfillStartupDelay { get; set; } = TimeSpan.FromSeconds(30);

    /// <summary>Backfill'de iki indirme arası bekleme (kaynak sitelere nazik davran).</summary>
    public TimeSpan BackfillItemDelay { get; set; } = TimeSpan.FromMilliseconds(500);
}
