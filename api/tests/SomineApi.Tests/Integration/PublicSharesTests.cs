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

public class PublicSharesTests
{
    [Fact]
    public async Task CreatePublicLink_OwnerCreatesRotatesAndDeletesLink()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("public-owner");
        var recipient = TestUser("public-recipient");
        var category = TestCategory(owner.Id, "Public collection");
        var share = TestShare(owner.Id, recipient.Id, category.Id, ShareStatus.Accepted);

        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(owner, recipient);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
        });

        using var client = factory.CreateAuthenticatedClient(owner.Id, owner.Email!, owner.FirebaseUid);

        var createResponse = await client.PostAsync($"/api/shares/{share.Id}/public-link", null);
        Assert.Equal(HttpStatusCode.OK, createResponse.StatusCode);
        var created = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        var token1 = created.GetProperty("token").GetString();
        Assert.False(string.IsNullOrWhiteSpace(token1));
        Assert.EndsWith($"/s/{token1}", created.GetProperty("url").GetString());

        // Rotate — yeni token, eskisi geçersiz
        var rotateResponse = await client.PostAsync($"/api/shares/{share.Id}/public-link", null);
        Assert.Equal(HttpStatusCode.OK, rotateResponse.StatusCode);
        var rotated = await rotateResponse.Content.ReadFromJsonAsync<JsonElement>();
        var token2 = rotated.GetProperty("token").GetString();
        Assert.NotEqual(token1, token2);

        // Delete — token null
        var deleteResponse = await client.DeleteAsync($"/api/shares/{share.Id}/public-link");
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        var stored = await db.CollectionShares.FirstAsync(s => s.Id == share.Id);
        Assert.Null(stored.PublicLinkToken);
        Assert.Null(stored.PublicLinkCreatedAtUtc);
    }

    [Fact]
    public async Task CreatePublicLink_NonOwnerReturnsNotFound()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("owner-x");
        var recipient = TestUser("recipient-x");
        var stranger = TestUser("stranger-x");
        var category = TestCategory(owner.Id, "Collection");
        var share = TestShare(owner.Id, recipient.Id, category.Id, ShareStatus.Accepted);

        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(owner, recipient, stranger);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
        });

        using var strangerClient = factory.CreateAuthenticatedClient(stranger.Id, stranger.Email!, stranger.FirebaseUid);
        var response = await strangerClient.PostAsync($"/api/shares/{share.Id}/public-link", null);

        Assert.Equal(HttpStatusCode.NotFound, response.StatusCode);
    }

    [Fact]
    public async Task CreatePublicLink_VaultCategoryReturnsBadRequest()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("vault-owner");
        var recipient = TestUser("vault-recipient");
        var category = TestCategory(owner.Id, "Secret vault");
        category.IsVault = true;
        var share = TestShare(owner.Id, recipient.Id, category.Id, ShareStatus.Accepted);

        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(owner, recipient);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
        });

        using var client = factory.CreateAuthenticatedClient(owner.Id, owner.Email!, owner.FirebaseUid);
        var response = await client.PostAsync($"/api/shares/{share.Id}/public-link", null);

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task GetPublicShare_ValidTokenReturnsContentWithoutApiKey()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("content-owner");
        var recipient = TestUser("content-recipient");
        var category = TestCategory(owner.Id, "My links");
        owner.DisplayName = "Ada Lovelace";
        var share = TestShare(owner.Id, recipient.Id, category.Id, ShareStatus.Accepted);
        share.CategoryName = "My links";
        share.FromUserName = "Ada Lovelace";
        share.PublicLinkToken = "test-token-valid";
        share.PublicLinkCreatedAtUtc = DateTime.UtcNow;

        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(owner, recipient);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
            db.Items.AddRange(
                TestItem(owner.Id, "first", category.Id),
                TestItem(owner.Id, "second", category.Id));
        });

        // API key GONDERMEDEN — public muafiyeti calismali
        using var anonymousClient = factory.CreateClient();
        var response = await anonymousClient.GetAsync($"/public/shares/{share.PublicLinkToken}");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("My links", body.GetProperty("categoryName").GetString());
        Assert.Equal("Ada Lovelace", body.GetProperty("fromUserName").GetString());
        Assert.Equal(2, body.GetProperty("items").GetArrayLength());

        // userId sizmamali
        Assert.DoesNotContain("userId", body.GetRawText(), StringComparison.OrdinalIgnoreCase);
    }

    [Fact]
    public async Task GetPublicShare_RevokedAndUnknownTokenReturnNotFound()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("revoke-owner");
        var recipient = TestUser("revoke-recipient");
        var category = TestCategory(owner.Id, "Collection");
        var share = TestShare(owner.Id, recipient.Id, category.Id, ShareStatus.Accepted);
        share.PublicLinkToken = "will-be-revoked";
        share.PublicLinkCreatedAtUtc = DateTime.UtcNow;

        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(owner, recipient);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
        });

        using var ownerClient = factory.CreateAuthenticatedClient(owner.Id, owner.Email!, owner.FirebaseUid);
        using var anonymousClient = factory.CreateClient();

        // Uydurma token -> notr 404
        var unknownResponse = await anonymousClient.GetAsync("/public/shares/nonexistent-token");
        Assert.Equal(HttpStatusCode.NotFound, unknownResponse.StatusCode);
        var unknownBody = await unknownResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Not found", unknownBody.GetProperty("error").GetString());

        // Iptal edilen token -> 404
        var deleteResponse = await ownerClient.DeleteAsync($"/api/shares/{share.Id}/public-link");
        Assert.Equal(HttpStatusCode.NoContent, deleteResponse.StatusCode);

        var revokedResponse = await anonymousClient.GetAsync("/public/shares/will-be-revoked");
        Assert.Equal(HttpStatusCode.NotFound, revokedResponse.StatusCode);
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

    private static CollectionShare TestShare(Guid fromUserId, Guid toUserId, Guid categoryId, ShareStatus status) => new()
    {
        Id = Guid.NewGuid(),
        FromUserId = fromUserId,
        ToUserId = toUserId,
        CategoryId = categoryId,
        CategoryName = "Collection",
        Status = status,
        CreatedAt = DateTime.UtcNow,
        AcceptedAt = status == ShareStatus.Accepted ? DateTime.UtcNow : null
    };
}
