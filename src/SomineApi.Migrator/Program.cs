using FirebaseAdmin;
using FirebaseAdmin.Auth;
using Google.Cloud.Firestore;
using Google.Apis.Auth.OAuth2;
using Microsoft.EntityFrameworkCore;
using SomineApi.Infrastructure.Data;

var options = FirebaseMigrationOptions.Parse(args);
var repositoryRoot = RootPathLocator.FindRepositoryRoot(AppContext.BaseDirectory);
var webApiConfigPath = Path.Combine(repositoryRoot, "src", "SomineApi.WebApi");

var builder = Host.CreateApplicationBuilder(args);
builder.Configuration.Sources.Clear();
builder.Configuration
    .SetBasePath(webApiConfigPath)
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: false)
    .AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: false)
    .AddEnvironmentVariables();

builder.Logging.ClearProviders();
builder.Logging.AddSimpleConsole(console =>
{
    console.SingleLine = true;
    console.TimestampFormat = "HH:mm:ss ";
});

builder.Services.AddDbContext<SomineDbContext>(dbOptions =>
{
    var connectionString = builder.Configuration.GetConnectionString("PostgreSQL")
        ?? throw new InvalidOperationException("ConnectionStrings:PostgreSQL missing.");

    dbOptions.UseNpgsql(connectionString);
});

builder.Services.AddSingleton(sp =>
{
    var configuration = sp.GetRequiredService<IConfiguration>();
    var projectId = configuration["Firebase:ProjectId"];
    if (string.IsNullOrWhiteSpace(projectId))
    {
        throw new InvalidOperationException("Firebase:ProjectId missing.");
    }

    var credentialsPath = NormalizeCredentialsPath(configuration["Firebase:CredentialsPath"]);
    var firebaseAppName = "somine-migrator";

    var appOptions = new AppOptions
    {
        ProjectId = projectId
    };

    if (!string.IsNullOrWhiteSpace(credentialsPath))
    {
        if (!Path.IsPathRooted(credentialsPath))
        {
            credentialsPath = Path.GetFullPath(Path.Combine(repositoryRoot, credentialsPath));
        }

        if (!File.Exists(credentialsPath))
        {
            throw new FileNotFoundException("Firebase credentials file not found.", credentialsPath);
        }

        Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", credentialsPath);
    }

    appOptions.Credential = GoogleCredential.GetApplicationDefault();

    var existingApp = FirebaseApp.GetInstance(firebaseAppName);
    if (existingApp is not null)
    {
        return existingApp;
    }

    return FirebaseApp.Create(appOptions, firebaseAppName);
});

builder.Services.AddSingleton(sp =>
{
    var configuration = sp.GetRequiredService<IConfiguration>();
    var projectId = configuration["Firebase:ProjectId"];
    if (string.IsNullOrWhiteSpace(projectId))
    {
        throw new InvalidOperationException("Firebase:ProjectId missing.");
    }

    var credentialsPath = NormalizeCredentialsPath(configuration["Firebase:CredentialsPath"]);
    if (!string.IsNullOrWhiteSpace(credentialsPath) && !Path.IsPathRooted(credentialsPath))
    {
        credentialsPath = Path.GetFullPath(Path.Combine(repositoryRoot, credentialsPath));
    }

    var firestoreBuilder = new FirestoreDbBuilder
    {
        ProjectId = projectId,
        DatabaseId = "(default)"
    };

    if (!string.IsNullOrWhiteSpace(credentialsPath))
    {
        if (!File.Exists(credentialsPath))
        {
            throw new FileNotFoundException("Firebase credentials file not found.", credentialsPath);
        }

        Environment.SetEnvironmentVariable("GOOGLE_APPLICATION_CREDENTIALS", credentialsPath);
    }

    firestoreBuilder.GoogleCredential = GoogleCredential.GetApplicationDefault();

    return firestoreBuilder.Build();
});

builder.Services.AddSingleton(sp => FirebaseAuth.GetAuth(sp.GetRequiredService<FirebaseApp>()));
builder.Services.AddScoped<FirebaseContentMigrationRunner>();

using var host = builder.Build();
using var scope = host.Services.CreateScope();

var runner = scope.ServiceProvider.GetRequiredService<FirebaseContentMigrationRunner>();
var exitCode = await runner.RunAsync(options, CancellationToken.None);
Environment.ExitCode = exitCode;

static string? NormalizeCredentialsPath(string? configuredPath)
{
    if (string.IsNullOrWhiteSpace(configuredPath))
    {
        return null;
    }

    var trimmed = configuredPath.Trim();
    return trimmed.StartsWith("CHANGE_ME", StringComparison.OrdinalIgnoreCase)
        ? null
        : trimmed;
}

internal static class RootPathLocator
{
    public static string FindRepositoryRoot(string startPath)
    {
        var directory = new DirectoryInfo(startPath);

        while (directory is not null)
        {
            if (File.Exists(Path.Combine(directory.FullName, "SomineApi.slnx")))
            {
                return directory.FullName;
            }

            directory = directory.Parent;
        }

        throw new DirectoryNotFoundException("Could not locate SomineApi.slnx from the current execution path.");
    }
}
