using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using SomineApi.Tests.Testing;
using SomineApi.WebApi.Embeddings;

namespace SomineApi.Tests.Integration;

public class SemanticSearchTests
{
    [Fact]
    public async Task SearchItems_WithoutMode_ReturnsKeywordMatches()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("search-keyword");
        await SeedAsync(factory.Services, db =>
        {
            db.Users.Add(user);
            db.Items.AddRange(
                TestItem(user.Id, note: "alpha recipe for pasta"),
                TestItem(user.Id, note: "beta workout plan"));
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var response = await client.GetAsync("/api/items/search?q=alpha");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, body.GetProperty("totalCount").GetInt32());
        Assert.Equal("alpha recipe for pasta", body.GetProperty("items")[0].GetProperty("note").GetString());
    }

    [Fact]
    public async Task SearchItems_SemanticModeWithEmbeddingDisabled_FallsBackToKeyword()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("search-semantic-disabled");
        await SeedAsync(factory.Services, db =>
        {
            db.Users.Add(user);
            db.Items.AddRange(
                TestItem(user.Id, note: "alpha recipe for pasta"),
                TestItem(user.Id, note: "beta workout plan"));
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var response = await client.GetAsync("/api/items/search?q=alpha&mode=semantic");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, body.GetProperty("totalCount").GetInt32());
        Assert.Equal("alpha recipe for pasta", body.GetProperty("items")[0].GetProperty("note").GetString());

        // Embedding yapılandırılmadığı için sorgu hiç embed edilmemeli.
        Assert.Empty(factory.EmbeddingService.Requests);
    }

    [Fact]
    public async Task SearchItems_SemanticModeWithEmbeddingConfigured_FallsBackWhenVectorStoreUnavailable()
    {
        using var factory = new SomineApiWebApplicationFactory();
        using var configured = factory.WithWebHostBuilder(builder =>
            builder.ConfigureAppConfiguration((_, config) =>
                config.AddInMemoryCollection(new Dictionary<string, string?>
                {
                    ["Embedding:ApiKey"] = "sk-test-embedding"
                })));

        await ResetDatabaseAsync(configured.Services);

        var user = TestUser("search-semantic-fallback");
        await SeedAsync(configured.Services, db =>
        {
            db.Users.Add(user);
            db.Items.AddRange(
                TestItem(user.Id, note: "alpha recipe for pasta"),
                TestItem(user.Id, note: "beta workout plan"));
        });

        using var client = CreateAuthenticatedClient(configured, user);

        var response = await client.GetAsync("/api/items/search?q=alpha&mode=semantic");

        // SQLite'ta item_embeddings map dışı: semantik yol denenir, sorgu embed edilir,
        // vektör deposu bulunamayınca keyword aramaya zarifçe geri düşülür.
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, body.GetProperty("totalCount").GetInt32());
        Assert.Equal("alpha recipe for pasta", body.GetProperty("items")[0].GetProperty("note").GetString());

