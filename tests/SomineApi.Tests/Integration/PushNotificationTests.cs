using System.Net;
using System.Net.Http.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Domain.Notifications;
using SomineApi.Infrastructure.Data;
using SomineApi.Tests.Testing;
using SomineApi.WebApi.Push;

namespace SomineApi.Tests.Integration;

// Uzak bildirim (FCM push): cihaz token uçları ve paylaşım bildirimlerinin push'a dönüşmesi.
public class PushNotificationTests
{
    private static readonly TimeSpan Timeout = TimeSpan.FromSeconds(10);

    [Fact]
    public async Task RegisterDeviceToken_UpsertsAndMovesTokenBetweenAccounts()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var first = TestUser("token-first");
        var second = TestUser("token-second");
        await SeedAsync(factory, db => db.Users.AddRange(first, second));

        using var firstClient = factory.CreateAuthenticatedClient(first.Id, first.Email!, first.FirebaseUid);
        using var secondClient = factory.CreateAuthenticatedClient(second.Id, second.Email!, second.FirebaseUid);

        var created = await firstClient.PutAsJsonAsync("/api/users/me/device-token", new { token = " fcm-token-1 ", platform = "iOS", locale = "tr" });
        Assert.Equal(HttpStatusCode.NoContent, created.StatusCode);

