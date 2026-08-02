using Microsoft.EntityFrameworkCore;
using SomineApi.Domain.Entities;

namespace SomineApi.Infrastructure.Data;

/// <summary>
/// <c>GET /api/items/search</c> anahtar kelime yolunun sorgu kurulumu.
/// Controller'dan ayrı tutulur ki hem PostgreSQL hem SQLite için üretilen SQL
/// canlı veritabanı olmadan (<c>ToQueryString()</c>) test edilebilsin.
/// </summary>
public static class ItemSearchQuery
{
    /// <summary>
    /// LIKE kaçış karakteri. Açıkça verilmezse EF Core <c>ESCAPE ''</c> üretir; PostgreSQL'de
    /// boş kaçış karakteri kaçış işlemeyi TAMAMEN kapatır, yani kullanıcının yazdığı
    /// <c>%</c> / <c>_</c> yine joker olarak davranırdı. Bu yüzden ters bölü açıkça bildirilir.
    /// </summary>
    private const string LikeEscapeCharacter = "\\";

    /// <summary>
    /// Trigram yolunun kullanılıp kullanılmayacağına karar verir.
    /// SQLite (test) veya çok kısa sorgularda daima klasik LIKE davranışı geçerlidir.
    /// </summary>
    public static bool ShouldUseTrigram(bool isNpgsql, bool trigramEnabled, string? q, int minQueryLength)
        => isNpgsql
           && trigramEnabled
           && !string.IsNullOrWhiteSpace(q)
           && q.Trim().Length >= minQueryLength;

    /// <summary>
    /// LIKE meta karakterlerini (<c>\ % _</c>) kaçırır; kullanıcı girdisi joker karaktere dönüşmesin.
    /// </summary>
    public static string EscapeLikePattern(string value)
        => value
            .Replace("\\", "\\\\", StringComparison.Ordinal)
            .Replace("%", "\\%", StringComparison.Ordinal)
            .Replace("_", "\\_", StringComparison.Ordinal);

    /// <summary>
    /// Faz A öncesinden beri kullanılan naif arama. SQLite'ta ve 1-2 karakterlik
    /// sorgularda tek yol budur; davranışı bilinçli olarak birebir korunur.
    /// </summary>
    public static IQueryable<Item> ApplyLikeFilter(IQueryable<Item> query, string q)
    {
        var searchTerm = q.ToLower();
        return query.Where(i =>
            (i.Url != null && i.Url.ToLower().Contains(searchTerm)) ||
            (i.Note != null && i.Note.ToLower().Contains(searchTerm)) ||
            (i.OgTitle != null && i.OgTitle.ToLower().Contains(searchTerm)) ||
            (i.OgDescription != null && i.OgDescription.ToLower().Contains(searchTerm)));
    }

    /// <summary>
    /// pg_trgm tabanlı arama. Her aranabilir sütun için iki dallı bir yüklem kurulur:
    /// <list type="bullet">
    /// <item>
    /// <c>normalize(col) LIKE '%q%'</c> — kısmi eşleşme.
    /// </item>
    /// <item>
    /// <c>q &lt;&lt;% normalize(col) AND strict_word_similarity(q, normalize(col)) &gt;= eşik</c>
    /// — yazım hatası toleransı.
    /// </item>
    /// </list>
    /// <para>
    /// <b>Neden <c>strict_word_similarity</c>, düz <c>similarity</c> değil:</b> <c>similarity()</c>
    /// iki metnin TAMAMINI karşılaştırır, dolayısıyla uzun bir başlıkta geçen tek bir kelimenin
    /// yazım hatası benzerliği uzunlukla seyrelir. Gerçek veriyle ölçüldü: "Kahvatlilik yazim hatasi"
    /// başlığı "kahvaltilik" sorgusuna karşı <c>similarity</c> ile 0.276 (alakasız satır 0.054),
    /// <c>strict_word_similarity</c> ile 0.500 (alakasız satır 0.118) puan alıyor — yani düz
    /// similarity ile makul hiçbir eşik yazım hatasını gürültüden ayıramıyor.
    /// </para>
    /// <para>
    /// <b>Neden hem operatör hem açık eşik:</b> <c>&lt;&lt;%</c> operatörü index'lenebilir
    /// (PostgreSQL onu <c>normalize(col) %&gt;&gt; q</c> olarak çevirip GIN index'ini kullanır);
    /// açık <c>strict_word_similarity(...) &gt;= eşik</c> ise index'lenemez. İkisi <c>AND</c> ile
    /// birleştirildiğinde ön eleme index'ten gelir, yapılandırılabilir eşik yalnızca recheck
    /// aşamasında daraltır. 50.000 satırla ölçüldü: bu biçim BitmapOr ile ~5 ms, yalnızca açık
    /// eşik kullanan biçim ise Parallel Seq Scan ile ~135 ms.
    /// </para>
    /// </summary>
    public static IQueryable<Item> ApplyTrigramFilter(IQueryable<Item> query, string q, float threshold)
    {
        var term = q.Trim();
        var pattern = EscapeLikePattern(term);

        return query.Where(i =>
            (i.OgTitle != null && (
                EF.Functions.Like(SomineDbFunctions.SearchNormalize(i.OgTitle), "%" + SomineDbFunctions.SearchNormalize(pattern) + "%", LikeEscapeCharacter) ||
                (EF.Functions.TrigramsAreStrictWordSimilar(SomineDbFunctions.SearchNormalize(term), SomineDbFunctions.SearchNormalize(i.OgTitle)) &&
                 EF.Functions.TrigramsStrictWordSimilarity(SomineDbFunctions.SearchNormalize(term), SomineDbFunctions.SearchNormalize(i.OgTitle)) >= threshold))) ||
            (i.Note != null && (
                EF.Functions.Like(SomineDbFunctions.SearchNormalize(i.Note), "%" + SomineDbFunctions.SearchNormalize(pattern) + "%", LikeEscapeCharacter) ||
                (EF.Functions.TrigramsAreStrictWordSimilar(SomineDbFunctions.SearchNormalize(term), SomineDbFunctions.SearchNormalize(i.Note)) &&
                 EF.Functions.TrigramsStrictWordSimilarity(SomineDbFunctions.SearchNormalize(term), SomineDbFunctions.SearchNormalize(i.Note)) >= threshold))) ||
            (i.Url != null && (
                EF.Functions.Like(SomineDbFunctions.SearchNormalize(i.Url), "%" + SomineDbFunctions.SearchNormalize(pattern) + "%", LikeEscapeCharacter) ||
                (EF.Functions.TrigramsAreStrictWordSimilar(SomineDbFunctions.SearchNormalize(term), SomineDbFunctions.SearchNormalize(i.Url)) &&
                 EF.Functions.TrigramsStrictWordSimilarity(SomineDbFunctions.SearchNormalize(term), SomineDbFunctions.SearchNormalize(i.Url)) >= threshold))) ||
            (i.OgDescription != null && (
                EF.Functions.Like(SomineDbFunctions.SearchNormalize(i.OgDescription), "%" + SomineDbFunctions.SearchNormalize(pattern) + "%", LikeEscapeCharacter) ||
                (EF.Functions.TrigramsAreStrictWordSimilar(SomineDbFunctions.SearchNormalize(term), SomineDbFunctions.SearchNormalize(i.OgDescription)) &&
                 EF.Functions.TrigramsStrictWordSimilarity(SomineDbFunctions.SearchNormalize(term), SomineDbFunctions.SearchNormalize(i.OgDescription)) >= threshold))));
    }

