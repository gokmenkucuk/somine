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

// App Store Guideline 1.2: şikâyet, engelleme ve kütüphaneden kaldırma uçları.
public class UgcModerationTests
{
    [Fact]
    public async Task ReportShare_RecipientCreatesOpenReportAgainstSender()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var sender = TestUser("report-sender");
        var recipient = TestUser("report-recipient");
        var category = TestCategory(sender.Id, "Reported");
        var share = TestShare(sender.Id, recipient.Id, category.Id, ShareStatus.Accepted);
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, recipient);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
        });

        using var client = factory.CreateAuthenticatedClient(recipient.Id, recipient.Email!, recipient.FirebaseUid);
        var response = await client.PostAsJsonAsync($"/api/shares/{share.Id}/report", new
        {
            reason = "inappropriate",
            note = "  offensive images  "
        });

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Inappropriate", body.GetProperty("reason").GetString());
        Assert.Equal("Open", body.GetProperty("status").GetString());

        // Aynı paylaşım için ikinci şikâyet yeni kayıt açmaz.
        var duplicate = await client.PostAsJsonAsync($"/api/shares/{share.Id}/report", new { reason = "spam" });
        Assert.Equal(HttpStatusCode.OK, duplicate.StatusCode);
        var duplicateBody = await duplicate.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(body.GetProperty("id").GetGuid(), duplicateBody.GetProperty("id").GetGuid());

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        var report = await db.ContentReports.SingleAsync();
        Assert.Equal(recipient.Id, report.ReporterId);
        Assert.Equal(sender.Id, report.ReportedUserId);
        Assert.Equal(share.Id, report.ShareId);
        Assert.Equal(category.Id, report.CategoryId);
        Assert.Equal(ReportReason.Inappropriate, report.Reason);
        Assert.Equal("offensive images", report.Note);
        Assert.Equal(ReportStatus.Open, report.Status);
    }

    [Fact]
    public async Task ReportShare_EmailsModeratorWithReasonPeopleAndLinks()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var sender = TestUser("alert-sender");
        var recipient = TestUser("alert-recipient");
        var category = TestCategory(sender.Id, "Alerted");
        var share = TestShare(sender.Id, recipient.Id, category.Id, ShareStatus.Accepted);
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, recipient);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
            db.Items.Add(new Item
            {
                Id = Guid.NewGuid(),
                UserId = sender.Id,
                CategoryId = category.Id,
                Url = "https://bad.example.com/page",
                OgTitle = "Bad page"
            });
        });

        using var client = factory.CreateAuthenticatedClient(recipient.Id, recipient.Email!, recipient.FirebaseUid);
        var response = await client.PostAsJsonAsync($"/api/shares/{share.Id}/report", new { reason = "harassment", note = "rude" });
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var reportId = (await response.Content.ReadFromJsonAsync<JsonElement>()).GetProperty("id").GetGuid();

        var email = await factory.ReportAlertSender.WaitForEmailAsync(TimeSpan.FromSeconds(10));
        Assert.Equal("moderator@example.com", email.To);
        Assert.StartsWith("[somine Şikayet] Taciz", email.Subject);
        Assert.Contains("rude", email.TextBody);
        Assert.Contains(sender.Id.ToString(), email.TextBody);
        Assert.Contains(recipient.Id.ToString(), email.TextBody);
        Assert.Contains("Alerted", email.TextBody);
        Assert.Contains("https://bad.example.com/page", email.TextBody);
        Assert.Contains(reportId.ToString(), email.TextBody);
        Assert.Contains($"WHERE id = '{share.Id}'", email.TextBody);
        Assert.NotNull(email.HtmlBody);
        Assert.Contains("cid:somine-logo", email.HtmlBody);
        Assert.Contains("href=\"https://bad.example.com/page\"", email.HtmlBody);
        Assert.Contains("rude", email.HtmlBody);
        Assert.Contains(reportId.ToString(), email.HtmlBody);

        // Aynı paylaşım için tekrar şikâyet yeni e-posta göndermez.
        await client.PostAsJsonAsync($"/api/shares/{share.Id}/report", new { reason = "spam" });
        await Task.Delay(300);
        Assert.Single(factory.ReportAlertSender.Sent);
    }

    [Fact]
    public async Task ReportShare_RejectsInvalidInputAndNonRecipients()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var sender = TestUser("invalid-sender");
        var recipient = TestUser("invalid-recipient");
        var stranger = TestUser("invalid-stranger");
        var category = TestCategory(sender.Id, "Collection");
        var share = TestShare(sender.Id, recipient.Id, category.Id, ShareStatus.Accepted);
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, recipient, stranger);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
        });

        using var recipientClient = factory.CreateAuthenticatedClient(recipient.Id, recipient.Email!, recipient.FirebaseUid);
        using var senderClient = factory.CreateAuthenticatedClient(sender.Id, sender.Email!, sender.FirebaseUid);
        using var strangerClient = factory.CreateAuthenticatedClient(stranger.Id, stranger.Email!, stranger.FirebaseUid);

        var badReason = await recipientClient.PostAsJsonAsync($"/api/shares/{share.Id}/report", new { reason = "boring" });
        var numericReason = await recipientClient.PostAsJsonAsync($"/api/shares/{share.Id}/report", new { reason = "7" });
        var missingReason = await recipientClient.PostAsJsonAsync($"/api/shares/{share.Id}/report", new { note = "x" });
        var longNote = await recipientClient.PostAsJsonAsync($"/api/shares/{share.Id}/report", new
        {
            reason = "other",
            note = new string('a', ContentReport.MaxNoteLength + 1)
        });
        var bySender = await senderClient.PostAsJsonAsync($"/api/shares/{share.Id}/report", new { reason = "spam" });
        var byStranger = await strangerClient.PostAsJsonAsync($"/api/shares/{share.Id}/report", new { reason = "spam" });

        Assert.Equal(HttpStatusCode.BadRequest, badReason.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, numericReason.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, missingReason.StatusCode);
        Assert.Equal(HttpStatusCode.BadRequest, longNote.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, bySender.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, byStranger.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        Assert.Equal(0, await db.ContentReports.CountAsync());
    }

    [Fact]
    public async Task BlockUser_RejectsIncomingSharesListsUserAndHidesBlockFromSender()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();
        factory.SubscriptionTierService.DefaultIsPremium = true;

        var blocker = TestUser("blocker");
        var blocked = TestUser("blocked");
        var bystander = TestUser("bystander");
        var acceptedCategory = TestCategory(blocked.Id, "Accepted from blocked");
        var pendingCategory = TestCategory(blocked.Id, "Pending from blocked");
        var blockerCategory = TestCategory(blocker.Id, "Blocker's own");
        var bystanderCategory = TestCategory(bystander.Id, "Bystander's");
        var acceptedShare = TestShare(blocked.Id, blocker.Id, acceptedCategory.Id, ShareStatus.Accepted);
        var pendingShare = TestShare(blocked.Id, blocker.Id, pendingCategory.Id, ShareStatus.Pending);
        var outgoingShare = TestShare(blocker.Id, blocked.Id, blockerCategory.Id, ShareStatus.Accepted);
        var bystanderShare = TestShare(bystander.Id, blocker.Id, bystanderCategory.Id, ShareStatus.Accepted);

        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(blocker, blocked, bystander);
            db.Categories.AddRange(acceptedCategory, pendingCategory, blockerCategory, bystanderCategory);
            db.CollectionShares.AddRange(acceptedShare, pendingShare, outgoingShare, bystanderShare);
        });

        using var blockerClient = factory.CreateAuthenticatedClient(blocker.Id, blocker.Email!, blocker.FirebaseUid);
        using var blockedClient = factory.CreateAuthenticatedClient(blocked.Id, blocked.Email!, blocked.FirebaseUid);

        var blockResponse = await blockerClient.PostAsync($"/api/users/{blocked.Id}/block", null);
        Assert.Equal(HttpStatusCode.NoContent, blockResponse.StatusCode);

        // İdempotent
        var secondBlock = await blockerClient.PostAsync($"/api/users/{blocked.Id}/block", null);
        Assert.Equal(HttpStatusCode.NoContent, secondBlock.StatusCode);

        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
            Assert.Equal(1, await db.UserBlocks.CountAsync());
            var shares = await db.CollectionShares.AsNoTracking().ToDictionaryAsync(s => s.Id);
            Assert.Equal(ShareStatus.Rejected, shares[acceptedShare.Id].Status);
            Assert.NotNull(shares[acceptedShare.Id].RejectedAt);
            Assert.Equal(ShareStatus.Rejected, shares[pendingShare.Id].Status);
            Assert.Equal(ShareStatus.Accepted, shares[outgoingShare.Id].Status);
            Assert.Equal(ShareStatus.Accepted, shares[bystanderShare.Id].Status);
        }

        // Engelleyen artık engellenenin koleksiyonunu göremez.
        var itemsResponse = await blockerClient.GetAsync($"/api/shares/{acceptedShare.Id}/items");
        Assert.Equal(HttpStatusCode.BadRequest, itemsResponse.StatusCode);

        var listResponse = await blockerClient.GetAsync("/api/users/blocked");
        Assert.Equal(HttpStatusCode.OK, listResponse.StatusCode);
        var list = await listResponse.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal(1, list.GetArrayLength());
        Assert.Equal(blocked.Id, list[0].GetProperty("userId").GetGuid());
        Assert.Equal(blocked.DisplayName, list[0].GetProperty("displayName").GetString());

        // Engellenen gönderen "kullanıcı bulunamadı" ile aynı cevabı alır.
        var newCategory = TestCategory(blocked.Id, "New try");
        await SeedAsync(factory, db => db.Categories.Add(newCategory));
        var byIdResponse = await blockedClient.PostAsJsonAsync("/api/shares", new
        {
            categoryId = newCategory.Id,
            toUserId = blocker.Id
        });
        var byEmailResponse = await blockedClient.PostAsJsonAsync("/api/shares", new
        {
            categoryId = newCategory.Id,
            toUserEmail = blocker.Email
        });
        var unknownResponse = await blockedClient.PostAsJsonAsync("/api/shares", new
        {
            categoryId = newCategory.Id,
            toUserId = Guid.NewGuid()
        });

        Assert.Equal(HttpStatusCode.NotFound, byIdResponse.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, byEmailResponse.StatusCode);
        Assert.Equal(unknownResponse.StatusCode, byIdResponse.StatusCode);
        Assert.Equal(
            await unknownResponse.Content.ReadAsStringAsync(),
            await byIdResponse.Content.ReadAsStringAsync());
        Assert.Equal(
            await unknownResponse.Content.ReadAsStringAsync(),
            await byEmailResponse.Content.ReadAsStringAsync());

        // Engel kaldırılınca paylaşım yeniden mümkün.
        var unblockResponse = await blockerClient.DeleteAsync($"/api/users/{blocked.Id}/block");
        Assert.Equal(HttpStatusCode.NoContent, unblockResponse.StatusCode);

        var afterUnblock = await blockedClient.PostAsJsonAsync("/api/shares", new
        {
            categoryId = newCategory.Id,
            toUserId = blocker.Id
        });
        Assert.Equal(HttpStatusCode.OK, afterUnblock.StatusCode);

        var emptyList = await blockerClient.GetFromJsonAsync<JsonElement>("/api/users/blocked");
        Assert.Equal(0, emptyList.GetArrayLength());
    }

    [Fact]
    public async Task BlockUser_SelfAndUnknownUserAreRejected()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("self-blocker");
        await SeedAsync(factory, db => db.Users.Add(user));

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var self = await client.PostAsync($"/api/users/{user.Id}/block", null);
        var unknown = await client.PostAsync($"/api/users/{Guid.NewGuid()}/block", null);
        var unblockUnknown = await client.DeleteAsync($"/api/users/{Guid.NewGuid()}/block");

        Assert.Equal(HttpStatusCode.BadRequest, self.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, unknown.StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, unblockUnknown.StatusCode);
    }

    [Fact]
    public async Task LeaveShare_RecipientLosesAccessAndOthersCannotLeave()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var sender = TestUser("leave-sender");
        var recipient = TestUser("leave-recipient");
        var category = TestCategory(sender.Id, "Leave me");
        var share = TestShare(sender.Id, recipient.Id, category.Id, ShareStatus.Accepted);
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, recipient);
            db.Categories.Add(category);
            db.CollectionShares.Add(share);
        });

        using var senderClient = factory.CreateAuthenticatedClient(sender.Id, sender.Email!, sender.FirebaseUid);
        using var recipientClient = factory.CreateAuthenticatedClient(recipient.Id, recipient.Email!, recipient.FirebaseUid);

        var bySender = await senderClient.PutAsync($"/api/shares/{share.Id}/leave", null);
        Assert.Equal(HttpStatusCode.NotFound, bySender.StatusCode);

        var leave = await recipientClient.PutAsync($"/api/shares/{share.Id}/leave", null);
        Assert.Equal(HttpStatusCode.NoContent, leave.StatusCode);

        var items = await recipientClient.GetAsync($"/api/shares/{share.Id}/items");
        Assert.Equal(HttpStatusCode.BadRequest, items.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        var stored = await db.CollectionShares.AsNoTracking().SingleAsync(s => s.Id == share.Id);
        Assert.Equal(ShareStatus.Rejected, stored.Status);
        // Gönderene bildirim gitmez.
        Assert.Equal(0, await db.Notifications.CountAsync());
    }

    [Fact]
    public async Task DeleteAccount_RemovesBlocksAndReports()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("deleting-user");
        var other = TestUser("other-user");
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(user, other);
            db.UserBlocks.Add(new UserBlock { BlockerId = user.Id, BlockedId = other.Id });
            db.UserBlocks.Add(new UserBlock { BlockerId = other.Id, BlockedId = user.Id });
            db.ContentReports.Add(new ContentReport
            {
                Id = Guid.NewGuid(),
                ReporterId = other.Id,
                ReportedUserId = user.Id,
                Reason = ReportReason.Spam
            });
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);
        var response = await client.DeleteAsync("/api/users/me");
        Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        Assert.Equal(0, await db.UserBlocks.CountAsync());
        Assert.Equal(0, await db.ContentReports.CountAsync());
    }

    private static async Task SeedAsync(SomineApiWebApplicationFactory factory, Action<SomineDbContext> seed)
    {
        using var scope = factory.Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        seed(dbContext);
        await dbContext.SaveChangesAsync();
    }

    [Fact]
    public async Task CreateShare_RejectsTargetWhoseFirebaseAccountWasDeleted()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var sender = TestUser("ghost-sender");
        var ghost = TestUser("ghost-target");
        var category = TestCategory(sender.Id, "To ghost");
        await SeedAsync(factory, db =>
        {
            db.Users.AddRange(sender, ghost);
            db.Categories.Add(category);
        });
        // Firebase hesabı silinmiş ama sunucuda kalmış kayıt.
        factory.FirebaseAuthService.DeletedFirebaseUids.Add(ghost.FirebaseUid);

        using var client = factory.CreateAuthenticatedClient(sender.Id, sender.Email!, sender.FirebaseUid);
        var byId = await client.PostAsJsonAsync("/api/shares", new { categoryId = category.Id, toUserId = ghost.Id });
        var byEmail = await client.PostAsJsonAsync("/api/shares", new { categoryId = category.Id, toUserEmail = ghost.Email });

        Assert.Equal(HttpStatusCode.NotFound, byId.StatusCode);
        Assert.Equal(HttpStatusCode.NotFound, byEmail.StatusCode);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        Assert.Equal(0, await db.CollectionShares.CountAsync());
        Assert.Equal(0, await db.Notifications.CountAsync());
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
