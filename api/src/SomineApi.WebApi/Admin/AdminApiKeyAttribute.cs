using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Options;
using SomineApi.WebApi.Options;

namespace SomineApi.WebApi.Admin;

/// <summary>
/// Yönetim uçlarını <c>X-Admin-Key</c> başlığıyla korur. Anahtar yapılandırılmamışsa 404
/// (uç yok gibi davranır), başlık eksik ya da yanlışsa 401 döner. Karşılaştırma sabit zamanlı.
/// </summary>
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public sealed class AdminApiKeyAttribute : Attribute, IAsyncAuthorizationFilter
{
    public Task OnAuthorizationAsync(AuthorizationFilterContext context)
    {
        var services = context.HttpContext.RequestServices;
        var options = services.GetRequiredService<IOptionsMonitor<AdminApiOptions>>().CurrentValue;
        if (!options.IsConfigured)
        {
            context.Result = new NotFoundResult();
            return Task.CompletedTask;
        }

        if (!context.HttpContext.Request.Headers.TryGetValue(AdminApiOptions.HeaderName, out var provided)
            || !KeysMatch(options.ApiKey!, provided.ToString()))
        {
            services.GetRequiredService<ILogger<AdminApiKeyAttribute>>()
                .LogWarning("Admin API key missing or invalid. Path: {Path}", context.HttpContext.Request.Path);
            context.Result = new UnauthorizedResult();
        }

        return Task.CompletedTask;
    }

    // Uzunluk sızmasın diye iki değerin özeti karşılaştırılır.
    public static bool KeysMatch(string expected, string provided)
    {
        if (string.IsNullOrEmpty(provided)) return false;
        var a = SHA256.HashData(Encoding.UTF8.GetBytes(expected));
        var b = SHA256.HashData(Encoding.UTF8.GetBytes(provided));
        return CryptographicOperations.FixedTimeEquals(a, b);
    }
}
