using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;
using Microsoft.Extensions.Options;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Domain.Notifications;
using SomineApi.Infrastructure.Data;
using SomineApi.Tests.Testing;
using SomineApi.WebApi.Options;
using SomineApi.WebApi.Reminders;

namespace SomineApi.Tests.Integration;

// Vakti gelen hatırlatıcı → uygulama içi bildirim (ReminderNotificationBackgroundService).
public class ReminderNotificationTests
{
    // Sabit referans an: 2026-08-10 09:00 İstanbul = 06:00 UTC
    private static readonly DateTimeOffset NowUtc = new(2026, 8, 10, 6, 0, 0, TimeSpan.Zero);

    [Fact]
    public async Task DueReminder_CreatesSingleNotification_AndIsIdempotentOnSecondSweep()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("reminder-due");
        var item = TestItem(user.Id, "Okunacak yazı");
        item.OgTitle = "pgvector ile semantik arama";
        var reminder = TestReminder(item.Id, new DateOnly(2026, 8, 10), 9, 0, RepeatFrequency.None);

        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(item);
            db.Reminders.Add(reminder);
        });

        var publisher = new RecordingUserRealtimeEventPublisher();
        var service = CreateService(factory, publisher);

        var created = await service.RunOnceAsync(NowUtc);
        Assert.Equal(1, created);

        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();

            var notification = await db.Notifications.SingleAsync();
            Assert.Equal(user.Id, notification.UserId);
            Assert.Equal(NotificationTypes.Reminder, notification.Type);
            Assert.True(notification.Type.Length <= NotificationTypes.MaxLength);
            Assert.Equal("pgvector ile semantik arama", notification.Title);
            Assert.False(notification.IsRead);

            var data = notification.Data!.RootElement;
            Assert.Equal(item.Id, data.GetProperty("itemId").GetGuid());
            Assert.Equal(reminder.Id, data.GetProperty("reminderId").GetGuid());
            Assert.True(data.TryGetProperty("triggeredForUtc", out _));

            var stored = await db.Reminders.SingleAsync();
            Assert.NotNull(stored.LastTriggered);
        }

        Assert.Single(publisher.NotificationEvents);
        Assert.True(publisher.NotificationEvents.TryDequeue(out var evt));
        Assert.Equal(user.Id, evt.UserId);
        Assert.Equal("created", evt.Action);

        // İkinci tur: aynı slot için tekrar bildirim üretilmemeli.
        var secondSweep = await service.RunOnceAsync(NowUtc.AddMinutes(1));
        Assert.Equal(0, secondSweep);

        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
            Assert.Equal(1, await db.Notifications.CountAsync());
        }

        Assert.Empty(publisher.NotificationEvents);
    }

    [Fact]
    public async Task InactiveReminder_IsNeverTriggered()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("reminder-inactive");
        var item = TestItem(user.Id, "Pasif");
        var reminder = TestReminder(item.Id, new DateOnly(2026, 8, 10), 9, 0, RepeatFrequency.None);
        reminder.IsActive = false;

        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(item);
            db.Reminders.Add(reminder);
        });

        var publisher = new RecordingUserRealtimeEventPublisher();
        var service = CreateService(factory, publisher);

        Assert.Equal(0, await service.RunOnceAsync(NowUtc));

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        Assert.Empty(await db.Notifications.ToListAsync());
        Assert.Null((await db.Reminders.SingleAsync()).LastTriggered);
        Assert.Empty(publisher.NotificationEvents);
    }

    [Fact]
    public async Task FutureReminder_IsNotTriggeredYet()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("reminder-future");
        var item = TestItem(user.Id, "Gelecek");
        // 10:00 İstanbul = 07:00 UTC → referans an 06:00 UTC'de henüz vakti gelmemiş
        var reminder = TestReminder(item.Id, new DateOnly(2026, 8, 10), 10, 0, RepeatFrequency.None);

        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(item);
            db.Reminders.Add(reminder);
        });

        var service = CreateService(factory, new RecordingUserRealtimeEventPublisher());

        Assert.Equal(0, await service.RunOnceAsync(NowUtc));
        Assert.Equal(1, await service.RunOnceAsync(NowUtc.AddHours(1)));
    }

    [Fact]
    public async Task DailyReminder_TriggersAgainOnTheNextDaySlot()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("reminder-daily");
        var item = TestItem(user.Id, "Her gün");
        var reminder = TestReminder(item.Id, new DateOnly(2026, 8, 10), 9, 0, RepeatFrequency.Daily);

        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(item);
            db.Reminders.Add(reminder);
        });

        var service = CreateService(factory, new RecordingUserRealtimeEventPublisher());

        Assert.Equal(1, await service.RunOnceAsync(NowUtc));
        Assert.Equal(0, await service.RunOnceAsync(NowUtc.AddHours(5)));
        Assert.Equal(1, await service.RunOnceAsync(NowUtc.AddDays(1)));

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        Assert.Equal(2, await db.Notifications.CountAsync());
    }

    [Fact]
    public async Task StaleReminderOutsideCatchUpWindow_IsSkipped()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("reminder-stale");
        var item = TestItem(user.Id, "Çok eski");
        var reminder = TestReminder(item.Id, new DateOnly(2026, 1, 1), 9, 0, RepeatFrequency.None);

        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(item);
            db.Reminders.Add(reminder);
        });

        var service = CreateService(factory, new RecordingUserRealtimeEventPublisher());

        Assert.Equal(0, await service.RunOnceAsync(NowUtc));
    }

    [Fact]
    public async Task UserTimeZone_ShiftsTheTriggerInstant()
    {
        // Kullanıcı UTC'de → 09:00 yerel = 09:00 UTC, İstanbul'a göre 3 saat sonra tetiklenmeli.
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("reminder-utc-tz");
        user.TimeZoneId = "UTC";
        var item = TestItem(user.Id, "UTC kullanıcısı");
        var reminder = TestReminder(item.Id, new DateOnly(2026, 8, 10), 9, 0, RepeatFrequency.None);

        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(item);
            db.Reminders.Add(reminder);
        });

        var service = CreateService(factory, new RecordingUserRealtimeEventPublisher());

        Assert.Equal(0, await service.RunOnceAsync(NowUtc));            // 06:00 UTC
        Assert.Equal(1, await service.RunOnceAsync(NowUtc.AddHours(3))); // 09:00 UTC
    }

    [Fact]
    public async Task Disabled_DoesNothing()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("reminder-disabled");
        var item = TestItem(user.Id, "Kapalı");
        var reminder = TestReminder(item.Id, new DateOnly(2026, 8, 10), 9, 0, RepeatFrequency.None);

        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(item);
            db.Reminders.Add(reminder);
        });

        var service = CreateService(factory, new RecordingUserRealtimeEventPublisher(), enabled: false);

        // Enabled bayrağı ExecuteAsync'i durdurur; hosted service olarak çalışmadığında hiçbir şey yapmaz.
        await service.StartAsync(CancellationToken.None);
        await service.StopAsync(CancellationToken.None);

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        Assert.Empty(await db.Notifications.ToListAsync());
    }

    [Fact]
    public void TestHost_RemovesReminderNotificationBackgroundService()
    {
        using var factory = new SomineApiWebApplicationFactory();
        var hostedServices = factory.Services.GetServices<IHostedService>();
        Assert.DoesNotContain(hostedServices, service => service is ReminderNotificationBackgroundService);
    }

    [Fact]
    public void NotificationTitle_FallsBackFromOgTitleToNoteToUrl()
    {
        Assert.Equal("OG", ReminderNotificationBackgroundService.BuildNotificationTitle("OG", "note", "https://x"));
        Assert.Equal("note", ReminderNotificationBackgroundService.BuildNotificationTitle("  ", "note", "https://x"));
        Assert.Equal("https://x", ReminderNotificationBackgroundService.BuildNotificationTitle(null, null, "https://x"));
        Assert.Equal("Hatırlatıcı", ReminderNotificationBackgroundService.BuildNotificationTitle(null, "   ", null));
        Assert.Equal("ilk satır", ReminderNotificationBackgroundService.BuildNotificationTitle(null, "ilk satır\nikinci satır", null));

        var longTitle = ReminderNotificationBackgroundService.BuildNotificationTitle(new string('a', 400), null, null);
        Assert.True(longTitle.Length <= 200);
        Assert.EndsWith("…", longTitle);
    }

    [Fact]
    public async Task ReminderDto_ExposesLastTriggeredAndNextTriggerAtUtc()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("reminder-dto");
        var item = TestItem(user.Id, "DTO");
        var reminder = TestReminder(item.Id, DateOnly.FromDateTime(DateTime.UtcNow.Date.AddDays(1)), 9, 0, RepeatFrequency.Daily);

        await SeedAsync(factory, db =>
        {
            db.Users.Add(user);
            db.Items.Add(item);
            db.Reminders.Add(reminder);
        });

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var response = await client.GetAsync("/api/reminders");
        response.EnsureSuccessStatusCode();

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        var dto = body.EnumerateArray().Single();

        Assert.Equal(JsonValueKind.Null, dto.GetProperty("lastTriggered").ValueKind);
        Assert.Equal(JsonValueKind.String, dto.GetProperty("nextTriggerAtUtc").ValueKind);
        Assert.True(dto.GetProperty("nextTriggerAtUtc").GetDateTimeOffset() > DateTimeOffset.UtcNow);
    }

    [Fact]
    public async Task UpdateUser_AcceptsTimeZoneId()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var user = TestUser("reminder-tz-update");
        await SeedAsync(factory, db => db.Users.Add(user));

        using var client = factory.CreateAuthenticatedClient(user.Id, user.Email!, user.FirebaseUid);

        var response = await client.PutAsJsonAsync("/api/users/me", new { timeZoneId = "Europe/Berlin" });
        response.EnsureSuccessStatusCode();

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.Equal("Europe/Berlin", body.GetProperty("timeZoneId").GetString());

        using var scope = factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        Assert.Equal("Europe/Berlin", (await db.Users.SingleAsync(u => u.Id == user.Id)).TimeZoneId);
    }

    // ---------- helpers ----------

    private static ReminderNotificationBackgroundService CreateService(
        SomineApiWebApplicationFactory factory,
        RecordingUserRealtimeEventPublisher publisher,
        bool enabled = true)
    {
        var options = Options.Create(new ReminderNotificationOptions
        {
            Enabled = enabled,
            PollInterval = TimeSpan.FromMinutes(1),
            CatchUpWindow = TimeSpan.FromHours(24),
            DefaultTimeZoneId = "Europe/Istanbul"
        });

        return new ReminderNotificationBackgroundService(
            factory.Services.GetRequiredService<IServiceScopeFactory>(),
            publisher,
            options,
            TimeProvider.System,
            NullLogger<ReminderNotificationBackgroundService>.Instance);
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
        Url = $"https://example.com/{Uri.EscapeDataString(note)}",
        Note = note,
        CreatedAt = DateTime.UtcNow,
        UpdatedAt = DateTime.UtcNow
    };

    private static Reminder TestReminder(Guid itemId, DateOnly date, int hour, int minute, RepeatFrequency repeat) => new()
    {
        Id = Guid.NewGuid(),
        ItemId = itemId,
        ReminderDate = date,
        ReminderHour = hour,
        ReminderMinute = minute,
        RepeatType = repeat,
        IsActive = true,
        CreatedAt = DateTime.UtcNow
    };
}
