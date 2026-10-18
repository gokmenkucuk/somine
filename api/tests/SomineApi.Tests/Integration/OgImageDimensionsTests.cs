using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using SomineApi.Tests.Testing;
using Microsoft.Extensions.DependencyInjection;

namespace SomineApi.Tests.Integration;

// OG görselinin piksel boyutları: istemci ölçer, sunucu YALNIZCA saklar.
// Amaç, taze bir cihazda ilk render'da en-boy oranının bilinmesi (masonry zıplaması yok).
public class OgImageDimensionsTests
{
    [Fact]
    public async Task CreateItem_WithOgImageDimensions_RoundTripsThroughGet()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("og-dims-owner");
        await SeedAsync(factory, db => db.Users.Add(user));

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var createResponse = await client.PostAsJsonAsync("/api/items", new
        {
            url = "https://example.com/with-dims",
            note = "with dims",
            type = ItemType.Link,
            ogImageUrl = "https://cdn.example.com/preview.jpg",
            ogImageWidth = 1200,
            ogImageHeight = 630
        });

        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);
        var created = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1200, created.GetProperty("ogImageWidth").GetInt32());
        Assert.Equal(630, created.GetProperty("ogImageHeight").GetInt32());

        var itemId = created.GetProperty("id").GetGuid();
        var getResponse = await client.GetAsync($"/api/items/{itemId}");
        Assert.Equal(HttpStatusCode.OK, getResponse.StatusCode);

        var fetched = await getResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1200, fetched.GetProperty("ogImageWidth").GetInt32());
        Assert.Equal(630, fetched.GetProperty("ogImageHeight").GetInt32());
    }

    [Fact]
    public async Task CreateItem_WithoutOgImageDimensions_LeavesThemNull()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("og-dims-absent");
        await SeedAsync(factory, db => db.Users.Add(user));

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        // Boyutları hiç göndermeyen eski istemci — alanlar null kalmalı, hata olmamalı.
        var createResponse = await client.PostAsJsonAsync("/api/items", new
        {
            url = "https://example.com/no-dims",
            note = "no dims",
            type = ItemType.Link
        });

        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);
        var created = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        var itemId = created.GetProperty("id").GetGuid();

        var fetched = await (await client.GetAsync($"/api/items/{itemId}")).Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(JsonValueKind.Null, fetched.GetProperty("ogImageWidth").ValueKind);
        Assert.Equal(JsonValueKind.Null, fetched.GetProperty("ogImageHeight").ValueKind);
    }

    [Fact]
    public async Task UpdateItem_SetsOgImageDimensionsOnAnExistingItem()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("og-dims-update");
        var item = TestItem(user.Id, "legacy-item");
        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(item);
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var updateResponse = await client.PutAsJsonAsync($"/api/items/{item.Id}", new
        {
            ogImageWidth = 800,
            ogImageHeight = 1000
        });

        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
        var updated = await updateResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(800, updated.GetProperty("ogImageWidth").GetInt32());
        Assert.Equal(1000, updated.GetProperty("ogImageHeight").GetInt32());

        using var scope = factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        var stored = await dbContext.Items.FindAsync(item.Id);
        Assert.NotNull(stored);
        Assert.Equal(800, stored!.OgImageWidth);
        Assert.Equal(1000, stored.OgImageHeight);
    }

    [Fact]
    public async Task CreateAndUpdate_WithAbsurdDimensions_StoresNullInsteadOfFailing()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("og-dims-absurd");
        await SeedAsync(factory, db => db.Users.Add(user));

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        // Hatalı istemci: negatif genişlik + absürt yükseklik. 400 DEĞİL, sessizce null.
        var createResponse = await client.PostAsJsonAsync("/api/items", new
        {
            url = "https://example.com/absurd",
            note = "absurd dims",
            type = ItemType.Link,
            ogImageWidth = -5,
            ogImageHeight = 999999
        });

        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);
        var created = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(JsonValueKind.Null, created.GetProperty("ogImageWidth").ValueKind);
        Assert.Equal(JsonValueKind.Null, created.GetProperty("ogImageHeight").ValueKind);

        var itemId = created.GetProperty("id").GetGuid();

        var updateResponse = await client.PutAsJsonAsync($"/api/items/{itemId}", new
        {
            ogImageWidth = 0,
            ogImageHeight = 20001
        });

        Assert.Equal(HttpStatusCode.OK, updateResponse.StatusCode);
        var updated = await updateResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(JsonValueKind.Null, updated.GetProperty("ogImageWidth").ValueKind);
        Assert.Equal(JsonValueKind.Null, updated.GetProperty("ogImageHeight").ValueKind);
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

    private static Item TestItem(Guid userId, string note)
    {
        return new Item
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Type = ItemType.Link,
            Url = $"https://example.com/{note}",
            Note = note,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }
}
