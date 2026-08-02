using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using SomineApi.Application;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using SomineApi.Tests.Testing;

namespace SomineApi.Tests.Integration;

public class ControllerIntegrationTests
{
    [Fact]
    public async Task CreateItem_FreeUserBelowLimitCreatesItemAndAtLimitReturnsLimitReached()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("items-owner");
        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.AddRange(Enumerable.Range(0, SubscriptionLimits.FreeMaxItems - 1)
                .Select(index => TestItem(user.Id, $"seed-{index}")));
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var createdResponse = await client.PostAsJsonAsync("/api/items", new
        {
            url = "https://example.com/created",
            note = "created below limit",
            type = ItemType.Link
        });

        Assert.Equal(HttpStatusCode.Created, createdResponse.StatusCode);

        var limitResponse = await client.PostAsJsonAsync("/api/items", new
        {
            url = "https://example.com/blocked",
            note = "blocked at limit",
            type = ItemType.Link
        });

        Assert.Equal(HttpStatusCode.Forbidden, limitResponse.StatusCode);
        await AssertErrorAsync(limitResponse, "limit_reached");
        await AssertItemCountAsync(factory, user.Id, SubscriptionLimits.FreeMaxItems);
    }

    [Fact]
    public async Task CreateShare_FreeUserWithOneActiveShareReturnsLimitReached()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var sender = TestUser("share-sender");
        var existingRecipient = TestUser("existing-recipient");
        var newRecipient = TestUser("new-recipient");
        var category = TestCategory(sender.Id, "Shared collection");
        var existingShare = TestShare(sender.Id, existingRecipient.Id, category.Id, ShareStatus.Pending);

        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, existingRecipient, newRecipient);
            db.Categories.Add(category);
            db.CollectionShares.Add(existingShare);
        });

        using var client = factory.CreateAuthenticatedClient(sender.Id, sender.Email!, sender.FirebaseUid);

        var response = await client.PostAsJsonAsync("/api/shares", new
        {
            categoryId = category.Id,
            toUserId = newRecipient.Id
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        await AssertErrorAsync(response, "limit_reached");
    }

    [Fact]
    public async Task GetShareItems_AllowsSenderAndAcceptedRecipientButHidesFromThirdUserAndRejectsPendingRecipient()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var sender = TestUser("share-items-sender");
        var acceptedRecipient = TestUser("accepted-recipient");
        var pendingRecipient = TestUser("pending-recipient");
        var thirdUser = TestUser("third-user");
        var acceptedCategory = TestCategory(sender.Id, "Accepted collection");
        var pendingCategory = TestCategory(sender.Id, "Pending collection");
        var acceptedShare = TestShare(sender.Id, acceptedRecipient.Id, acceptedCategory.Id, ShareStatus.Accepted);
        var pendingShare = TestShare(sender.Id, pendingRecipient.Id, pendingCategory.Id, ShareStatus.Pending);

        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, acceptedRecipient, pendingRecipient, thirdUser);
            db.Categories.AddRange(acceptedCategory, pendingCategory);
            db.CollectionShares.AddRange(acceptedShare, pendingShare);
            db.Items.AddRange(
                TestItem(sender.Id, "visible-1", acceptedCategory.Id),
                TestItem(sender.Id, "visible-2", acceptedCategory.Id),
                TestItem(sender.Id, "pending", pendingCategory.Id));
        });

        using var senderClient = factory.CreateAuthenticatedClient(sender.Id, sender.Email!, sender.FirebaseUid);
        using var acceptedClient = factory.CreateAuthenticatedClient(acceptedRecipient.Id, acceptedRecipient.Email!, acceptedRecipient.FirebaseUid);
        using var thirdClient = factory.CreateAuthenticatedClient(thirdUser.Id, thirdUser.Email!, thirdUser.FirebaseUid);
        using var pendingClient = factory.CreateAuthenticatedClient(pendingRecipient.Id, pendingRecipient.Email!, pendingRecipient.FirebaseUid);

        var senderResponse = await senderClient.GetAsync($"/api/shares/{acceptedShare.Id}/items");
        var acceptedResponse = await acceptedClient.GetAsync($"/api/shares/{acceptedShare.Id}/items");
        var thirdResponse = await thirdClient.GetAsync($"/api/shares/{acceptedShare.Id}/items");
        var pendingResponse = await pendingClient.GetAsync($"/api/shares/{pendingShare.Id}/items");

        Assert.Equal(HttpStatusCode.OK, senderResponse.StatusCode);
        Assert.Equal(HttpStatusCode.OK, acceptedResponse.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, thirdResponse.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, pendingResponse.StatusCode);

        var acceptedItems = await acceptedResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(2, acceptedItems.GetArrayLength());
        await AssertErrorAsync(thirdResponse, "Share not found");
        await AssertErrorAsync(pendingResponse, "Share is not accepted");
    }

    [Fact]
    public async Task CreateReminder_FreeUserWithThreeActiveRemindersReturnsLimitReached()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("reminder-owner");
        var targetItem = TestItem(user.Id, "target-reminder");
        var existingItems = Enumerable.Range(0, SubscriptionLimits.FreeMaxActiveReminders)
            .Select(index => TestItem(user.Id, $"reminder-seed-{index}"))
            .ToList();
        var existingReminders = existingItems
            .Select(item => TestReminder(item.Id))
            .ToList();

        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(targetItem);
            db.Items.AddRange(existingItems);
            db.Reminders.AddRange(existingReminders);

            foreach (var pair in existingItems.Zip(existingReminders))
            {
                pair.First.HasReminder = true;
                pair.First.ReminderId = pair.Second.Id;
            }
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var response = await client.PostAsJsonAsync("/api/reminders", new
        {
            itemId = targetItem.Id,
            reminderDate = DateOnly.FromDateTime(DateTime.UtcNow.Date.AddDays(1)),
            reminderHour = 9,
            reminderMinute = 30,
            repeatType = RepeatFrequency.None
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
        await AssertErrorAsync(response, "limit_reached");
    }

    [Fact]
    public async Task LoginWithGoogle_SameUidTwiceSequentiallyReturnsOkAndCreatesSingleUser()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        const string firebaseUid = "firebase-sequential-login";
        factory.FirebaseAuthService.UserInfo = new FirebaseUserInfo(
            firebaseUid, "sequential-login@somine.test", "Sequential Login", null);

        using var client = CreateLoginClient(factory);

        var firstResponse = await client.PostAsJsonAsync("/api/auth/google", new { idToken = "token-1" });
        var secondResponse = await client.PostAsJsonAsync("/api/auth/google", new { idToken = "token-2" });

        Assert.Equal(HttpStatusCode.OK, firstResponse.StatusCode);
        Assert.Equal(HttpStatusCode.OK, secondResponse.StatusCode);

        var firstUserId = await ReadUserIdAsync(firstResponse);
        var secondUserId = await ReadUserIdAsync(secondResponse);
        Assert.Equal(firstUserId, secondUserId);

        await AssertUserCountAsync(factory, firebaseUid, 1);
    }

    [Fact]
    public async Task LoginWithGoogle_ParallelRequestsWithSameUidBothSucceedWithSingleUser()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        const string firebaseUid = "firebase-parallel-login";
        factory.FirebaseAuthService.UserInfo = new FirebaseUserInfo(
            firebaseUid, "parallel-login@somine.test", "Parallel Login", null);

        using var client = CreateLoginClient(factory);

        var responses = await Task.WhenAll(
            client.PostAsJsonAsync("/api/auth/google", new { idToken = "parallel-token-1" }),
            client.PostAsJsonAsync("/api/auth/google", new { idToken = "parallel-token-2" }));

        Assert.All(responses, response => Assert.Equal(HttpStatusCode.OK, response.StatusCode));

        var userIds = await Task.WhenAll(responses.Select(ReadUserIdAsync));
        Assert.Equal(userIds[0], userIds[1]);

        await AssertUserCountAsync(factory, firebaseUid, 1);
    }

    [Fact]
    public async Task LoginWithGoogle_WhenConcurrentRequestWinsInsertRaceReusesExistingUser()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var winner = TestUser("race-winner");
        factory.FirebaseAuthService.UserInfo = new FirebaseUserInfo(
            winner.FirebaseUid, winner.Email, winner.DisplayName, null);

        // Yarışı kaybeden isteği deterministik simüle et: istek kullanıcıyı bulamayıp
        // INSERT'e giderken, SaveChanges'ten hemen önce kazanan istek aynı
        // firebase_uid'li satırı yazar → unique ihlali → recovery yolu.
        factory.SaveChangesHook.OnSavingNewUserAsync = () =>
            SeedAsync(factory, db => db.Users.Add(winner));

        using var client = CreateLoginClient(factory);

        var response = await client.PostAsJsonAsync("/api/auth/google", new { idToken = "race-token" });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        Assert.Equal(winner.Id, await ReadUserIdAsync(response));
        await AssertUserCountAsync(factory, winner.FirebaseUid, 1);
    }

    [Fact]
    public async Task MarkItemOpened_ReturnsNoContentAndUpdatesTrackingFields()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("opened-owner");
        var item = TestItem(user.Id, "opened-item");
        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(item);
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var response = await client.PostAsync($"/api/items/{item.Id}/opened", null);

        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        using var scope = factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        var updated = await dbContext.Items.SingleAsync(i => i.Id == item.Id);
        Assert.NotNull(updated.LastOpenedAt);
        Assert.Equal(1, updated.OpenCount);
    }

    [Fact]
    public async Task MarkItemOpened_ReturnsNotFoundForOtherUsersItemAndSoftDeletedItem()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var owner = TestUser("opened-victim");
        var otherUser = TestUser("opened-intruder");
        var item = TestItem(owner.Id, "victim-item");
        var deletedItem = TestItem(owner.Id, "deleted-item");
        deletedItem.IsDeleted = true;
        deletedItem.DeletedAt = DateTime.UtcNow;

        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(owner, otherUser);
            db.Items.AddRange(item, deletedItem);
        });

        using var intruderClient = factory.CreateAuthenticatedClient(otherUser.Id, otherUser.Email!, otherUser.FirebaseUid);
        using var ownerClient = factory.CreateAuthenticatedClient(owner.Id, owner.Email!, owner.FirebaseUid);

        var intruderResponse = await intruderClient.PostAsync($"/api/items/{item.Id}/opened", null);
        var deletedResponse = await ownerClient.PostAsync($"/api/items/{deletedItem.Id}/opened", null);

        Assert.Equal(HttpStatusCode.NotFound, intruderResponse.StatusCode);
        await AssertErrorAsync(intruderResponse, "Item not found");
        Assert.Equal(HttpStatusCode.NotFound, deletedResponse.StatusCode);
        await AssertErrorAsync(deletedResponse, "Item not found");

        using var scope = factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        var untouched = await dbContext.Items.SingleAsync(i => i.Id == item.Id);
        Assert.Null(untouched.LastOpenedAt);
        Assert.Equal(0, untouched.OpenCount);
    }

    [Fact]
    public async Task MarkItemOpened_CalledTwiceIncrementsOpenCountToTwo()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("opened-twice");
        var item = TestItem(user.Id, "opened-twice-item");
        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(item);
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var firstResponse = await client.PostAsync($"/api/items/{item.Id}/opened", null);
        var secondResponse = await client.PostAsync($"/api/items/{item.Id}/opened", null);

        Assert.Equal(HttpStatusCode.NoContent, firstResponse.StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, secondResponse.StatusCode);

        using var scope = factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        var updated = await dbContext.Items.SingleAsync(i => i.Id == item.Id);
        Assert.Equal(2, updated.OpenCount);
        Assert.NotNull(updated.LastOpenedAt);
    }

    private static HttpClient CreateLoginClient(SomineApiWebApplicationFactory factory)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-SoMine-Api-Key", SomineApiWebApplicationFactory.ApiKey);
        return client;
    }

    private static async Task<Guid> ReadUserIdAsync(HttpResponseMessage response)
    {
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        return body.GetProperty("user").GetProperty("id").GetGuid();
    }

    private static async Task AssertUserCountAsync(
        SomineApiWebApplicationFactory factory,
        string firebaseUid,
        int expectedCount)
    {
        using var scope = factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        var count = await dbContext.Users.CountAsync(user => user.FirebaseUid == firebaseUid);
        Assert.Equal(expectedCount, count);
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

    private static CollectionShare TestShare(
        Guid fromUserId,
        Guid toUserId,
        Guid categoryId,
        ShareStatus status)
    {
        return new CollectionShare
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

    private static Reminder TestReminder(Guid itemId)
    {
        return new Reminder
        {
            Id = Guid.NewGuid(),
            ItemId = itemId,
            ReminderDate = DateOnly.FromDateTime(DateTime.UtcNow.Date.AddDays(1)),
            ReminderHour = 8,
            ReminderMinute = 0,
            RepeatType = RepeatFrequency.None,
            IsActive = true,
            CreatedAt = DateTime.UtcNow
        };
    }

    private static async Task AssertErrorAsync(HttpResponseMessage response, string expectedError)
    {
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("error", out var error), "Response body did not include an error property.");
        Assert.Equal(expectedError, error.GetString());
    }

    private static async Task AssertItemCountAsync(
        SomineApiWebApplicationFactory factory,
        Guid userId,
        int expectedCount)
    {
        using var scope = factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        var count = await dbContext.Items.CountAsync(item => item.UserId == userId);
        Assert.Equal(expectedCount, count);
    }
}
