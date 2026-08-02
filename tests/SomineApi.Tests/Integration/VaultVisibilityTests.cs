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
/// Kasa (vault) item'ları listeleme/arama uçlarında varsayılan olarak dönmez;
/// yalnızca `includeVault=true` ile açıkça istendiğinde döner.
/// Bu bir güvenlik sınırı değil, savunma katmanıdır (bkz. ItemsController.ApplyVaultVisibility).
/// Bozulmaması gerekenler de burada kilitlenir: kota sayacı ve kategori listesi.
/// </summary>
public class VaultVisibilityTests
{
    [Fact]
    public async Task GetItems_ExcludesVaultByDefaultAndReturnsItWithIncludeVault()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var fixture = await SeedVaultFixtureAsync(factory);
        using var client = factory.CreateAuthenticatedClient(fixture.User.Id, fixture.User.Email!, fixture.User.FirebaseUid);

        var defaultNotes = await GetPagedNotesAsync(client, "/api/items?page=1&limit=50");
        Assert.Contains("normal-item", defaultNotes);
        Assert.Contains("uncategorized-item", defaultNotes);
        Assert.DoesNotContain("vault-item", defaultNotes);

        var explicitNotes = await GetPagedNotesAsync(client, "/api/items?page=1&limit=50&includeVault=true");
        Assert.Contains("normal-item", explicitNotes);
        Assert.Contains("uncategorized-item", explicitNotes);
        Assert.Contains("vault-item", explicitNotes);
    }

    [Fact]
    public async Task GetItems_ByVaultCategoryIdReturnsNothingUnlessIncludeVaultRequested()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var fixture = await SeedVaultFixtureAsync(factory);
        using var client = factory.CreateAuthenticatedClient(fixture.User.Id, fixture.User.Email!, fixture.User.FirebaseUid);

        var defaultNotes = await GetPagedNotesAsync(client, $"/api/items?categoryId={fixture.VaultCategory.Id}&page=1&limit=50");
        Assert.Empty(defaultNotes);

        var explicitNotes = await GetPagedNotesAsync(client, $"/api/items?categoryId={fixture.VaultCategory.Id}&page=1&limit=50&includeVault=true");
        Assert.Equal(["favorite-vault-item", "vault-item"], explicitNotes.Order().ToArray());
    }

    [Fact]
    public async Task SearchItems_ExcludesVaultByDefaultAndReturnsItWithIncludeVault()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var fixture = await SeedVaultFixtureAsync(factory);
        using var client = factory.CreateAuthenticatedClient(fixture.User.Id, fixture.User.Email!, fixture.User.FirebaseUid);

        var defaultNotes = await GetPagedNotesAsync(client, "/api/items/search?q=item&page=1&limit=50");
        Assert.Contains("normal-item", defaultNotes);
        Assert.DoesNotContain("vault-item", defaultNotes);

        var explicitNotes = await GetPagedNotesAsync(client, "/api/items/search?q=item&page=1&limit=50&includeVault=true");
        Assert.Contains("vault-item", explicitNotes);
    }

    [Fact]
    public async Task GetFavorites_ExcludesVaultByDefaultAndReturnsItWithIncludeVault()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var fixture = await SeedVaultFixtureAsync(factory);
        using var client = factory.CreateAuthenticatedClient(fixture.User.Id, fixture.User.Email!, fixture.User.FirebaseUid);

        var defaultNotes = await GetListNotesAsync(client, "/api/items/favorites");
        Assert.Equal(["favorite-normal-item"], defaultNotes.Order().ToArray());

        var explicitNotes = await GetListNotesAsync(client, "/api/items/favorites?includeVault=true");
        Assert.Equal(["favorite-normal-item", "favorite-vault-item"], explicitNotes.Order().ToArray());
    }

    [Fact]
    public async Task GetDeletedItems_ExcludesVaultByDefaultAndReturnsItWithIncludeVault()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var fixture = await SeedVaultFixtureAsync(factory);
        using var client = factory.CreateAuthenticatedClient(fixture.User.Id, fixture.User.Email!, fixture.User.FirebaseUid);

        var defaultNotes = await GetListNotesAsync(client, "/api/items/deleted");
        Assert.Equal(["deleted-normal-item"], defaultNotes.Order().ToArray());

        var explicitNotes = await GetListNotesAsync(client, "/api/items/deleted?includeVault=true");
        Assert.Equal(["deleted-normal-item", "deleted-vault-item"], explicitNotes.Order().ToArray());
    }

    [Fact]
    public async Task GetItemCount_StillCountsVaultItems()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var fixture = await SeedVaultFixtureAsync(factory);
        using var client = factory.CreateAuthenticatedClient(fixture.User.Id, fixture.User.Email!, fixture.User.FirebaseUid);

        var response = await client.GetAsync("/api/items/count");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        // Silinmemiş item'lar: normal, uncategorized, vault, favorite-normal, favorite-vault = 5
        Assert.Equal(5, document.RootElement.GetProperty("total").GetInt32());
    }

    [Fact]
    public async Task CreateItem_FreeLimitStillCountsVaultItems()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        factory.SubscriptionTierService.DefaultIsPremium = false;

        var user = TestUser("vault-quota-owner");
        var vaultCategory = TestCategory(user.Id, "Gizli Kasa", isVault: true);

        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Categories.Add(vaultCategory);
            // Limitin bir altına kadar SADECE vault item'ı ile doldur: kota vault'u saymazsa
            // aşağıdaki ikinci create isteği 403 yerine 201 dönerdi.
            db.Items.AddRange(Enumerable
                .Range(0, SomineApi.Application.SubscriptionLimits.FreeMaxItems - 1)
                .Select(index => TestItem(user.Id, $"vault-seed-{index}", vaultCategory.Id)));
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var allowed = await client.PostAsJsonAsync("/api/items", new
        {
            url = "https://example.com/allowed",
            note = "allowed",
            type = ItemType.Link
        });
        Assert.Equal(HttpStatusCode.Created, allowed.StatusCode);

        var blocked = await client.PostAsJsonAsync("/api/items", new
        {
            url = "https://example.com/blocked",
            note = "blocked",
            type = ItemType.Link
        });
        Assert.Equal(HttpStatusCode.Forbidden, blocked.StatusCode);
    }

    [Fact]
    public async Task GetCategories_StillReturnsVaultCategories()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var fixture = await SeedVaultFixtureAsync(factory);
        using var client = factory.CreateAuthenticatedClient(fixture.User.Id, fixture.User.Email!, fixture.User.FirebaseUid);

        var response = await client.GetAsync("/api/categories");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var vault = document.RootElement
            .EnumerateArray()
            .Single(c => c.GetProperty("id").GetGuid() == fixture.VaultCategory.Id);

        Assert.True(vault.GetProperty("isVault").GetBoolean());
    }

    [Fact]
    public async Task Export_StillIncludesVaultItems()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var fixture = await SeedVaultFixtureAsync(factory);
        using var client = factory.CreateAuthenticatedClient(fixture.User.Id, fixture.User.Email!, fixture.User.FirebaseUid);

        var response = await client.GetAsync("/api/export?format=json");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadAsStringAsync();
        // Export kullanıcının bilinçli, kimlik doğrulamalı kendi verisi talebidir — vault dahil kalır.
        Assert.Contains("vault-item", body, StringComparison.Ordinal);
    }

    private static async Task<string[]> GetPagedNotesAsync(HttpClient client, string url)
    {
        var response = await client.GetAsync(url);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return document.RootElement
            .GetProperty("items")
            .EnumerateArray()
            .Select(item => item.GetProperty("note").GetString()!)
            .ToArray();
    }

    private static async Task<string[]> GetListNotesAsync(HttpClient client, string url)
    {
        var response = await client.GetAsync(url);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return document.RootElement
            .EnumerateArray()
            .Select(item => item.GetProperty("note").GetString()!)
            .ToArray();
    }

    private static async Task<VaultFixture> SeedVaultFixtureAsync(SomineApiWebApplicationFactory factory)
    {
        var user = TestUser("vault-owner");
        var normalCategory = TestCategory(user.Id, "Normal", isVault: false);
        var vaultCategory = TestCategory(user.Id, "Gizli Kasa", isVault: true);

        var favoriteNormal = TestItem(user.Id, "favorite-normal-item", normalCategory.Id);
        favoriteNormal.IsFavorite = true;
        var favoriteVault = TestItem(user.Id, "favorite-vault-item", vaultCategory.Id);
        favoriteVault.IsFavorite = true;

        var deletedNormal = TestItem(user.Id, "deleted-normal-item", normalCategory.Id);
        deletedNormal.IsDeleted = true;
        deletedNormal.DeletedAt = DateTime.UtcNow;
        var deletedVault = TestItem(user.Id, "deleted-vault-item", vaultCategory.Id);
        deletedVault.IsDeleted = true;
        deletedVault.DeletedAt = DateTime.UtcNow;

        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Categories.AddRange(normalCategory, vaultCategory);
            db.Items.AddRange(
                TestItem(user.Id, "normal-item", normalCategory.Id),
                TestItem(user.Id, "vault-item", vaultCategory.Id),
                TestItem(user.Id, "uncategorized-item"),
                favoriteNormal,
                favoriteVault,
                deletedNormal,
                deletedVault);
        });

        return new VaultFixture(user, normalCategory, vaultCategory);
    }

    private static async Task SeedAsync(SomineApiWebApplicationFactory factory, Action<SomineDbContext> seed)
    {
        using var scope = factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        seed(dbContext);
        await dbContext.SaveChangesAsync();
    }

    private static User TestUser(string key)
    {
        return new User
        {
            Id = Guid.NewGuid(),
            FirebaseUid = $"firebase-{key}",
            Email = $"{key}@somine.test",
            DisplayName = key,
            Username = key.Replace("-", "", StringComparison.Ordinal),
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    private static Category TestCategory(Guid userId, string name, bool isVault)
    {
        return new Category
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Name = name,
            IsVault = isVault,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    private static Item TestItem(Guid userId, string note, Guid? categoryId = null)
    {
        return new Item
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CategoryId = categoryId,
            Type = ItemType.Link,
            Url = $"https://example.com/{note}",
            Note = note,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    private sealed record VaultFixture(User User, Category NormalCategory, Category VaultCategory);
}
