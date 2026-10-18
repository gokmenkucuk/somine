namespace SomineApi.Infrastructure.Data;

/// <summary>
/// PostgreSQL tarafında tanımlı yardımcı fonksiyonların EF Core eşlemeleri.
/// Gövdeler yalnızca LINQ ağacında yer tutucudur; hiçbir zaman istemcide çalışmaz.
/// </summary>
public static class SomineDbFunctions
{
    /// <summary>PostgreSQL'deki IMMUTABLE sarmalayıcının adı.</summary>
    public const string SearchNormalizeFunctionName = "somine_search_normalize";

    /// <summary>
    /// <c>unaccent('public.unaccent'::regdictionary, lower(value))</c> karşılığı.
    /// Hem trigram GIN index ifadesi hem de sorgu tarafı bu fonksiyonu kullanır;
    /// böylece index ile sorgu ifadesi birebir eşleşir.
    /// </summary>
    public static string SearchNormalize(string value)
        => throw new InvalidOperationException(
            $"{nameof(SearchNormalize)} yalnızca EF Core sorgularında (PostgreSQL) kullanılabilir.");
}