        var embedRequest = Assert.Single(factory.EmbeddingService.Requests);
        Assert.Equal(["alpha"], embedRequest);
    }

    [Fact]
    public async Task SearchItems_InvalidMode_ReturnsBadRequest()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("search-invalid-mode");
        await SeedAsync(factory.Services, db => db.Users.Add(user));

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var response = await client.GetAsync("/api/items/search?q=alpha&mode=fuzzy");

        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    [Fact]
    public async Task SearchItems_PlatformAndExcludeCategoryFilters_AreApplied()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("search-filters");
        var vaultCategory = TestCategory(user.Id, "Vault", isVault: true);
        var normalCategory = TestCategory(user.Id, "Videos");

        await SeedAsync(factory.Services, db =>
        {
            db.Users.Add(user);
            db.Categories.AddRange(vaultCategory, normalCategory);
            db.Items.AddRange(
                TestItem(user.Id, note: "youtube video", url: "https://www.youtube.com/watch?v=1", categoryId: normalCategory.Id),
                TestItem(user.Id, note: "youtube vault video", url: "https://youtu.be/2", categoryId: vaultCategory.Id),
                TestItem(user.Id, note: "plain article", url: "https://example.com/article"));
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        // Vault item'ları artık varsayılan olarak dönmüyor; platform filtresi
        // iki YouTube kaydını da yakalasa da yalnızca vault dışındaki döner.
        var platformResponse = await client.GetAsync("/api/items/search?platform=YouTube");
        Assert.Equal(HttpStatusCode.OK, platformResponse.StatusCode);
        var platformBody = await platformResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, platformBody.GetProperty("totalCount").GetInt32());
        Assert.Equal("youtube video", platformBody.GetProperty("items")[0].GetProperty("note").GetString());

        // includeVault=true ile platform filtresinin asıl kapsamı (2 kayıt) korunur.
        var platformWithVaultResponse = await client.GetAsync("/api/items/search?platform=YouTube&includeVault=true");
        Assert.Equal(HttpStatusCode.OK, platformWithVaultResponse.StatusCode);
        var platformWithVaultBody = await platformWithVaultResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(2, platformWithVaultBody.GetProperty("totalCount").GetInt32());

        var excludedResponse = await client.GetAsync(
            $"/api/items/search?platform=YouTube&excludeCategoryIds={vaultCategory.Id}");
        Assert.Equal(HttpStatusCode.OK, excludedResponse.StatusCode);
        var excludedBody = await excludedResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, excludedBody.GetProperty("totalCount").GetInt32());
        Assert.Equal("youtube video", excludedBody.GetProperty("items")[0].GetProperty("note").GetString());

        var categoryResponse = await client.GetAsync($"/api/items/search?categoryId={normalCategory.Id}");
        Assert.Equal(HttpStatusCode.OK, categoryResponse.StatusCode);
        var categoryBody = await categoryResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, categoryBody.GetProperty("totalCount").GetInt32());

        var invalidPlatformResponse = await client.GetAsync("/api/items/search?platform=Netflix");
        Assert.Equal(HttpStatusCode.BadRequest, invalidPlatformResponse.StatusCode);
    }

    [Fact]
    public void TestHost_RemovesEmbeddingBackgroundServiceAndUsesFakeEmbeddingService()
    {
        using var factory = new SomineApiWebApplicationFactory();

        var hostedServices = factory.Services.GetServices<IHostedService>();
        Assert.DoesNotContain(hostedServices, service => service is EmbeddingBackgroundService);

        var embeddingService = factory.Services.GetRequiredService<IEmbeddingService>();
        Assert.Same(factory.EmbeddingService, embeddingService);
    }

    private static HttpClient CreateAuthenticatedClient(WebApplicationFactory<Program> factory, User user)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-SoMine-Api-Key", SomineApiWebApplicationFactory.ApiKey);

        using var scope = factory.Services.CreateScope();
        var jwtService = scope.ServiceProvider.GetRequiredService<IJwtService>();
        var token = jwtService.GenerateAccessToken(user.Id, user.Email!, user.FirebaseUid, Guid.NewGuid());
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);

        return client;
    }

    private static async Task ResetDatabaseAsync(IServiceProvider services)
    {
        using var scope = services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        await dbContext.Database.EnsureDeletedAsync();
        await dbContext.Database.EnsureCreatedAsync();
    }

    private static async Task SeedAsync(IServiceProvider services, Action<SomineDbContext> seed)
    {
        using var scope = services.CreateScope();
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

    private static Category TestCategory(Guid userId, string name, bool isVault = false)
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

    private static Item TestItem(Guid userId, string note, string? url = null, Guid? categoryId = null)
    {
        return new Item
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            CategoryId = categoryId,
            Type = ItemType.Link,
            Url = url ?? $"https://example.com/{Guid.NewGuid():N}",
            Note = note,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
    }
}
