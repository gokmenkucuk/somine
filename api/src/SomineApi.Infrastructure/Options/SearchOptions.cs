namespace SomineApi.Infrastructure.Options;

/// <summary>
/// Anahtar kelime aramasının (pg_trgm) davranışını yapılandırır.
/// Yalnızca PostgreSQL sağlayıcısında etkilidir; SQLite'ta trigram yolu hiç çalışmaz.
/// </summary>
public class SearchOptions
{
    public const string SectionName = "Search";

    /// <summary>
    /// pg_trgm <c>strict_word_similarity()</c> eşiği (0..1).
    /// <para>
    /// Varsayılan, sunucudaki <c>pg_trgm.strict_word_similarity_threshold</c> varsayılanıyla
    /// (0.5) hizalıdır. Index hızlandırmasını sağlayan <c>&lt;&lt;%</c> operatörü ön elemeyi
    /// bu sunucu ayarına göre yaptığı için, buradan verilen değer aramayı yalnızca
    /// DARALTABİLİR: efektif eşik <c>max(bu değer, sunucu ayarı)</c>'dır. Daha gevşek bir
    /// arama istenirse sunucu ayarının da düşürülmesi gerekir
    /// (<c>ALTER DATABASE ... SET pg_trgm.strict_word_similarity_threshold = ...</c>).
    /// </para>
    /// </summary>
    public float TrigramSimilarityThreshold { get; set; } = 0.5f;

    /// <summary>
    /// Trigram aramasının devreye girmesi için gereken en küçük sorgu uzunluğu.
    /// 1-2 karakterlik sorgularda trigram anlamsızlaşır (3-gram üretilemez),
    /// bu yüzden klasik LIKE davranışına düşülür.
    /// </summary>
    public int MinTrigramQueryLength { get; set; } = 3;

    /// <summary>Trigram (yazım hatası toleranslı) arama tamamen kapatılabilir.</summary>
    public bool TrigramEnabled { get; set; } = true;

    /// <summary>Yapılandırmadan gelen değerleri güvenli aralığa sıkıştırır.</summary>
    public float EffectiveThreshold => Math.Clamp(TrigramSimilarityThreshold, 0.05f, 1.0f);

    /// <summary>Trigram için anlamlı en küçük uzunluk 3'ün altına indirilemez.</summary>
    public int EffectiveMinQueryLength => Math.Max(3, MinTrigramQueryLength);
}
