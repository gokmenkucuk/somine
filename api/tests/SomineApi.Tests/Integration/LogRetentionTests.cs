using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using SomineApi.Domain.Entities;
using SomineApi.Infrastructure.Data;
using SomineApi.Tests.Testing;
using SomineApi.WebApi.Maintenance;

namespace SomineApi.Tests.Integration;

public class LogRetentionTests
{
    [Fact]
    public async Task RunOnce_RemovesOnlyRecordsOlderThanRetention()
    {
        using var factory = new SomineApiWebApplicationFactory();
        await factory.ResetDatabaseAsync();

        var now = DateTime.UtcNow;
        var user = new User { Id = Guid.NewGuid(), FirebaseUid = "fb-retention", Email = "retention@somine.test" };
        var oldRequest = Request(now.AddDays(-45));
        var newRequest = Request(now.AddDays(-5));
        var oldRequestWithRecentError = Request(now.AddDays(-40));
        var oldError = new ExceptionLog { Id = Guid.NewGuid(), ExceptionType = "X", Message = "old", CreatedAt = now.AddDays(-45) };
        var recentError = new ExceptionLog
        {
            Id = Guid.NewGuid(), ExceptionType = "X", Message = "recent", CreatedAt = now.AddDays(-1),
            RequestLogId = oldRequestWithRecentError.Id
        };
        var revokedLongAgo = Session(user.Id, expiresAt: now.AddDays(10), revokedAt: now.AddDays(-31));
        var expiredLongAgo = Session(user.Id, expiresAt: now.AddDays(-40), revokedAt: null);
        var active = Session(user.Id, expiresAt: now.AddDays(20), revokedAt: null);

        using (var scope = factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
            db.Users.Add(user);
            db.RequestLogs.AddRange(oldRequest, newRequest, oldRequestWithRecentError);
            db.ExceptionLogs.AddRange(oldError, recentError);
            db.AuthSessions.AddRange(revokedLongAgo, expiredLongAgo, active);
            await db.SaveChangesAsync();
        }

        var result = await factory.Services.GetRequiredService<LogRetentionService>().RunOnceAsync(CancellationToken.None);

        Assert.Equal((1, 1, 2), result);
        using var verify = factory.Services.CreateScope();
        var check = verify.ServiceProvider.GetRequiredService<SomineDbContext>();
        Assert.Equal(
            new[] { newRequest.Id, oldRequestWithRecentError.Id }.OrderBy(x => x),
            (await check.RequestLogs.Select(r => r.Id).ToListAsync()).OrderBy(x => x));
        Assert.Equal([recentError.Id], await check.ExceptionLogs.Select(e => e.Id).ToListAsync());
        Assert.Equal([active.Id], await check.AuthSessions.Select(s => s.Id).ToListAsync());
    }

    private static RequestLog Request(DateTime createdAt) => new()
    {
        Id = Guid.NewGuid(), TraceId = Guid.NewGuid().ToString("N"), Method = "GET", Path = "/x",
        StatusCode = 200, DurationMs = 1, IpAddress = "203.0.113.1", CreatedAt = createdAt, UpdatedAt = createdAt
    };

    private static AuthSession Session(Guid userId, DateTime expiresAt, DateTime? revokedAt) => new()
    {
        Id = Guid.NewGuid(), UserId = userId, RefreshTokenHash = Guid.NewGuid().ToString("N"),
        ExpiresAt = expiresAt, RevokedAt = revokedAt, IpAddress = "203.0.113.1"
    };
}
