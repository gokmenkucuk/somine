using Microsoft.EntityFrameworkCore;
using Microsoft.Data.Sqlite;
using Pgvector.EntityFrameworkCore;
using SomineApi.Infrastructure.Data;
using SomineApi.Infrastructure.Options;

namespace SomineApi.Tests;

/// <summary>
/// Trigram arama yolunun ÜRETTİĞİ SQL'i canlı veritabanı olmadan doğrular.
/// <c>ToQueryString()</c> bağlantı açmadığı için Npgsql çevirisi burada test edilebilir;
/// aksi halde pg_trgm yolu hiçbir testte derleme ötesinde doğrulanamazdı.
/// </summary>
public class TrigramSearchQueryTests
{
    private const string FakeNpgsqlConnectionString =
        "Host=localhost;Port=5432;Database=somine_sql_shape;Username=somine;Password=somine";

    [Fact]
    public void ShouldUseTrigram_IsDisabledForSqliteShortQueriesAndDisabledOption()
    {
        var options = new SearchOptions();

        // SQLite (testler) — trigram asla devreye girmez.
        Assert.False(ItemSearchQuery.ShouldUseTrigram(isNpgsql: false, trigramEnabled: true, "alpha", options.EffectiveMinQueryLength));

        // 1-2 karakterlik sorgular — trigram anlamsız, LIKE'a düşülür.
        Assert.False(ItemSearchQuery.ShouldUseTrigram(isNpgsql: true, trigramEnabled: true, "a", options.EffectiveMinQueryLength));
        Assert.False(ItemSearchQuery.ShouldUseTrigram(isNpgsql: true, trigramEnabled: true, "ab", options.EffectiveMinQueryLength));
        Assert.False(ItemSearchQuery.ShouldUseTrigram(isNpgsql: true, trigramEnabled: true, "  ab  ", options.EffectiveMinQueryLength));

        // Kapatma anahtarı.
        Assert.False(ItemSearchQuery.ShouldUseTrigram(isNpgsql: true, trigramEnabled: false, "alpha", options.EffectiveMinQueryLength));

        // Boş sorgu.
        Assert.False(ItemSearchQuery.ShouldUseTrigram(isNpgsql: true, trigramEnabled: true, "   ", options.EffectiveMinQueryLength));

        // PostgreSQL + 3+ karakter — trigram yolu.
        Assert.True(ItemSearchQuery.ShouldUseTrigram(isNpgsql: true, trigramEnabled: true, "alp", options.EffectiveMinQueryLength));
    }

    [Fact]
    public void SearchOptions_ClampsOutOfRangeConfiguration()
    {
        var defaults = new SearchOptions();
        Assert.Equal(0.5f, defaults.EffectiveThreshold);
        Assert.Equal(3, defaults.EffectiveMinQueryLength);

        var extreme = new SearchOptions { TrigramSimilarityThreshold = -5f, MinTrigramQueryLength = 1 };
        Assert.Equal(0.05f, extreme.EffectiveThreshold);
        Assert.Equal(3, extreme.EffectiveMinQueryLength);

        var tooHigh = new SearchOptions { TrigramSimilarityThreshold = 42f };
        Assert.Equal(1.0f, tooHigh.EffectiveThreshold);
    }

    [Fact]
    public void EscapeLikePattern_NeutralisesWildcards()
    {
        Assert.Equal("50\\%", ItemSearchQuery.EscapeLikePattern("50%"));
        Assert.Equal("a\\_b", ItemSearchQuery.EscapeLikePattern("a_b"));
        Assert.Equal("c\\\\d", ItemSearchQuery.EscapeLikePattern("c\\d"));
    }

    [Fact]
    public void TrigramFilterAndOrder_TranslateToPgTrgmSqlOnNpgsql()
    {
        using var context = CreateNpgsqlContext();

        var filtered = ItemSearchQuery.ApplyTrigramFilter(context.Items, "kahvalti", 0.5f);
        var sql = ItemSearchQuery.ApplyRelevanceOrder(filtered, "kahvalti").ToQueryString();

        // Index ifadesiyle birebir aynı normalize sarmalayıcısı kullanılmalı.
        Assert.Contains("somine_search_normalize", sql, StringComparison.Ordinal);
        // Yazım hatası toleransı: index'lenebilir <<% operatörü + eşiği uygulayan strict_word_similarity().
        Assert.Contains("strict_word_similarity(", sql, StringComparison.Ordinal);
        Assert.Contains(" <<% ", sql, StringComparison.Ordinal);
        // Kısmi eşleşme: LIKE (GIN trigram index'i tarafından hızlandırılabilir).
        Assert.Contains("LIKE", sql, StringComparison.Ordinal);
        // Alaka sıralaması + mevcut updated_at eşitlik kuralı.
        Assert.Contains("ORDER BY", sql, StringComparison.Ordinal);
        Assert.Contains("updated_at", sql, StringComparison.Ordinal);
        // Dört aranabilir sütunun tamamı kapsanmalı.
        foreach (var column in new[] { "og_title", "note", "url", "og_description" })
        {
            Assert.Contains(column, sql, StringComparison.Ordinal);
        }
    }

    [Fact]
    public void LikeFallback_DoesNotEmitTrigramSqlOnNpgsql()
    {
        using var context = CreateNpgsqlContext();

        var sql = ItemSearchQuery.ApplyLikeFilter(context.Items, "ab").ToQueryString();

        Assert.DoesNotContain("similarity(", sql, StringComparison.Ordinal);
        Assert.DoesNotContain("somine_search_normalize", sql, StringComparison.Ordinal);
    }

    [Fact]
    public void SqliteKeywordSearch_UsesPlainLikeWithoutTrigramFunctions()
    {
        using var connection = new SqliteConnection("DataSource=:memory:");
        connection.Open();

        var options = new DbContextOptionsBuilder<SomineDbContext>()
            .UseSqlite(connection)
            .Options;

        using var context = new SomineDbContext(options);

        var sql = ItemSearchQuery.ApplyLikeFilter(context.Items, "alpha")
            .OrderByDescending(i => i.UpdatedAt)
            .ToQueryString();

        Assert.DoesNotContain("somine_search_normalize", sql, StringComparison.Ordinal);
        Assert.DoesNotContain("similarity", sql, StringComparison.OrdinalIgnoreCase);
        Assert.DoesNotContain("unaccent", sql, StringComparison.OrdinalIgnoreCase);
    }

    private static SomineDbContext CreateNpgsqlContext()
    {
        var options = new DbContextOptionsBuilder<SomineDbContext>()
            .UseNpgsql(FakeNpgsqlConnectionString, npgsql => npgsql.UseVector())
            .Options;

        return new SomineDbContext(options);
    }
}
