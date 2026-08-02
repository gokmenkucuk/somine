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

// Alıcısız ("link ile paylaş") koleksiyon linki: POST/DELETE /api/categories/{id}/public-link
public class CategoryPublicLinkTests
{
    [Fact]
    public async Task CreateCategoryPublicLink_IsIdempotentAndRevocable()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("cat-link-owner");
        var category = TestCategory(owner.Id, "Link ile paylaşılan");

        await SeedAsync(factory, db =>
        {
            db.Users.Add(owner);
            db.Categories.Add(category);
        });

        using var client = factory.CreateAuthenticatedClient(owner.Id, owner.Email!, owner.FirebaseUid);

        var createResponse = await client.PostAsync($"/api/categories/{category.Id}/public-link", null);
        Assert.Equal(HttpStatusCode.OK, createResponse.StatusCode);
        var created = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        var token1 = created.GetProperty("token").GetString();
        Assert.False(string.IsNullOrWhiteSpace(token1));
        Assert.EndsWith($"/s/{token1}", created.GetProperty("url").GetString());

        // Idempotency — ikinci POST AYNI token'ı döndürmeli (share ucundaki rotate davranışının aksine)
        var secondResponse = await client.PostAsync($"/api/categories/{category.Id}/public-link", null);
        Assert.Equal(HttpStatusCode.OK, secondResponse.StatusCode);
        var second = await secondResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(token1, second.GetProperty("token").GetString());

