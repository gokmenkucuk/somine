using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using SomineApi.Application.Interfaces;
using SomineApi.Infrastructure.Data;
using SomineApi.Infrastructure.Repositories;
using SomineApi.Infrastructure.Services;
using SomineApi.WebApi.Hubs;
using SomineApi.WebApi.Logging;
using SomineApi.WebApi.Middleware;
using SomineApi.WebApi.Options;
using SomineApi.WebApi.Security;
using Microsoft.AspNetCore.RateLimiting;
using System.Text;
using System.Threading.RateLimiting;

var builder = WebApplication.CreateBuilder(args);

builder.Configuration.AddJsonFile("appsettings.Local.json", optional: true, reloadOnChange: true);

// ===== Services =====

// PostgreSQL
builder.Services.AddDbContext<SomineDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("PostgreSQL")));

// Repositories
builder.Services.AddScoped(typeof(IRepository<>), typeof(Repository<>));

// Services
builder.Services.AddScoped<IJwtService, JwtService>();
builder.Services.AddScoped<IFirebaseAuthService, FirebaseAuthService>();
builder.Services.AddScoped<IStorageService, LocalStorageService>();
builder.Services.AddScoped<RevenueCatSubscriptionStatusService>();
builder.Services.AddScoped<CachedSubscriptionService>();
builder.Services.AddScoped<ISubscriptionStatusService>(sp => sp.GetRequiredService<CachedSubscriptionService>());
builder.Services.AddScoped<ISubscriptionTierService>(sp => sp.GetRequiredService<CachedSubscriptionService>());
builder.Services.AddScoped<ClientProofAuthorizationFilter>();
builder.Services.AddScoped<IClientProofValidationService, ClientProofValidationService>();
builder.Services.AddSingleton<IUserRealtimeEventPublisher, UserRealtimeEventPublisher>();
builder.Services.AddSingleton<ILogPersistenceQueue, ChannelLogPersistenceQueue>();
builder.Services.AddHostedService<LogPersistenceBackgroundService>();
builder.Services.AddHttpClient();
builder.Services.AddMemoryCache();
builder.Services.Configure<ClientRequestSecurityOptions>(
    builder.Configuration.GetSection(ClientRequestSecurityOptions.SectionName));
builder.Services.Configure<ApiKeyOptions>(
    builder.Configuration.GetSection(ApiKeyOptions.SectionName));
builder.Services.Configure<PublicWebOptions>(
    builder.Configuration.GetSection(PublicWebOptions.SectionName));

// JWT Authentication
var jwtSettings = builder.Configuration.GetSection("Jwt");
var key = Encoding.UTF8.GetBytes(jwtSettings["Secret"]!);

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,
        ValidateAudience = true,
        ValidateLifetime = true,
        ValidateIssuerSigningKey = true,
        ValidIssuer = jwtSettings["Issuer"],
        ValidAudience = jwtSettings["Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(key)
    };

    // Support JWT in query string for SignalR
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var path = context.HttpContext.Request.Path;
            if (!string.IsNullOrEmpty(accessToken) && path.StartsWithSegments("/hub"))
            {
                context.Token = accessToken;
            }
            return Task.CompletedTask;
        }
    };
});

builder.Services.AddAuthorization();

// Controllers
builder.Services.AddControllers();

// SignalR
builder.Services.AddSignalR();

// Health Checks
builder.Services.AddHealthChecks();

// OpenAPI (.NET 10 native)
builder.Services.AddOpenApi();

// CORS — mobil istemciler Origin göndermez; tarayıcı erişimi yalnızca
// yapılandırılmış origin'lere açılır. Origin yapılandırılmamışsa hiçbir
// cross-origin isteğe izin verilmez (önceki any-origin fallback kaldırıldı).
builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        var origins = builder.Configuration.GetSection("Cors:AllowedOrigins").Get<string[]>();
        if (origins != null && origins.Length > 0)
        {
            policy.WithOrigins(origins)
                  .AllowAnyMethod()
                  .AllowAnyHeader();
        }
    });
});

// Rate limiting — kimlikli isteklerde kullanıcı, kimliksizlerde IP başına pencere
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(httpContext =>
    {
        var partitionKey = httpContext.User.Identity?.IsAuthenticated == true
            ? httpContext.User.FindFirst("sub")?.Value
              ?? httpContext.User.Identity.Name
              ?? "authenticated"
            : httpContext.Connection.RemoteIpAddress?.ToString() ?? "anonymous";

        return RateLimitPartition.GetFixedWindowLimiter(partitionKey, _ =>
            new FixedWindowRateLimiterOptions
            {
                PermitLimit = 300,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0
            });
    });

    // Auth uçları için daha dar pencere (brute force / token farming önlemi)
    options.AddPolicy("auth", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            httpContext.Connection.RemoteIpAddress?.ToString() ?? "anonymous",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 10,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0
            }));

    // Herkese açık paylaşım uçları — IP başına 30 istek/dk
    options.AddPolicy("public", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            httpContext.Connection.RemoteIpAddress?.ToString() ?? "anonymous",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 30,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0
            }));
});

// Sentry
if (!string.IsNullOrEmpty(builder.Configuration["Sentry:Dsn"]))
{
    builder.WebHost.UseSentry(sentryOptions =>
    {
        sentryOptions.Dsn = builder.Configuration["Sentry:Dsn"];
        sentryOptions.SendDefaultPii = false;
    });
}

var app = builder.Build();

var applyMigrationsOnStartup =
    builder.Configuration.GetValue<bool>("Database:ApplyMigrationsOnStartup");

if (applyMigrationsOnStartup)
{
    using var scope = app.Services.CreateScope();
    var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();
    dbContext.Database.Migrate();
}

// ===== Middleware Pipeline =====

if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
}

app.UseMiddleware<RequestLoggingMiddleware>();
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseMiddleware<ApiKeyMiddleware>();

app.UseCors();

app.UseAuthentication();
app.UseAuthorization();

app.UseRateLimiter();

app.MapControllers();

app.MapHealthChecks("/health");

// SignalR Hubs
app.MapHub<ItemsHub>("/hub/items");
app.MapHub<CategoriesHub>("/hub/categories");
app.MapHub<NotificationsHub>("/hub/notifications");

// Ensure uploads directory exists
var uploadsPath = builder.Configuration["Storage:LocalPath"] ?? "./uploads";
if (!Path.IsPathRooted(uploadsPath))
{
    uploadsPath = Path.Combine(builder.Environment.ContentRootPath, uploadsPath);
}
Directory.CreateDirectory(uploadsPath);

// NOTE: /storage files are NOT served as public static files.
// Files are served via StorageController which requires [Authorize].
// See: GET /api/storage/{fileName}

app.Run();

public partial class Program;