        // Aynı token yeniden bildirilince yeni satır açılmaz; dil güncellenir.
        var refreshed = await firstClient.PutAsJsonAsync("/api/users/me/device-token", new { token = "fcm-token-1", platform = "ios", locale = "en" });
        Assert.Equal(HttpStatusCode.NoContent, refreshed.StatusCode);

        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
            var token = await db.DeviceTokens.SingleAsync();
            Assert.Equal(first.Id, token.UserId);
            Assert.Equal("fcm-token-1", token.Token);
            Assert.Equal("ios", token.Platform);
            Assert.Equal("en", token.Locale);
        }

        // Aynı cihazda başka hesapla oturum açılınca token yeni hesaba taşınır.
        var moved = await secondClient.PutAsJsonAsync("/api/users/me/device-token", new { token = "fcm-token-1", platform = "ios", locale = "tr" });
        Assert.Equal(HttpStatusCode.NoContent, moved.StatusCode);

        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
            var token = await db.DeviceTokens.SingleAsync();
            Assert.Equal(second.Id, token.UserId);
            Assert.Equal("tr", token.Locale);
        }

        var empty = await firstClient.PutAsJsonAsync("/api/users/me/device-token", new { token = "  " });
        var tooLong = await firstClient.PutAsJsonAsync("/api/users/me/device-token", new { token = new string('a', DeviceToken.MaxTokenLength + 1) });
        Assert.Equal(HttpStatusCode.BadRequest, empty.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, tooLong.StatusCode);
    }

    [Fact]
    public async Task UnregisterDeviceToken_RemovesOnlyCallersToken()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("unregister-owner");
        var other = TestUser("unregister-other");
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(owner, other);
            db.DeviceTokens.AddRange(TestToken(owner.Id, "owner-token"), TestToken(other.Id, "other-token"));
        });

        using var ownerClient = factory.CreateAuthenticatedClient(owner.Id, owner.Email!, owner.FirebaseUid);

        // Başkasının token'ını silmeye çalışmak etkisizdir.
        var foreign = await ownerClient.SendAsync(DeleteTokenRequest("other-token"));
        var own = await ownerClient.SendAsync(DeleteTokenRequest("owner-token"));
        var again = await ownerClient.SendAsync(DeleteTokenRequest("owner-token"));

        Assert.Equal(HttpStatusCode.NoContent, foreign.StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, own.StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, again.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        var remaining = await db.DeviceTokens.SingleAsync();
        Assert.Equal("other-token", remaining.Token);
    }

    [Fact]
    public async Task CreateShare_PushesLocalizedRequestToEveryRecipientDevice()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();
        factory.SubscriptionTierService.DefaultIsPremium = true;

        var sender = TestUser("push-sender");
        sender.DisplayName = "Ayşe";
        var recipient = TestUser("push-recipient");
        var category = TestCategory(sender.Id, "Tarifler");
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, recipient);
            db.Categories.Add(category);
            db.DeviceTokens.AddRange(
                TestToken(recipient.Id, "recipient-tr", "tr"),
                TestToken(recipient.Id, "recipient-en", "en-US"),
                TestToken(sender.Id, "sender-device", "tr"));
        });

        using var client = factory.CreateAuthenticatedClient(sender.Id, sender.Email!, sender.FirebaseUid);
        var response = await client.PostAsJsonAsync("/api/shares", new { toUserId = recipient.Id, categoryId = category.Id });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        await factory.PushNotificationSender.WaitForSendAsync(Timeout);

        Guid shareId;
        Guid notificationId;
        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
            shareId = (await db.CollectionShares.SingleAsync()).Id;
            notificationId = (await db.Notifications.SingleAsync()).Id;
        }

        var sent = factory.PushNotificationSender.Sent;
        Assert.Equal(2, sent.Count);
        Assert.DoesNotContain(sent, m => m.Token == "sender-device");

        var tr = sent.Single(m => m.Token == "recipient-tr");
        Assert.Equal("Yeni Paylaşım İsteği", tr.Title);
        Assert.Equal("Ayşe \"Tarifler\" koleksiyonunu sizinle paylaşmak istiyor.", tr.Body);

        var en = sent.Single(m => m.Token == "recipient-en");
        Assert.Equal("New Share Request", en.Title);
        Assert.Equal("Ayşe wants to share the \"Tarifler\" collection with you.", en.Body);

        Assert.Equal(NotificationTypes.ShareRequest, tr.Data["type"]);
        Assert.Equal(notificationId.ToString(), tr.Data["notificationId"]);
        Assert.Equal(shareId.ToString(), tr.Data["shareId"]);
        Assert.Equal(category.Id.ToString(), tr.Data["categoryId"]);
        Assert.Equal(sender.Id.ToString(), tr.Data["fromUserId"]);
        Assert.Equal("Tarifler", tr.Data["categoryName"]);
    }

    [Theory]
    [InlineData("accept", NotificationTypes.ShareAccepted, "Paylaşım Kabul Edildi", "Share Accepted")]
    [InlineData("reject", NotificationTypes.ShareRejected, "Paylaşım Reddedildi", "Share Rejected")]
    public async Task RespondToShare_PushesResultToSender(string action, string type, string trTitle, string enTitle)
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var sender = TestUser($"respond-sender-{action}");
        var recipient = TestUser($"respond-recipient-{action}");
        var category = TestCategory(sender.Id, "Kitaplar");
        var share = TestShare(sender.Id, recipient.Id, category.Id, ShareStatus.Pending);
        share.CategoryName = "Kitaplar";
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, recipient);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
            db.DeviceTokens.AddRange(
                TestToken(sender.Id, "sender-tr", "tr-TR"),
                TestToken(sender.Id, "sender-en", "en"),
                TestToken(recipient.Id, "recipient-device", "tr"));
        });

        using var client = factory.CreateAuthenticatedClient(recipient.Id, recipient.Email!, recipient.FirebaseUid);
        var response = await client.PutAsync($"/api/shares/{share.Id}/{action}", null);
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        await factory.PushNotificationSender.WaitForSendAsync(Timeout);

        var sent = factory.PushNotificationSender.Sent;
        Assert.Equal(2, sent.Count);
        Assert.DoesNotContain(sent, m => m.Token == "recipient-device");

        var tr = sent.Single(m => m.Token == "sender-tr");
        var en = sent.Single(m => m.Token == "sender-en");
        Assert.Equal(trTitle, tr.Title);
        Assert.EndsWith(": Kitaplar", tr.Body);
        Assert.Equal(enTitle, en.Title);
        Assert.EndsWith(": Kitaplar", en.Body);
        Assert.Equal(type, en.Data["type"]);
        Assert.Equal(share.Id.ToString(), en.Data["shareId"]);
        Assert.Equal(category.Id.ToString(), en.Data["categoryId"]);
    }

    [Fact]
    public async Task Push_RemovesTokensThatFcmReportsAsUnregistered()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var sender = TestUser("invalid-token-sender");
        var recipient = TestUser("invalid-token-recipient");
        var category = TestCategory(sender.Id, "Collection");
        var share = TestShare(sender.Id, recipient.Id, category.Id, ShareStatus.Pending);
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, recipient);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
            db.DeviceTokens.AddRange(TestToken(sender.Id, "stale-token"), TestToken(sender.Id, "live-token"));
        });
        factory.PushNotificationSender.InvalidTokens.Add("stale-token");

        using var client = factory.CreateAuthenticatedClient(recipient.Id, recipient.Email!, recipient.FirebaseUid);
        var response = await client.PutAsync($"/api/shares/{share.Id}/accept", null);
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        await factory.PushNotificationSender.WaitForSendAsync(Timeout);

        await WaitUntilAsync(factory, async db => !await db.DeviceTokens.AnyAsync(t => t.Token == "stale-token"));

        using var scope = factory.Services.CreateScope();
        var verifyDb = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        Assert.Equal("live-token", (await verifyDb.DeviceTokens.SingleAsync()).Token);
    }

    [Fact]
    public async Task PushFailure_NeverFailsTheShareRequest()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();
        factory.PushNotificationSender.ThrowOnSend = new InvalidOperationException("FCM down");

        var sender = TestUser("failing-sender");
        var recipient = TestUser("failing-recipient");
        var category = TestCategory(sender.Id, "Collection");
        var share = TestShare(sender.Id, recipient.Id, category.Id, ShareStatus.Pending);
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, recipient);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
            db.DeviceTokens.Add(TestToken(sender.Id, "sender-token"));
        });

        using var client = factory.CreateAuthenticatedClient(recipient.Id, recipient.Email!, recipient.FirebaseUid);
        var response = await client.PutAsync($"/api/shares/{share.Id}/reject", null);
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        await factory.PushNotificationSender.WaitForSendAsync(Timeout);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        Assert.Equal(ShareStatus.Rejected, (await db.CollectionShares.SingleAsync()).Status);
        Assert.Equal(1, await db.Notifications.CountAsync());
        // Geçici hata token'ı silmez.
        Assert.Equal(1, await db.DeviceTokens.CountAsync());
    }

    [Fact]
    public async Task Push_IsSkippedWhenSenderIsNotConfigured()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();
        factory.PushNotificationSender.IsConfigured = false;

        var recipient = TestUser("unconfigured-recipient");
        await SeedAsync(factory, db =>
        {
            db.Users.Add(recipient);
            db.DeviceTokens.Add(TestToken(recipient.Id, "unconfigured-token"));
        });

        var service = factory.Services.GetServices<Microsoft.Extensions.Hosting.IHostedService>()
            .OfType<PushNotificationBackgroundService>()
            .Single();

        var request = new PushNotificationRequest(recipient.Id, NotificationTypes.ShareAccepted,
            new Dictionary<string, string> { ["type"] = NotificationTypes.ShareAccepted, ["categoryName"] = "X" });
        await service.ProcessAsync(request);

        Assert.Empty(factory.PushNotificationSender.Sent);
    }

    [Fact]
    public async Task DeleteAccount_RemovesDeviceTokens()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("delete-tokens");
        var other = TestUser("delete-tokens-other");
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(user, other);
            db.DeviceTokens.AddRange(TestToken(user.Id, "delete-a"), TestToken(user.Id, "delete-b"), TestToken(other.Id, "keep"));
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);
        var response = await client.DeleteAsync("/api/users/me");
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        Assert.Equal("keep", (await db.DeviceTokens.SingleAsync()).Token);
    }

    [Theory]
    [InlineData(null, true)]
    [InlineData("tr", true)]
    [InlineData("tr-TR", true)]
    [InlineData("en", false)]
    [InlineData("de", false)]
    public void PushTexts_FallBackToTurkishOnlyWhenLocaleIsUnknown(string? locale, bool expectTurkish)
    {
        Assert.Equal(expectTurkish, PushNotificationTexts.IsTurkish(locale));
    }

    [Fact]
    public void PushTexts_ReturnNullForReminders()
    {
        // Hatırlatıcılar cihazda yerel olarak planlanır; sunucu push'u çift uyarı üretirdi.
        var request = new PushNotificationRequest(Guid.NewGuid(), NotificationTypes.Reminder, new Dictionary<string, string>());
        Assert.Null(PushNotificationTexts.Build(request, "tr"));
    }

    private static HttpRequestMessage DeleteTokenRequest(string token) => new(HttpMethod.Delete, "/api/users/me/device-token")
    {
        Content = JsonContent.Create(new { token })
    };

    private static async Task WaitUntilAsync(SomineApiWebApplicationFactory factory, Func<SomineDbContext, Task<bool>> condition)
    {
        var deadline = DateTime.UtcNow + Timeout;
        while (true)
        {
            using (var scope = factory.Services.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
                if (await condition(db)) return;
            }

            if (DateTime.UtcNow > deadline) throw new TimeoutException("Condition was not met in time.");
            await Task.Delay(50);
        }
    }

    private static async Task SeedAsync(SomineApiWebApplicationFactory factory, Action<SomineDbContext> seed)
    {
        using var scope = factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        seed(dbContext);
        await dbContext.SaveChangesAsync();
    }

    private static DeviceToken TestToken(Guid userId, string token, string? locale = "tr") => new()
    {
        Id = Guid.NewGuid(),
        UserId = userId,
        Token = token,
        Platform = "ios",
        Locale = locale,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow,
        LastSeenAt = DateTime.UtcNow
    };

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