        // İptal → 204 ve token temizlenir
        var deleteResponse = await client.DeleteAsync($"/api/categories/{category.Id}/public-link");
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        var stored = await db.Categories.FirstAsync(c => c.Id == category.Id);
        Assert.Null(stored.PublicLinkToken);
        Assert.Null(stored.PublicLinkCreatedAtUtc);
    }

    [Fact]
    public async Task CreateCategoryPublicLink_NonOwnerReturnsNotFound()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("cat-link-owner2");
        var stranger = TestUser("cat-link-stranger");
        var category = TestCategory(owner.Id, "Başkasının koleksiyonu");

        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(owner, stranger);
            db.Categories.Add(category);
        });

        using var strangerClient = factory.CreateAuthenticatedClient(stranger.Id, stranger.Email!, stranger.FirebaseUid);

        var createResponse = await strangerClient.PostAsync($"/api/categories/{category.Id}/public-link", null);
        Assert.Equal(HttpStatusCode.NotFound, createResponse.StatusCode);

        var deleteResponse = await strangerClient.DeleteAsync($"/api/categories/{category.Id}/public-link");
        Assert.Equal(HttpStatusCode.NotFound, deleteResponse.StatusCode);
    }

    [Fact]
    public async Task CreateCategoryPublicLink_VaultCategoryReturnsBadRequest()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("cat-vault-owner");
        var category = TestCategory(owner.Id, "Gizli kasa");
        category.IsVault = true;

        await SeedAsync(factory, db =>
        {
            db.Users.Add(owner);
            db.Categories.Add(category);
        });

        using var client = factory.CreateAuthenticatedClient(owner.Id, owner.Email!, owner.FirebaseUid);
        var response = await client.PostAsync($"/api/categories/{category.Id}/public-link", null);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        var stored = await db.Categories.FirstAsync(c => c.Id == category.Id);
        Assert.Null(stored.PublicLinkToken);
    }

    [Fact]
    public async Task CategoryPublicLinkToken_IsReturnedToOwnerOnly()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("token-owner");
        var stranger = TestUser("token-stranger");
        var category = TestCategory(owner.Id, "Token sahibi koleksiyon");

        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(owner, stranger);
            db.Categories.Add(category);
        });

        using var ownerClient = factory.CreateAuthenticatedClient(owner.Id, owner.Email!, owner.FirebaseUid);
        using var strangerClient = factory.CreateAuthenticatedClient(stranger.Id, stranger.Email!, stranger.FirebaseUid);

        var createResponse = await ownerClient.PostAsync($"/api/categories/{category.Id}/public-link", null);
        var created = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        var token = created.GetProperty("token").GetString()!;

        // Sahibi kendi listesinde token'ı görür
        var ownerList = await ownerClient.GetFromJsonAsync<JsonElement>("/api/categories");
        var ownerCategory = ownerList.EnumerateArray().Single(c => c.GetProperty("id").GetGuid() == category.Id);
        Assert.Equal(token, ownerCategory.GetProperty("publicLinkToken").GetString());

        // Başkasının listesinde token hiçbir yerde geçmez
        var strangerList = await strangerClient.GetAsync("/api/categories");
        var strangerBody = await strangerList.Content.ReadAsStringAsync();
        Assert.DoesNotContain(token, strangerBody, StringComparison.Ordinal);
    }

    [Fact]
    public async Task GetPublicShare_ResolvesCategoryOnlyLinkWithoutAnyShareRow()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("standalone-owner");
        owner.DisplayName = "Grace Hopper";
        var category = TestCategory(owner.Id, "Bağımsız koleksiyon");

        await SeedAsync(factory, db =>
        {
            db.Users.Add(owner);
            db.Categories.Add(category);
            db.Items.AddRange(
                TestItem(owner.Id, "alpha", category.Id),
                TestItem(owner.Id, "beta", category.Id));
        });

        using var ownerClient = factory.CreateAuthenticatedClient(owner.Id, owner.Email!, owner.FirebaseUid);
        var createResponse = await ownerClient.PostAsync($"/api/categories/{category.Id}/public-link", null);
        var created = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        var token = created.GetProperty("token").GetString()!;

        // Hiçbir CollectionShare satırı olmadan public sayfa çalışmalı
        using var anonymousClient = factory.CreateClient();
        var response = await anonymousClient.GetAsync($"/public/shares/{token}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Bağımsız koleksiyon", body.GetProperty("categoryName").GetString());
        Assert.Equal("Grace Hopper", body.GetProperty("fromUserName").GetString());
        Assert.Equal(2, body.GetProperty("items").GetArrayLength());
        Assert.DoesNotContain("userId", body.GetRawText(), StringComparison.OrdinalIgnoreCase);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        Assert.False(await db.CollectionShares.AnyAsync());

        // İptal sonrası nötr 404
        var deleteResponse = await ownerClient.DeleteAsync($"/api/categories/{category.Id}/public-link");
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        var revokedResponse = await anonymousClient.GetAsync($"/public/shares/{token}");
        Assert.Equal(HttpStatusCode.NotFound, revokedResponse.StatusCode);
    }

    [Fact]
    public async Task MarkingCategoryAsVault_RevokesExistingPublicLink()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("vault-flip-owner");
        var category = TestCategory(owner.Id, "Sonradan kasaya alınan");

        await SeedAsync(factory, db =>
        {
            db.Users.Add(owner);
            db.Categories.Add(category);
        });

        using var client = factory.CreateAuthenticatedClient(owner.Id, owner.Email!, owner.FirebaseUid);
        var createResponse = await client.PostAsync($"/api/categories/{category.Id}/public-link", null);
        var created = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        var token = created.GetProperty("token").GetString()!;

        var updateResponse = await client.PutAsJsonAsync($"/api/categories/{category.Id}",
            new { name = (string?)null, icon = (string?)null, color = (string?)null, isVault = true });
        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);

        var updated = await updateResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(updated.GetProperty("isVault").GetBoolean());
        Assert.Null(updated.GetProperty("publicLinkToken").GetString());

        using var anonymousClient = factory.CreateClient();
        var publicResponse = await anonymousClient.GetAsync($"/public/shares/{token}");
        Assert.Equal(HttpStatusCode.NotFound, publicResponse.StatusCode);
    }

    private static async Task SeedAsync(SomineApiWebApplicationFactory factory, Action<SomineDbContext> seed)
    {
        using var scope = factory.Services.CreateScope();
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

    private static Category TestCategory(Guid userId, string name) => new()
    {
        Id = Guid.NewGuid(),
        UserId = userId,
        Name = name,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private static Item TestItem(Guid userId, string note, Guid categoryId) => new()
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
