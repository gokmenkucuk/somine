using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Options;
using SomineApi.Domain.Entities;
using SomineApi.Tests.Testing;
using SomineApi.WebApi.Onboarding;

namespace SomineApi.Tests.Integration;

public class OnboardingDemoContentTests
{
    [Fact]
    public async Task DemoContent_ReturnsBuiltInListForSignedInUser()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();
        var user = new User { Id = Guid.NewGuid(), FirebaseUid = "fb-onboarding", Email = "onboarding@somine.test" };
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<SomineApi.Infrastructure.Data.SomineDbContext>();
            db.Users.Add(user);
            await db.SaveChangesAsync();
        }

        using var anonymous = factory.CreateClient();
        anonymous.DefaultRequestHeaders.Add("X-SoMine-Api-Key", SomineApiWebApplicationFactory.ApiKey);
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync("/api/onboarding/demo-content")).StatusCode);

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);
        var body = await client.GetFromJsonAsync<JsonElement>("/api/onboarding/demo-content");
        var items = body.GetProperty("items").EnumerateArray().ToList();

        Assert.False(string.IsNullOrWhiteSpace(body.GetProperty("version").GetString()));
        Assert.True(items.Count >= 8);
        Assert.All(items, i => Assert.Contains(i.GetProperty("collection").GetString()!, OnboardingDemoContentProvider.Collections));
        // Dört koleksiyonun hepsi dolu gelir.
        Assert.Equal(4, items.Select(i => i.GetProperty("collection").GetString()).Distinct().Count());
    }

    [Fact]
    public void DemoContent_PrefersServerFileAndDropsInvalidRows()
    {
        var path = Path.Combine(Path.GetTempPath(), $"demo-{Guid.NewGuid():N}.json");
        File.WriteAllText(path, """
            { "version": "test-1", "items": [
              { "collection": "places", "url": "https://example.com/a" },
              { "collection": "unknown", "url": "https://example.com/b" },
              { "collection": "music", "url": "javascript:alert(1)" },
              { "collection": "music", "url": "https://example.com/c", "note": "kept" }
            ] }
            """);
        try
        {
            var provider = new OnboardingDemoContentProvider(
                new StaticOptionsMonitor(new OnboardingOptions { DemoContentPath = path }),
                Microsoft.Extensions.Logging.Abstractions.NullLogger<OnboardingDemoContentProvider>.Instance);
            var content = provider.Get();

            Assert.Equal("test-1", content.Version);
            Assert.Equal(["https://example.com/a", "https://example.com/c"], content.Items.Select(i => i.Url));
        }
        finally
        {
            File.Delete(path);
        }
    }

    [Fact]
    public void DemoContent_FallsBackToBuiltInWhenFileIsBroken()
    {
        var path = Path.Combine(Path.GetTempPath(), $"demo-{Guid.NewGuid():N}.json");
        File.WriteAllText(path, "{ not json");
        try
        {
            var provider = new OnboardingDemoContentProvider(
                new StaticOptionsMonitor(new OnboardingOptions { DemoContentPath = path }),
                Microsoft.Extensions.Logging.Abstractions.NullLogger<OnboardingDemoContentProvider>.Instance);
            Assert.True(provider.Get().Items.Count >= 8);
        }
        finally
        {
            File.Delete(path);
        }
    }

    private sealed class StaticOptionsMonitor(OnboardingOptions value) : IOptionsMonitor<OnboardingOptions>
    {
        public OnboardingOptions CurrentValue => value;
        public OnboardingOptions Get(string? name) => value;
        public IDisposable? OnChange(Action<OnboardingOptions, string?> listener) => null;
    }
}
