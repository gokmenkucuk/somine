using System.Net;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using SomineApi.Tests.Testing;

namespace SomineApi.Tests.Integration;

public class ExportControllerTests
{
    [Fact]
    public async Task ExportJson_ReturnsUsersNonDeletedItemsAndCategories()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("export-json-owner");
        var category = TestCategory(user.Id, "Tarifler");

        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Categories.Add(category);
            db.Items.AddRange(
                TestItem(user.Id, "first", category.Id),
                TestItem(user.Id, "second"),
                TestItem(user.Id, "deleted", category.Id, isDeleted: true));
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var response = await client.GetAsync("/api/export?format=json");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.StartsWith("application/json", response.Content.Headers.ContentType?.ToString());

        var payload = await response.Content.ReadAsStringAsync();
        using var document = JsonDocument.Parse(payload);
        var root = document.RootElement;

        Assert.True(root.TryGetProperty("exportedAt", out _));
        Assert.Equal(user.Email, root.GetProperty("user").GetProperty("email").GetString());

        var categories = root.GetProperty("categories").EnumerateArray().ToList();
        Assert.Single(categories);
        Assert.Equal("Tarifler", categories[0].GetProperty("name").GetString());

        var items = root.GetProperty("items").EnumerateArray().ToList();
        Assert.Equal(2, items.Count);
        Assert.DoesNotContain(items, i => i.GetProperty("note").GetString() == "deleted");

        var categorized = Assert.Single(items, i => i.GetProperty("note").GetString() == "first");
        Assert.Equal("Tarifler", categorized.GetProperty("categoryName").GetString());
        Assert.Equal("Link", categorized.GetProperty("type").GetString());
    }

    [Fact]
    public async Task ExportCsv_ReturnsHeaderRowAndEscapesSpecialCharacters()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("export-csv-owner");
        var trickyItem = TestItem(user.Id, "plain");
        trickyItem.Note = "virgül, içeren \"tırnaklı\" not";
        trickyItem.OgTitle = "satır\nsonu";

        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(trickyItem);
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var response = await client.GetAsync("/api/export?format=csv");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.StartsWith("text/csv", response.Content.Headers.ContentType?.ToString());

        var payload = await response.Content.ReadAsStringAsync();

        Assert.StartsWith("Id,Type,Url,Note,OgTitle,OgDescription,Category,IsFavorite,CreatedAt,LastOpenedAt", payload);
        // RFC 4180: virgüllü/tırnaklı alan tırnaklanır, iç tırnaklar ikilenir.
        Assert.Contains("\"virgül, içeren \"\"tırnaklı\"\" not\"", payload);
        // Satır sonu içeren alan tırnak içinde korunur.
        Assert.Contains("\"satır\nsonu\"", payload);
        Assert.Contains(trickyItem.Id.ToString(), payload);
    }

    [Fact]
    public async Task Export_InvalidFormatReturnsBadRequest()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("export-badformat");
        await SeedAsync(factory, db => db.Users.Add(user));

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var response = await client.GetAsync("/api/export?format=xml");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task Export_WithoutTokenReturnsUnauthorized()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-SoMine-Api-Key", SomineApiWebApplicationFactory.ApiKey);

        var response = await client.GetAsync("/api/export?format=json");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [Fact]
    public async Task Export_DoesNotLeakOtherUsersData()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("export-owner");
        var stranger = TestUser("export-stranger");
        var strangerCategory = TestCategory(stranger.Id, "Gizli kategori");

        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(owner, stranger);
            db.Categories.Add(strangerCategory);
            db.Items.AddRange(
                TestItem(owner.Id, "owner-item"),
                TestItem(stranger.Id, "stranger-secret", strangerCategory.Id));
        });

        using var client = factory.CreateAuthenticatedClient(owner.Id, owner.Email!, owner.FirebaseUid);

        var response = await client.GetAsync("/api/export?format=json");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var payload = await response.Content.ReadAsStringAsync();
        using var document = JsonDocument.Parse(payload);
        var root = document.RootElement;

        var items = root.GetProperty("items").EnumerateArray().ToList();
        Assert.Single(items);
        Assert.Equal("owner-item", items[0].GetProperty("note").GetString());

        Assert.Empty(root.GetProperty("categories").EnumerateArray());
        Assert.DoesNotContain("stranger-secret", payload);
        Assert.DoesNotContain("Gizli kategori", payload);
        Assert.DoesNotContain(stranger.Email!, payload);
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

    private static Category TestCategory(Guid userId, string name)
    {
        return new Category
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Name = name,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }

    private static Item TestItem(Guid userId, string note, Guid? categoryId = null, bool isDeleted = false)
    {
        return new Item
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CategoryId = categoryId,
            Type = ItemType.Link,
            Url = $"https://example.com/{Uri.EscapeDataString(note)}",
            Note = note,
            IsDeleted = isDeleted,
            DeletedAt = isDeleted ? DateTime.UtcNow : null,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }
}
