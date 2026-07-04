using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using System.Text.Json;

namespace SomineApi.Infrastructure.Data;

public class DesignTimeSomineDbContextFactory : IDesignTimeDbContextFactory<SomineDbContext>
{
    public SomineDbContext CreateDbContext(string[] args)
    {
        var infrastructurePath = Directory.GetCurrentDirectory();
        var webApiPath = Path.GetFullPath(Path.Combine(infrastructurePath, "../SomineApi.WebApi"));
        var connectionString = ResolveConnectionString(webApiPath);

        var optionsBuilder = new DbContextOptionsBuilder<SomineDbContext>();
        optionsBuilder.UseNpgsql(connectionString);

        return new SomineDbContext(optionsBuilder.Options);
    }

    private static string ResolveConnectionString(string webApiPath)
    {
        var environmentValue = Environment.GetEnvironmentVariable("ConnectionStrings__PostgreSQL");
        if (!string.IsNullOrWhiteSpace(environmentValue))
        {
            return environmentValue;
        }

        var localPath = Path.Combine(webApiPath, "appsettings.Local.json");
        if (File.Exists(localPath))
        {
            var localValue = TryReadConnectionString(localPath);
            if (!string.IsNullOrWhiteSpace(localValue))
            {
                return localValue;
            }
        }

        var defaultPath = Path.Combine(webApiPath, "appsettings.json");
        var defaultValue = TryReadConnectionString(defaultPath);
        if (!string.IsNullOrWhiteSpace(defaultValue))
        {
            return defaultValue;
        }

        throw new InvalidOperationException("ConnectionStrings:PostgreSQL could not be resolved for design-time DbContext creation.");
    }

    private static string? TryReadConnectionString(string filePath)
    {
        using var document = JsonDocument.Parse(File.ReadAllText(filePath));
        if (document.RootElement.TryGetProperty("ConnectionStrings", out var connectionStrings) &&
            connectionStrings.TryGetProperty("PostgreSQL", out var postgresProperty))
        {
            return postgresProperty.GetString();
        }

        return null;
    }
}