    /// <summary>
    /// Alaka düzeyi sıralaması: tam eşleşme &gt; başlangıç eşleşmesi &gt; içerme &gt;
    /// yalnızca trigram benzerliği. Eşitlikte en yüksek sütun benzerliği, o da eşitse
    /// mevcut <c>updated_at</c> sıralaması geçerlidir.
    /// </summary>
    public static IOrderedQueryable<Item> ApplyRelevanceOrder(IQueryable<Item> query, string q)
    {
        var term = q.Trim();
        var pattern = EscapeLikePattern(term);

        return query
            .OrderBy(i =>
                (SomineDbFunctions.SearchNormalize(i.OgTitle!) == SomineDbFunctions.SearchNormalize(term) ||
                 SomineDbFunctions.SearchNormalize(i.Note!) == SomineDbFunctions.SearchNormalize(term) ||
                 SomineDbFunctions.SearchNormalize(i.Url!) == SomineDbFunctions.SearchNormalize(term))
                    ? 0
                : (EF.Functions.Like(SomineDbFunctions.SearchNormalize(i.OgTitle!), SomineDbFunctions.SearchNormalize(pattern) + "%", LikeEscapeCharacter) ||
                   EF.Functions.Like(SomineDbFunctions.SearchNormalize(i.Note!), SomineDbFunctions.SearchNormalize(pattern) + "%", LikeEscapeCharacter) ||
                   EF.Functions.Like(SomineDbFunctions.SearchNormalize(i.Url!), SomineDbFunctions.SearchNormalize(pattern) + "%", LikeEscapeCharacter))
                    ? 1
                : (EF.Functions.Like(SomineDbFunctions.SearchNormalize(i.OgTitle!), "%" + SomineDbFunctions.SearchNormalize(pattern) + "%", LikeEscapeCharacter) ||
                   EF.Functions.Like(SomineDbFunctions.SearchNormalize(i.Note!), "%" + SomineDbFunctions.SearchNormalize(pattern) + "%", LikeEscapeCharacter) ||
                   EF.Functions.Like(SomineDbFunctions.SearchNormalize(i.Url!), "%" + SomineDbFunctions.SearchNormalize(pattern) + "%", LikeEscapeCharacter) ||
                   EF.Functions.Like(SomineDbFunctions.SearchNormalize(i.OgDescription!), "%" + SomineDbFunctions.SearchNormalize(pattern) + "%", LikeEscapeCharacter))
                    ? 2
                : 3)
            .ThenByDescending(i => Math.Max(
                Math.Max(
                    EF.Functions.TrigramsStrictWordSimilarity(SomineDbFunctions.SearchNormalize(term), SomineDbFunctions.SearchNormalize(i.OgTitle!)),
                    EF.Functions.TrigramsStrictWordSimilarity(SomineDbFunctions.SearchNormalize(term), SomineDbFunctions.SearchNormalize(i.Note!))),
                Math.Max(
                    EF.Functions.TrigramsStrictWordSimilarity(SomineDbFunctions.SearchNormalize(term), SomineDbFunctions.SearchNormalize(i.Url!)),
                    EF.Functions.TrigramsStrictWordSimilarity(SomineDbFunctions.SearchNormalize(term), SomineDbFunctions.SearchNormalize(i.OgDescription!)))))
            .ThenByDescending(i => i.UpdatedAt);
    }
}
