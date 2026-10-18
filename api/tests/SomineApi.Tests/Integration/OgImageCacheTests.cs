using System.Net;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using SomineApi.Tests.Testing;
using SomineApi.WebApi.ImageCache;

namespace SomineApi.Tests.Integration;

// OG görsel önbelleği: imzalı CDN adresleri (Instagram/Facebook `oe=`) birkaç günde ölüyor;
// sunucu görseli kendi depolamasına kopyalar. Tüm HTTP/DNS sahtedir — gerçek ağ yok.
public class OgImageCacheTests
{
    private static readonly byte[] Jpeg = [0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, 0x49, 0x46, 0x00, 0x01, 0xAA, 0xBB];
    private static readonly byte[] Png = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52];
    private static readonly byte[] Gif = "GIF89a\u0001\u0000\u0001\u0000"u8.ToArray();
    private static readonly byte[] Webp = [.. "RIFF"u8, 0x24, 0x00, 0x00, 0x00, .. "WEBPVP8 "u8, 0x00];

    // ---------------------------------------------------------------- SSRF

    [Theory]
    [InlineData("http://10.0.0.5/a.jpg")]
    [InlineData("http://127.0.0.1/a.jpg")]
    [InlineData("http://localhost/a.jpg")]
    [InlineData("http://[::1]/a.jpg")]
    [InlineData("http://169.254.169.254/latest/meta-data")]
    [InlineData("http://192.168.1.1/a.jpg")]
    [InlineData("http://[fd00::1]/a.jpg")]
    [InlineData("http://[fe80::1]/a.jpg")]
    [InlineData("http://[::ffff:10.0.0.1]/a.jpg")]
    [InlineData("http://0.0.0.0/a.jpg")]
    [InlineData("http://224.0.0.1/a.jpg")]
    public async Task CacheAsync_BlocksNonPublicTargets_WithoutSendingRequest(string url)
    {
        using var factory = new SomineApiWebApplicationFactory();
        factory.ImageHttpHandler.RespondWith(url, Jpeg);

        var result = await CacheAsync(factory, url);

        Assert.Equal(ImageCacheStatus.PermanentFailure, result.Status);
        Assert.Equal("blocked_address", result.Reason);
        Assert.Empty(factory.ImageHttpHandler.Requests);
    }

    [Theory]
    [InlineData("file:///etc/passwd")]
    [InlineData("ftp://cdn.example.com/a.jpg")]
    [InlineData("gopher://cdn.example.com/a")]
    public async Task CacheAsync_RejectsNonHttpSchemes(string url)
    {
        using var factory = new SomineApiWebApplicationFactory();

        var result = await CacheAsync(factory, url);

        Assert.Equal(ImageCacheStatus.PermanentFailure, result.Status);
        Assert.Equal("unsupported_scheme", result.Reason);
        Assert.Empty(factory.ImageHttpHandler.Requests);
    }

    [Fact]
    public async Task CacheAsync_BlocksHostThatResolvesToPrivateAddress_EvenIfAlsoPublic()
    {
        using var factory = new SomineApiWebApplicationFactory();
        factory.HostAddressResolver.Map("internal.example.com", "192.168.1.10");
        factory.HostAddressResolver.Map("mixed.example.com", "93.184.216.34", "10.1.2.3");
        factory.ImageHttpHandler.RespondWith("https://internal.example.com/a.jpg", Jpeg);
        factory.ImageHttpHandler.RespondWith("https://mixed.example.com/a.jpg", Jpeg);

        Assert.Equal("blocked_address", (await CacheAsync(factory, "https://internal.example.com/a.jpg")).Reason);
        Assert.Equal("blocked_address", (await CacheAsync(factory, "https://mixed.example.com/a.jpg")).Reason);
        Assert.Empty(factory.ImageHttpHandler.Requests);
    }

    [Fact]
    public async Task CacheAsync_RedirectToPrivateAddress_IsBlockedBeforeFollowing()
    {
        using var factory = new SomineApiWebApplicationFactory();
        factory.ImageHttpHandler.RedirectTo("https://cdn.example.com/a.jpg", "http://169.254.169.254/latest/meta-data");
        factory.ImageHttpHandler.RespondWith("http://169.254.169.254/latest/meta-data", Jpeg);

        var result = await CacheAsync(factory, "https://cdn.example.com/a.jpg");

        Assert.Equal(ImageCacheStatus.PermanentFailure, result.Status);
        Assert.Equal("blocked_address", result.Reason);
        Assert.Single(factory.ImageHttpHandler.Requests);
    }

    [Fact]
    public async Task CacheAsync_FollowsAtMostThreeRedirects()
    {
        using var factory = new SomineApiWebApplicationFactory();
        factory.ImageHttpHandler.RedirectTo("https://a.example.com/1", "https://a.example.com/2");
        factory.ImageHttpHandler.RedirectTo("https://a.example.com/2", "/3");
        factory.ImageHttpHandler.RedirectTo("https://a.example.com/3", "https://b.example.com/4", HttpStatusCode.MovedPermanently);
        factory.ImageHttpHandler.RespondWith("https://b.example.com/4", Jpeg);

        var ok = await CacheAsync(factory, "https://a.example.com/1");
        Assert.Equal(ImageCacheStatus.Cached, ok.Status);

        factory.ImageHttpHandler.RedirectTo("https://b.example.com/4", "https://b.example.com/5");
        factory.ImageHttpHandler.RespondWith("https://b.example.com/5", Jpeg);
        var tooMany = await CacheAsync(factory, "https://a.example.com/1");
        Assert.Equal(ImageCacheStatus.PermanentFailure, tooMany.Status);
        Assert.Equal("too_many_redirects", tooMany.Reason);
    }

    [Theory]
    [InlineData("10.0.0.1", false)]
    [InlineData("172.31.255.255", false)]
    [InlineData("172.32.0.1", true)]
    [InlineData("100.64.0.1", false)]
    [InlineData("8.8.8.8", true)]
    [InlineData("2606:4700:4700::1111", true)]
    [InlineData("::", false)]
    [InlineData("fc00::1", false)]
    [InlineData("ff02::1", false)]
    [InlineData("64:ff9b::a00:1", false)]
    [InlineData("::ffff:8.8.8.8", true)]
    public void IpAddressPolicy_ClassifiesAddresses(string address, bool isPublic)
    {
        Assert.Equal(isPublic, IpAddressPolicy.IsPublic(IPAddress.Parse(address)));
    }

    // ---------------------------------------------------------------- İçerik doğrulama

    [Theory]
    [InlineData("text/html")]
    [InlineData("application/octet-stream")]
    [InlineData("image/svg+xml")]
    public async Task CacheAsync_RejectsNonImageOrSvgContentType(string contentType)
    {
        using var factory = new SomineApiWebApplicationFactory();
        factory.ImageHttpHandler.RespondWith("https://cdn.example.com/x", Jpeg, contentType);

        var result = await CacheAsync(factory, "https://cdn.example.com/x");

        Assert.Equal(ImageCacheStatus.PermanentFailure, result.Status);
        Assert.Equal("unsupported_content_type", result.Reason);
    }

    [Fact]
    public async Task CacheAsync_RejectsBytesThatAreNotARecognizedImage_EvenWithImageContentType()
    {
        using var factory = new SomineApiWebApplicationFactory();
        factory.ImageHttpHandler.RespondWith("https://cdn.example.com/html", "<html><script>x</script></html>"u8.ToArray());
        factory.ImageHttpHandler.RespondWith("https://cdn.example.com/svg",
            "<svg xmlns=\"http://www.w3.org/2000/svg\"/>"u8.ToArray(), "image/png");

        Assert.Equal("unrecognized_image_signature", (await CacheAsync(factory, "https://cdn.example.com/html")).Reason);
        Assert.Equal("unrecognized_image_signature", (await CacheAsync(factory, "https://cdn.example.com/svg")).Reason);
    }

    [Fact]
    public async Task CacheAsync_DetectsFormatFromMagicBytes()
    {
        using var factory = new SomineApiWebApplicationFactory();
        factory.ImageHttpHandler.RespondWith("https://cdn.example.com/j", Jpeg, "image/jpeg");
        factory.ImageHttpHandler.RespondWith("https://cdn.example.com/p", Png, "image/jpeg"); // yanlış başlık: baytlar kazanır
        factory.ImageHttpHandler.RespondWith("https://cdn.example.com/g", Gif, "image/gif");
        factory.ImageHttpHandler.RespondWith("https://cdn.example.com/w", Webp, "image/webp");

        Assert.EndsWith(".jpg", (await CacheAsync(factory, "https://cdn.example.com/j")).Url);
        Assert.EndsWith(".png", (await CacheAsync(factory, "https://cdn.example.com/p")).Url);
        Assert.EndsWith(".gif", (await CacheAsync(factory, "https://cdn.example.com/g")).Url);
        Assert.EndsWith(".webp", (await CacheAsync(factory, "https://cdn.example.com/w")).Url);
    }

    [Fact]
    public async Task CacheAsync_RejectsImagesLargerThanMaxBytes()
    {
        using var factory = new SomineApiWebApplicationFactory();
        var huge = new byte[5 * 1024 * 1024 + 1];
        Jpeg.CopyTo(huge, 0);
        factory.ImageHttpHandler.RespondWith("https://cdn.example.com/huge.jpg", huge);

        var result = await CacheAsync(factory, "https://cdn.example.com/huge.jpg");

        Assert.Equal(ImageCacheStatus.PermanentFailure, result.Status);
        Assert.Equal("too_large", result.Reason);
    }

    [Fact]
    public async Task CacheAsync_ClassifiesHttpErrors()
    {
        using var factory = new SomineApiWebApplicationFactory();
        factory.ImageHttpHandler.RespondWithStatus("https://cdn.example.com/expired", HttpStatusCode.Forbidden);
        factory.ImageHttpHandler.RespondWithStatus("https://cdn.example.com/down", HttpStatusCode.ServiceUnavailable);
        factory.ImageHttpHandler.Throw("https://cdn.example.com/net", new HttpRequestException("connection reset"));

        Assert.Equal(ImageCacheStatus.PermanentFailure, (await CacheAsync(factory, "https://cdn.example.com/expired")).Status);
        Assert.Equal(ImageCacheStatus.PermanentFailure, (await CacheAsync(factory, "https://cdn.example.com/missing")).Status);
        Assert.Equal(ImageCacheStatus.TransientFailure, (await CacheAsync(factory, "https://cdn.example.com/down")).Status);
        Assert.Equal(ImageCacheStatus.TransientFailure, (await CacheAsync(factory, "https://cdn.example.com/net")).Status);
    }

    // ---------------------------------------------------------------- Depolama + public servis

    [Fact]
    public async Task CacheAsync_DedupesByContentHash_AndServesPubliclyWithoutAuth()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();
        factory.ImageHttpHandler.RespondWith("https://scontent.cdninstagram.com/a.jpg?oe=1", Jpeg);
        factory.ImageHttpHandler.RespondWith("https://scontent.cdninstagram.com/a.jpg?oe=2", Jpeg);

        var first = await CacheAsync(factory, "https://scontent.cdninstagram.com/a.jpg?oe=1");
        var second = await CacheAsync(factory, "https://scontent.cdninstagram.com/a.jpg?oe=2");

        var expectedName = Convert.ToHexStringLower(SHA256.HashData(Jpeg)) + ".jpg";
        Assert.Equal(ImageCacheStatus.Cached, first.Status);
        Assert.Equal(first.Url, second.Url);
        Assert.EndsWith("/public/og/" + expectedName, first.Url);
        Assert.DoesNotContain("/api/storage/", first.Url); // mobil/web bu adrese yetki başlığı eklemesin

        // Kimliksiz ve ApiKey'siz istemci ("/public" muaf).
        using var anonymous = factory.CreateClient();
        var response = await anonymous.GetAsync("/public/og/" + expectedName);
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal("image/jpeg", response.Content.Headers.ContentType?.MediaType);
        Assert.Equal(Jpeg, await response.Content.ReadAsByteArrayAsync());
        Assert.Contains("immutable", response.Headers.CacheControl?.ToString());

        Assert.Equal(HttpStatusCode.NotFound, (await anonymous.GetAsync("/public/og/..%2F..%2Fappsettings.json")).StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, (await anonymous.GetAsync("/public/og/" + new string('a', 64) + ".jpg")).StatusCode);
    }

    // ---------------------------------------------------------------- Kuyruk + item güncelleme

    [Fact]
    public async Task CreateItem_EnqueuesExternalImage_AndProcessingSwapsUrlKeepingSource()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();
        DrainQueue(factory);
        const string source = "https://scontent-ist1-1.cdninstagram.com/v/t51/123.jpg?oe=6720ABCD&_nc_sid=x";
        factory.ImageHttpHandler.RespondWith(source, Jpeg);

        var user = TestUser("og-cache-create");
        await SeedAsync(factory, db => db.Users.Add(user));
        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var createResponse = await client.PostAsJsonAsync("/api/items", new
        {
            url = "https://www.instagram.com/p/abc/",
            type = ItemType.Link,
            ogImageUrl = source
        });

        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);
        var created = await createResponse.Content.ReadFromJsonAsync<JsonElement>();
        // İstek indirmeyi beklemez: yanıtta henüz orijinal adres var, ağa hiç çıkılmadı.
        Assert.Equal(source, created.GetProperty("ogImageUrl").GetString());
        Assert.Empty(factory.ImageHttpHandler.Requests);
        var itemId = created.GetProperty("id").GetGuid();
        Assert.Equal([itemId], DrainQueue(factory));

        var before = await LoadItemAsync(factory, itemId);
        var publisher = new RecordingUserRealtimeEventPublisher();
        var outcome = await CreateProcessor(factory, publisher).ProcessAsync(itemId, CancellationToken.None);

        Assert.Equal(OgImageCacheOutcome.Cached, outcome);
        var after = await LoadItemAsync(factory, itemId);
        Assert.StartsWith("http://localhost:5000/public/og/", after.OgImageUrl);
        Assert.Equal(source, after.OgImageSourceUrl);
        Assert.Null(after.OgImageCacheFailedAt);
        Assert.True(after.UpdatedAt > before.UpdatedAt);
        Assert.Contains(publisher.ItemEvents, e => e.UserId == user.Id && e.Action == "updated" && e.EntityId == itemId);

        // API artık kendi adresimizi döner; tekrar işlemek no-op.
        var fetched = await (await client.GetAsync($"/api/items/{itemId}")).Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(after.OgImageUrl, fetched.GetProperty("ogImageUrl").GetString());
        Assert.Equal(OgImageCacheOutcome.Skipped, await CreateProcessor(factory, publisher).ProcessAsync(itemId, CancellationToken.None));
    }

    [Fact]
    public async Task CreateItem_WhenDownloadFails_RequestStillSucceeds_AndItemIsMarkedFailed()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();
        DrainQueue(factory);
        const string source = "https://scontent.xx.fbcdn.net/v/expired.jpg?oe=600";
        factory.ImageHttpHandler.RespondWithStatus(source, HttpStatusCode.Forbidden);

        var user = TestUser("og-cache-fail");
        await SeedAsync(factory, db => db.Users.Add(user));
        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var createResponse = await client.PostAsJsonAsync("/api/items", new
        {
            url = "https://www.facebook.com/x",
            type = ItemType.Link,
            ogImageUrl = source
        });
        Assert.Equal(HttpStatusCode.Created, createResponse.StatusCode);
        var itemId = (await createResponse.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        var outcome = await CreateProcessor(factory, new RecordingUserRealtimeEventPublisher()).ProcessAsync(itemId, CancellationToken.None);

        Assert.Equal(OgImageCacheOutcome.MarkedFailed, outcome);
        var item = await LoadItemAsync(factory, itemId);
        Assert.Equal(source, item.OgImageUrl); // orijinal adres yerinde kalır
        Assert.Null(item.OgImageSourceUrl);
        Assert.NotNull(item.OgImageCacheFailedAt);
    }

    [Fact]
    public async Task CreateItem_WithOwnOrMissingImage_DoesNotEnqueue()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();
        DrainQueue(factory);
        var user = TestUser("og-cache-own");
        await SeedAsync(factory, db => db.Users.Add(user));
        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        await client.PostAsJsonAsync("/api/items", new { url = "https://example.com/a", type = ItemType.Link });
        await client.PostAsJsonAsync("/api/items", new
        {
            url = "https://example.com/b",
            type = ItemType.Link,
            ogImageUrl = "http://localhost:5000/public/og/" + new string('a', 64) + ".jpg"
        });

        Assert.Empty(DrainQueue(factory));
    }

    [Fact]
    public async Task UpdateItem_ResendingOriginalSourceUrl_KeepsCachedCopy_ButNewUrlIsReEnqueued()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();
        DrainQueue(factory);
        var user = TestUser("og-cache-update");
        var cachedUrl = "http://localhost:5000/public/og/" + new string('b', 64) + ".jpg";
        var item = TestItem(user.Id, "cached");
        item.OgImageUrl = cachedUrl;
        item.OgImageSourceUrl = "https://scontent.cdninstagram.com/old.jpg?oe=1";
        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(item);
        });
        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        // Eski istemci, yerel kopyasındaki orijinal adresi geri gönderiyor.
        var stale = await client.PutAsJsonAsync($"/api/items/{item.Id}", new { note = "edited", ogImageUrl = item.OgImageSourceUrl });
        Assert.Equal(HttpStatusCode.OK, stale.StatusCode);
        Assert.Equal(cachedUrl, (await LoadItemAsync(factory, item.Id)).OgImageUrl);
        Assert.Empty(DrainQueue(factory));

        // Gerçekten yeni bir görsel: kopya bilgisi sıfırlanır ve yeniden kuyruğa girer.
        const string newSource = "https://cdn.example.com/new.png";
        await client.PutAsJsonAsync($"/api/items/{item.Id}", new { ogImageUrl = newSource });
        var updated = await LoadItemAsync(factory, item.Id);
        Assert.Equal(newSource, updated.OgImageUrl);
        Assert.Null(updated.OgImageSourceUrl);
        Assert.Equal([item.Id], DrainQueue(factory));
    }

    [Fact]
    public async Task Processor_ReusesExistingCopyOfSameSource_WithoutDownloading()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();
        const string source = "https://scontent.cdninstagram.com/shared.jpg?oe=1";
        var cachedUrl = "http://localhost:5000/public/og/" + new string('c', 64) + ".jpg";
        var user = TestUser("og-cache-reuse");
        var existing = TestItem(user.Id, "existing");
        existing.OgImageUrl = cachedUrl;
        existing.OgImageSourceUrl = source;
        var fresh = TestItem(user.Id, "fresh");
        fresh.OgImageUrl = source;
        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.AddRange(existing, fresh);
        });

        var outcome = await CreateProcessor(factory, new RecordingUserRealtimeEventPublisher()).ProcessAsync(fresh.Id, CancellationToken.None);

        Assert.Equal(OgImageCacheOutcome.Reused, outcome);
        Assert.Equal(cachedUrl, (await LoadItemAsync(factory, fresh.Id)).OgImageUrl);
        Assert.Empty(factory.ImageHttpHandler.Requests);
    }

    // ---------------------------------------------------------------- Backfill

    [Fact]
    public async Task Backfill_ProcessesExternalItemsNewestFirst_MarksDeadSources_AndIsSafeToRerun()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();
        var user = TestUser("og-backfill");
        var now = DateTime.UtcNow;

        Item Make(string note, string? og, int minutesAgo)
        {
            var item = TestItem(user.Id, note);
            item.OgImageUrl = og;
            item.CreatedAt = now.AddMinutes(-minutesAgo);
            return item;
        }

        var alive = Make("alive", "https://cdn.example.com/alive.jpg", 1);
        var alive2 = Make("alive2", "https://cdn.example.com/alive2.png", 2);
        var dead = Make("dead", "https://scontent.cdninstagram.com/dead.jpg?oe=1", 3);
        var flaky = Make("flaky", "https://cdn.example.com/flaky.jpg", 4);
        var noImage = Make("none", null, 5);
        var own = Make("own", "http://localhost:5000/public/og/" + new string('d', 64) + ".jpg", 6);
        var alreadyFailed = Make("failed", "https://cdn.example.com/failed-before.jpg", 7);
        alreadyFailed.OgImageCacheFailedAt = now.AddDays(-1);
        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.AddRange(alive, alive2, dead, flaky, noImage, own, alreadyFailed);
        });

        factory.ImageHttpHandler.RespondWith("https://cdn.example.com/alive.jpg", Jpeg);
        factory.ImageHttpHandler.RespondWith("https://cdn.example.com/alive2.png", Png, "image/png");
        factory.ImageHttpHandler.RespondWithStatus("https://scontent.cdninstagram.com/dead.jpg?oe=1", HttpStatusCode.Forbidden);
        factory.ImageHttpHandler.RespondWithStatus("https://cdn.example.com/flaky.jpg", HttpStatusCode.BadGateway);

        var backfill = CreateBackfill(factory);
        var summary = await backfill.RunAsync(CancellationToken.None);

        Assert.Equal(2, summary.Cached);
        Assert.Equal(1, summary.MarkedFailed);
        Assert.Equal(1, summary.TransientFailures);
        Assert.Equal(
            ["https://cdn.example.com/alive.jpg", "https://cdn.example.com/alive2.png",
             "https://scontent.cdninstagram.com/dead.jpg?oe=1", "https://cdn.example.com/flaky.jpg"],
            factory.ImageHttpHandler.Requests.Select(u => u.ToString()).ToList());

        Assert.EndsWith(".jpg", (await LoadItemAsync(factory, alive.Id)).OgImageUrl);
        Assert.EndsWith(".png", (await LoadItemAsync(factory, alive2.Id)).OgImageUrl);
        Assert.NotNull((await LoadItemAsync(factory, dead.Id)).OgImageCacheFailedAt);
        Assert.Null((await LoadItemAsync(factory, flaky.Id)).OgImageCacheFailedAt); // geçici: yeniden denenecek

        // Tekrar çalıştırmak güvenli: yalnız geçici hatalı item yeniden denenir.
        factory.ImageHttpHandler.RespondWith("https://cdn.example.com/flaky.jpg", Jpeg);
        var rerun = await backfill.RunAsync(CancellationToken.None);
        Assert.Equal(1, rerun.Cached);
        Assert.Equal(0, rerun.MarkedFailed + rerun.TransientFailures);
        Assert.Equal(5, factory.ImageHttpHandler.Requests.Count);
        Assert.Equal("https://cdn.example.com/flaky.jpg", factory.ImageHttpHandler.Requests.Last().ToString());
        // Aynı bayt (alive.jpg ile) → aynı içerik adresli dosya.
        Assert.Equal((await LoadItemAsync(factory, alive.Id)).OgImageUrl, (await LoadItemAsync(factory, flaky.Id)).OgImageUrl);
    }

    // ---------------------------------------------------------------- yardımcılar

    private static async Task<ImageCacheResult> CacheAsync(SomineApiWebApplicationFactory factory, string url)
    {
        using var scope = factory.Services.CreateScope();
        var service = scope.ServiceProvider.GetRequiredService<IImageCacheService>();
        return await service.CacheAsync(url, CancellationToken.None);
    }

    private static OgImageCacheProcessor CreateProcessor(
        SomineApiWebApplicationFactory factory, RecordingUserRealtimeEventPublisher publisher)
        => new(
            factory.Services.GetRequiredService<IServiceScopeFactory>(),
            factory.Services.GetRequiredService<OgImageUrlPolicy>(),
            publisher,
            TimeProvider.System,
            NullLogger<OgImageCacheProcessor>.Instance);

    private static OgImageBackfillService CreateBackfill(SomineApiWebApplicationFactory factory)
        => new(
            factory.Services.GetRequiredService<IServiceScopeFactory>(),
            CreateProcessor(factory, new RecordingUserRealtimeEventPublisher()),
            factory.Services.GetRequiredService<OgImageUrlPolicy>(),
            Options.Create(new ImageCacheOptions
            {
                BackfillOnStartup = true,
                BackfillBatchSize = 2, // birden çok partiyi ve imleci sına
                BackfillItemDelay = TimeSpan.Zero
            }),
            NullLogger<OgImageBackfillService>.Instance);

    private static List<Guid> DrainQueue(SomineApiWebApplicationFactory factory)
    {
        var queue = factory.Services.GetRequiredService<IOgImageCacheQueue>();
        var ids = new List<Guid>();
        while (queue.TryRead(out var id)) ids.Add(id);
        return ids;
    }

    private static async Task<Item> LoadItemAsync(SomineApiWebApplicationFactory factory, Guid id)
    {
        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        return await db.Items.AsNoTracking().IgnoreQueryFilters().SingleAsync(i => i.Id == id);
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

    private static Item TestItem(Guid userId, string note) => new()
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
