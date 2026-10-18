using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using SomineApi.Tests.Testing;
using SomineApi.WebApi.Admin;

namespace SomineApi.Tests.Integration;

// GSO Studio yönetim paneli uçları: X-Admin-Key koruması, karşılama içeriği ve şikâyet kuyruğu.
public class AdminApiTests
{
    private const string AdminKey = "admin-test-key-0123456789";

    [Fact]
    public async Task AdminEndpoints_Return404WhenKeyNotConfigured()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();
        using var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-SoMine-Api-Key", SomineApiWebApplicationFactory.ApiKey);
        client.DefaultRequestHeaders.Add("X-Admin-Key", "anything");

        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync("/api/admin/reports")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await client.GetAsync("/api/admin/onboarding/demo-content")).StatusCode);
    }

    [Fact]
    public async Task AdminEndpoints_Return401ForMissingOrWrongKey()
    {
        using var root = new SomineApiWebApplicationFactory();
        using var factory = await CreateAdminFactoryAsync(root, null);

        using var noKey = factory.CreateClient();
        noKey.DefaultRequestHeaders.Add("X-SoMine-Api-Key", SomineApiWebApplicationFactory.ApiKey);
        Assert.Equal(HttpStatusCode.Unauthorized, (await noKey.GetAsync("/api/admin/reports")).StatusCode);

        using var wrongKey = factory.CreateClient();
        wrongKey.DefaultRequestHeaders.Add("X-SoMine-Api-Key", SomineApiWebApplicationFactory.ApiKey);
        wrongKey.DefaultRequestHeaders.Add("X-Admin-Key", AdminKey + "x");
        Assert.Equal(HttpStatusCode.Unauthorized, (await wrongKey.GetAsync("/api/admin/reports")).StatusCode);

        using var ok = AdminClient(factory);
        Assert.Equal(HttpStatusCode.OK, (await ok.GetAsync("/api/admin/reports")).StatusCode);
    }

    [Fact]
    public void KeysMatch_IsExactAndRejectsEmpty()
    {
        Assert.True(AdminApiKeyAttribute.KeysMatch("abc", "abc"));
        Assert.False(AdminApiKeyAttribute.KeysMatch("abc", "abcd"));
        Assert.False(AdminApiKeyAttribute.KeysMatch("abc", "ABC"));
        Assert.False(AdminApiKeyAttribute.KeysMatch("abc", ""));
    }

    [Fact]
    public async Task DemoContent_PutWritesFileAtomicallyAndPublicEndpointServesIt()
    {
        var dir = Path.Combine(Path.GetTempPath(), $"somine-admin-{Guid.NewGuid():N}");
        var path = Path.Combine(dir, "onboarding-demo-content.json");
        try
        {
            using var root = new SomineApiWebApplicationFactory();
            using var factory = await CreateAdminFactoryAsync(root, path);
            using var client = AdminClient(factory);

            var before = await client.GetFromJsonAsync<JsonElement>("/api/admin/onboarding/demo-content");
            Assert.Equal("embedded", before.GetProperty("source").GetString());
            Assert.True(before.GetProperty("writable").GetBoolean());
            Assert.True(before.GetProperty("items").GetArrayLength() >= 8);
            Assert.Equal(["music", "places", "restaurants", "inspiration"],
                before.GetProperty("collections").EnumerateArray().Select(c => c.GetString()));
            Assert.Equal(50, before.GetProperty("maxItems").GetInt32());

            var put = await client.PutAsJsonAsync("/api/admin/onboarding/demo-content", new
            {
                items = new object[]
                {
                    new { collection = "places", url = " https://example.com/a ", note = "Bir yer" },
                    new { collection = "music", url = "https://example.com/b", note = (string?)null }
                }
            });
            Assert.Equal(HttpStatusCode.OK, put.StatusCode);
            var saved = await put.Content.ReadFromJsonAsync<JsonElement>();
            var version = saved.GetProperty("version").GetString()!;
            Assert.Matches(@"^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$", version);

            Assert.True(File.Exists(path));
            Assert.Empty(Directory.GetFiles(dir, "*.tmp"));
            var onDisk = JsonDocument.Parse(File.ReadAllText(path)).RootElement;
            Assert.Equal(version, onDisk.GetProperty("version").GetString());
            Assert.Equal("Bir yer", onDisk.GetProperty("items")[0].GetProperty("note").GetString());
            Assert.Equal("https://example.com/a", onDisk.GetProperty("items")[0].GetProperty("url").GetString());

            var after = await client.GetFromJsonAsync<JsonElement>("/api/admin/onboarding/demo-content");
            Assert.Equal("file", after.GetProperty("source").GetString());
            Assert.Equal(2, after.GetProperty("items").GetArrayLength());

            // Uygulamanın okuduğu public uç da yeni dosyayı döner.
            var user = new User { Id = Guid.NewGuid(), FirebaseUid = "fb-admin-demo", Email = "admin-demo@somine.test" };
            await SeedAsync(factory, db => db.Users.Add(user));
            using var userClient = CreateUserClient(factory, user);
            var publicBody = await userClient.GetFromJsonAsync<JsonElement>("/api/onboarding/demo-content");
            Assert.Equal(version, publicBody.GetProperty("version").GetString());
            Assert.Equal(2, publicBody.GetProperty("items").GetArrayLength());
        }
        finally
        {
            if (Directory.Exists(dir)) Directory.Delete(dir, recursive: true);
        }
    }

    [Fact]
    public async Task DemoContent_PutRejectsInvalidPayloads()
    {
        var path = Path.Combine(Path.GetTempPath(), $"somine-admin-{Guid.NewGuid():N}", "demo.json");
        using var root = new SomineApiWebApplicationFactory();
        using var factory = await CreateAdminFactoryAsync(root, path);
        using var client = AdminClient(factory);

        async Task<HttpStatusCode> Put(object body) =>
            (await client.PutAsJsonAsync("/api/admin/onboarding/demo-content", body)).StatusCode;

        Assert.Equal(HttpStatusCode.BadRequest, await Put(new { items = Array.Empty<object>() }));
        Assert.Equal(HttpStatusCode.BadRequest, await Put(new { items = new[] { new { collection = "recipes", url = "https://e.com" } } }));
        Assert.Equal(HttpStatusCode.BadRequest, await Put(new { items = new[] { new { collection = "music", url = "javascript:alert(1)" } } }));
        Assert.Equal(HttpStatusCode.BadRequest, await Put(new { items = new[] { new { collection = "music", url = "ftp://e.com/x" } } }));
        Assert.Equal(HttpStatusCode.BadRequest, await Put(new { items = new[] { new { collection = "music", url = "https://e.com", note = new string('x', 501) } } }));
        var tooMany = Enumerable.Range(0, 51).Select(i => new { collection = "music", url = $"https://e.com/{i}" }).ToArray();
        Assert.Equal(HttpStatusCode.BadRequest, await Put(new { items = tooMany }));
        Assert.False(File.Exists(path));
    }

    [Fact]
    public async Task DemoContent_PutReturnsConflictWhenPathNotConfigured()
    {
        using var root = new SomineApiWebApplicationFactory();
        using var factory = await CreateAdminFactoryAsync(root, null);
        using var client = AdminClient(factory);

        var get = await client.GetFromJsonAsync<JsonElement>("/api/admin/onboarding/demo-content");
        Assert.False(get.GetProperty("writable").GetBoolean());
        var put = await client.PutAsJsonAsync("/api/admin/onboarding/demo-content",
            new { items = new[] { new { collection = "music", url = "https://e.com" } } });
        Assert.Equal(HttpStatusCode.Conflict, put.StatusCode);
    }

    [Fact]
    public async Task Reports_ListsOpenReportsWithPeopleAndCollection()
    {
        using var root = new SomineApiWebApplicationFactory();
        using var factory = await CreateAdminFactoryAsync(root, null);
        var (sender, recipient, category, share, report) = Scenario("list");
        var closed = new ContentReport
        {
            Id = Guid.NewGuid(), ReporterId = recipient.Id, ReportedUserId = sender.Id,
            Reason = ReportReason.Spam, Status = ReportStatus.Dismissed
        };
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, recipient);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
            db.ContentReports.AddRange(report, closed);
        });

        using var client = AdminClient(factory);
        var open = await client.GetFromJsonAsync<JsonElement>("/api/admin/reports?status=Open");
        var row = Assert.Single(open.EnumerateArray());
        Assert.Equal(report.Id, row.GetProperty("id").GetGuid());
        Assert.Equal("Harassment", row.GetProperty("reason").GetString());
        Assert.Equal("rude", row.GetProperty("note").GetString());
        Assert.Equal("list-sender", row.GetProperty("reported").GetProperty("displayName").GetString());
        Assert.Equal("listrecipient", row.GetProperty("reporter").GetProperty("username").GetString());
        Assert.Equal("Reported collection", row.GetProperty("collectionName").GetString());
        Assert.Equal(share.Id, row.GetProperty("shareId").GetGuid());

        var all = await client.GetFromJsonAsync<JsonElement>("/api/admin/reports?status=all");
        Assert.Equal(2, all.GetArrayLength());
        Assert.Equal(HttpStatusCode.BadRequest, (await client.GetAsync("/api/admin/reports?status=bogus")).StatusCode);
    }

    [Theory]
    [InlineData("dismiss", ReportStatus.Dismissed, ShareStatus.Accepted)]
    [InlineData("reviewed", ReportStatus.Reviewed, ShareStatus.Accepted)]
    [InlineData("remove_share", ReportStatus.ActionTaken, ShareStatus.Rejected)]
    public async Task Reports_ResolveAppliesAction(string action, ReportStatus expectedReport, ShareStatus expectedShare)
    {
        using var root = new SomineApiWebApplicationFactory();
        using var factory = await CreateAdminFactoryAsync(root, null);
        var (sender, recipient, category, share, report) = Scenario(action.Replace("_", "", StringComparison.Ordinal));
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, recipient);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
            db.ContentReports.Add(report);
        });

        using var client = AdminClient(factory);
        var response = await client.PostAsJsonAsync($"/api/admin/reports/{report.Id}/resolve", new { action });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
            Assert.Equal(expectedReport, (await db.ContentReports.SingleAsync()).Status);
            var storedShare = await db.CollectionShares.SingleAsync();
            Assert.Equal(expectedShare, storedShare.Status);
            Assert.Equal(expectedShare == ShareStatus.Rejected, storedShare.RejectedAt != null);
        }

        // İkinci çözüm denemesi çakışma döner.
        var again = await client.PostAsJsonAsync($"/api/admin/reports/{report.Id}/resolve", new { action = "dismiss" });
        Assert.Equal(HttpStatusCode.Conflict, again.StatusCode);
    }

    [Fact]
    public async Task Reports_ResolveValidatesInput()
    {
        using var root = new SomineApiWebApplicationFactory();
        using var factory = await CreateAdminFactoryAsync(root, null);
        var (sender, recipient, category, _, _) = Scenario("validate");
        var noShare = new ContentReport
        {
            Id = Guid.NewGuid(), ReporterId = recipient.Id, ReportedUserId = sender.Id,
            CategoryId = category.Id, Reason = ReportReason.Other
        };
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, recipient);
            db.Categories.Add(category);
            db.ContentReports.Add(noShare);
        });

        using var client = AdminClient(factory);
        Assert.Equal(HttpStatusCode.BadRequest,
            (await client.PostAsJsonAsync($"/api/admin/reports/{noShare.Id}/resolve", new { action = "delete_everything" })).StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest,
            (await client.PostAsJsonAsync($"/api/admin/reports/{noShare.Id}/resolve", new { action = "remove_share" })).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound,
            (await client.PostAsJsonAsync($"/api/admin/reports/{Guid.NewGuid()}/resolve", new { action = "dismiss" })).StatusCode);
    }

    private static async Task<WebApplicationFactory<Program>> CreateAdminFactoryAsync(SomineApiWebApplicationFactory root, string? demoContentPath)
    {
        var factory = root.WithWebHostBuilder(builder =>
        {
            builder.UseSetting("Admin:ApiKey", AdminKey);
            if (demoContentPath != null)
            {
                builder.UseSetting("Onboarding:DemoContentPath", demoContentPath);
            }
        });
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        await db.Database.EnsureDeletedAsync();
        await db.Database.EnsureCreatedAsync();
        return factory;
    }

    private static HttpClient AdminClient(WebApplicationFactory<Program> factory)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-SoMine-Api-Key", SomineApiWebApplicationFactory.ApiKey);
        client.DefaultRequestHeaders.Add("X-Admin-Key", AdminKey);
        return client;
    }

    private static HttpClient CreateUserClient(WebApplicationFactory<Program> factory, User user)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-SoMine-Api-Key", SomineApiWebApplicationFactory.ApiKey);
        using var scope = factory.Services.CreateScope();
        var jwt = scope.ServiceProvider.GetRequiredService<SomineApi.Application.Interfaces.IJwtService>();
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue(
            "Bearer", jwt.GenerateAccessToken(user.Id, user.Email!, user.FirebaseUid, Guid.NewGuid()));
        return client;
    }

    private static async Task SeedAsync(WebApplicationFactory<Program> factory, Action<SomineDbContext> seed)
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        seed(db);
        await db.SaveChangesAsync();
    }

    private static (User Sender, User Recipient, Category Category, CollectionShare Share, ContentReport Report) Scenario(string key)
    {
        var sender = TestUser($"{key}-sender");
        var recipient = TestUser($"{key}-recipient");
        var category = new Category { Id = Guid.NewGuid(), UserId = sender.Id, Name = "Reported collection" };
        var share = new CollectionShare
        {
            Id = Guid.NewGuid(), FromUserId = sender.Id, ToUserId = recipient.Id, CategoryId = category.Id,
            CategoryName = "Reported collection", Status = ShareStatus.Accepted, AcceptedAt = DateTime.UtcNow
        };
        var report = new ContentReport
        {
            Id = Guid.NewGuid(), ReporterId = recipient.Id, ReportedUserId = sender.Id, ShareId = share.Id,
            CategoryId = category.Id, Reason = ReportReason.Harassment, Note = "rude", Status = ReportStatus.Open
        };
        return (sender, recipient, category, share, report);
    }

    private static User TestUser(string key) => new()
    {
        Id = Guid.NewGuid(),
        FirebaseUid = $"firebase-{key}",
        Email = $"{key}@somine.test",
        DisplayName = key,
        Username = key.Replace("-", "", StringComparison.Ordinal)
    };
}
