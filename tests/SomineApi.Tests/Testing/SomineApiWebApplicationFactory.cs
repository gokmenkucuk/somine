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
using SomineApi.WebApi.Logging;

namespace SomineApi.Tests.Testing;

public sealed class SomineApiWebApplicationFactory : WebApplicationFactory<Program>
{
    public const string ApiKey = "integration-test-api-key";
    private static readonly ServiceProvider SqliteEfServiceProvider = new ServiceCollection()
        .AddEntityFrameworkSqlite()
        .BuildServiceProvider();

    public FakeSubscriptionTierService SubscriptionTierService { get; } = new();

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Testing");

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

            var hostedServices = services
                .Where(descriptor => descriptor.ServiceType == typeof(IHostedService)
                    && descriptor.ImplementationType == typeof(LogPersistenceBackgroundService))
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
                    .UseInternalServiceProvider(SqliteEfServiceProvider));

            services.AddSingleton<ISubscriptionTierService>(SubscriptionTierService);
            services.AddSingleton<ILogPersistenceQueue, NoOpLogPersistenceQueue>();
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
