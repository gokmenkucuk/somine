using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using SomineApi.Tests.Testing;

namespace SomineApi.Tests.Integration;

/// <summary>
/// Testler SQLite in-memory üzerinde koşar ve orada pg_trgm YOKTUR.
/// Bu testler, sağlayıcı kontrolünün gerçekten çalıştığını — yani trigram yolunun
/// devreye girmediğini ve eski LIKE davranışının aynen korunduğunu — doğrular.
/// </summary>
public class TrigramSearchFallbackTests
{
    [Fact]
    public void Sqlite_UsesSqliteProvider_SoTrigramPathIsNeverSelected()
    {
        using var factory = new SomineApiWebApplicationFactory();
        using var scope = factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();

        Assert.False(dbContext.Database.IsNpgsql());
        Assert.Equal("Microsoft.EntityFrameworkCore.Sqlite", dbContext.Database.ProviderName);
    }

    [Fact]
    public async Task SearchItems_OnSqlite_TypoDoesNotMatch_ProvingTrigramIsInactive()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("trgm-fallback-typo");
        await SeedAsync(factory.Services, db =>
        {
            db.Users.Add(user);
            db.Items.Add(TestItem(user.Id, note: "alpha recipe for pasta"));
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        // "alpah" yazım hatası PostgreSQL'de trigram ile eşleşirdi; SQLite'ta eşleşmemeli.
        var typo = await client.GetAsync("/api/items/search?q=alpah");
        Assert.Equal(HttpStatusCode.OK, typo.StatusCode);
        var typoBody = await typo.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(0, typoBody.GetProperty("totalCount").GetInt32());

        // Tam alt dize ise eskisi gibi eşleşmeye devam etmeli.
        var exact = await client.GetAsync("/api/items/search?q=alpha");
        var exactBody = await exact.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, exactBody.GetProperty("totalCount").GetInt32());
    }

    [Fact]
    public async Task SearchItems_ShortQuery_FallsBackToSubstringMatching()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("trgm-fallback-short");
        await SeedAsync(factory.Services, db =>
        {
            db.Users.Add(user);
            db.Items.AddRange(
                TestItem(user.Id, note: "alpha recipe"),
                TestItem(user.Id, note: "beta workout"));
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        // 2 karakter: trigram anlamsız, LIKE '%al%' davranışı.
        var response = await client.GetAsync("/api/items/search?q=al");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, body.GetProperty("totalCount").GetInt32());
        Assert.Equal("alpha recipe", body.GetProperty("items")[0].GetProperty("note").GetString());
    }

    [Fact]
    public async Task SearchItems_PreservesPagedResultContract()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("trgm-contract");
        await SeedAsync(factory.Services, db =>
        {
            db.Users.Add(user);
            for (var index = 0; index < 3; index++)
            {
                db.Items.Add(TestItem(user.Id, note: $"kahvaltilik urun {index}"));
            }
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var response = await client.GetAsync("/api/items/search?q=kahvaltilik&page=2&limit=2");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(3, body.GetProperty("totalCount").GetInt32());
        Assert.Equal(2, body.GetProperty("page").GetInt32());
        Assert.Equal(2, body.GetProperty("limit").GetInt32());
        Assert.Equal(1, body.GetProperty("items").GetArrayLength());
    }

    private static async Task SeedAsync(IServiceProvider services, Action<SomineDbContext> seed)
    {
        using var scope = services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        seed(dbContext);
        await dbContext.SaveChangesAsync();
    }

    private static User TestUser(string key) => new()
    {
        Id = Guid.NewGuid(),
        FirebaseUid = $"firebase-{key}",
        Email = $"{key}@somine.test",
        DisplayName = key,
        Username = key.Replace("-", "", StringComparison.Ordinal),
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private static Item TestItem(Guid userId, string note) => new()
    {
        Id = Guid.NewGuid(),
        UserId = userId,
        Type = ItemType.Link,
        Url = $"https://example.com/{Guid.NewGuid():N}",
        Note = note,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };
}
