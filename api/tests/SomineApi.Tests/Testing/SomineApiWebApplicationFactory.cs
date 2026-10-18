using System.Data.Common;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Hosting;
using SomineApi.Application.Interfaces;
using SomineApi.Infrastructure.Data;
using SomineApi.WebApi.Embeddings;
using SomineApi.WebApi.ImageCache;
using SomineApi.WebApi.Logging;
using SomineApi.WebApi.Moderation;
using SomineApi.WebApi.Reminders;

namespace SomineApi.Tests.Testing;

public sealed class SomineApiWebApplicationFactory : WebApplicationFactory<Program>
{
    public const string ApiKey = "integration-test-api-key";
    private static readonly ServiceProvider SqliteEfServiceProvider = new ServiceCollection()
        .AddEntityFrameworkSqlite()
        .BuildServiceProvider();

    public FakeSubscriptionTierService SubscriptionTierService { get; } = new();

    public FakeFirebaseAuthService FirebaseAuthService { get; } = new();

    public FakeEmbeddingService EmbeddingService { get; } = new();

    public FakeReportAlertSender ReportAlertSender { get; } = new();

    public FakePushNotificationSender PushNotificationSender { get; } = new();

    public SaveChangesHookInterceptor SaveChangesHook { get; } = new();

    /// <summary>OG görsel indirmeleri için sahte HTTP; testler asla gerçek ağa çıkmaz.</summary>
    public FakeImageHttpHandler ImageHttpHandler { get; } = new();

    /// <summary>Sahte DNS; varsayılan olarak her host'u public bir belgeleme dışı adrese çözer.</summary>
    public FakeHostAddressResolver HostAddressResolver { get; } = new();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

        // Program.cs JWT ayarlarını host kurulurken okuyor; ConfigureAppConfiguration ise
        // o noktada henüz uygulanmamış olur. UseSetting erken yüklenir, böylece testler
        // geliştiricinin yerel appsettings.Local.json dosyasına bağlı kalmaz.
        builder.UseSetting("Jwt:Secret", "SomineApi-SuperSecretKey-256Bits-MinimumLength-Required!!");
        builder.UseSetting("Jwt:Issuer", "somine-api");
        builder.UseSetting("Jwt:Audience", "somine-app");

        builder.ConfigureAppConfiguration((_, configurationBuilder) =>
        {
            configurationBuilder.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:PostgreSQL"] = "Host=localhost;Database=unused",
                ["Database:ApplyMigrationsOnStartup"] = "false",
                ["ApiKey:Enabled"] = "true",
                ["ApiKey:Key"] = ApiKey,
                ["ApiKey:HeaderName"] = "X-SoMine-Api-Key",
                ["Jwt:Secret"] = "SomineApi-SuperSecretKey-256Bits-MinimumLength-Required!!",
                ["Jwt:Issuer"] = "somine-api",
                ["Jwt:Audience"] = "somine-app",
                ["Jwt:AccessTokenExpireMinutes"] = "60",
                ["Moderation:ReportEmail"] = "moderator@example.com",
                ["LogRetention:Enabled"] = "false",
                ["Moderation:Smtp:Host"] = "smtp.invalid",
                ["Storage:LocalPath"] = Path.Combine(Path.GetTempPath(), "somine-api-tests", Guid.NewGuid().ToString("N"))
            });
        });

        builder.ConfigureServices(services =>
        {
            services.RemoveAll<DbContextOptions<SomineDbContext>>();
            services.RemoveAll<IDbContextOptionsConfiguration<SomineDbContext>>();
            services.RemoveAll<DbConnection>();
            services.RemoveAll<ISubscriptionTierService>();
            services.RemoveAll<ILogPersistenceQueue>();
            services.RemoveAll<IFirebaseAuthService>();
            services.RemoveAll<IEmbeddingService>();
            services.RemoveAll<IReportAlertSender>();
            services.AddSingleton<IReportAlertSender>(ReportAlertSender);
            services.RemoveAll<IPushNotificationSender>();
            services.AddSingleton<IPushNotificationSender>(PushNotificationSender);

            var hostedServices = services
                .Where(descriptor => descriptor.ServiceType == typeof(IHostedService)
                    && (descriptor.ImplementationType == typeof(LogPersistenceBackgroundService)
                        || descriptor.ImplementationType == typeof(EmbeddingBackgroundService)
                        || descriptor.ImplementationType == typeof(OgImageCacheBackgroundService)
                        || descriptor.ImplementationType == typeof(ReminderNotificationBackgroundService)))
                .ToList();
            foreach (var descriptor in hostedServices)
            {
                services.Remove(descriptor);
            }

            services.AddSingleton<DbConnection>(_ =>
            {
                var connection = new SqliteConnection("Data Source=:memory:");
                connection.Open();
                return connection;
            });

            services.AddDbContext<SomineDbContext>((sp, options) =>
                options
                    .UseSqlite(sp.GetRequiredService<DbConnection>())
                    .UseInternalServiceProvider(SqliteEfServiceProvider)
                    .AddInterceptors(SaveChangesHook));

            services.AddSingleton<ISubscriptionTierService>(SubscriptionTierService);
            services.AddSingleton<ILogPersistenceQueue, NoOpLogPersistenceQueue>();
            services.AddSingleton<IFirebaseAuthService>(FirebaseAuthService);
            services.AddSingleton<IEmbeddingService>(EmbeddingService);
            services.RemoveAll<IHostAddressResolver>();
            services.AddSingleton<IHostAddressResolver>(HostAddressResolver);
            services.AddHttpClient(ImageCacheService.HttpClientName)
                .ConfigurePrimaryHttpMessageHandler(() => ImageHttpHandler)
                .SetHandlerLifetime(Timeout.InfiniteTimeSpan);
        });
    }

    public async Task ResetDatabaseAsync()
    {
        using var scope = Services.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
        await dbContext.Database.EnsureDeletedAsync();
        await dbContext.Database.EnsureCreatedAsync();
    }
}
