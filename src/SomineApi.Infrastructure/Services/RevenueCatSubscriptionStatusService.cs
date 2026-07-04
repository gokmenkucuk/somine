using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using SomineApi.Application.DTOs.Subscriptions;
using SomineApi.Application.Interfaces;
using SomineApi.Domain.Entities;

namespace SomineApi.Infrastructure.Services;

public class RevenueCatSubscriptionStatusService : ISubscriptionStatusService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IConfiguration _configuration;

    public RevenueCatSubscriptionStatusService(IHttpClientFactory httpClientFactory, IConfiguration configuration)
    {
        _httpClientFactory = httpClientFactory;
        _configuration = configuration;
    }

    public async Task<SubscriptionStatusDto> GetStatusAsync(User user, string? preferredPlatform, CancellationToken cancellationToken = default)
    {
        var appUserIds = BuildCandidateAppUserIds(user);
        foreach (var appUserId in appUserIds)
        {
            var status = await TryGetStatusForAppUserIdAsync(appUserId, preferredPlatform, cancellationToken);
            if (status != null && status.IsActive)
            {
                return status;
            }
        }

        return new SubscriptionStatusDto(false, null, null, preferredPlatform);
    }

    private async Task<SubscriptionStatusDto?> TryGetStatusForAppUserIdAsync(string appUserId, string? preferredPlatform, CancellationToken cancellationToken)
    {
        foreach (var platform in BuildPlatformCandidates(preferredPlatform))
        {
            var apiKey = GetApiKey(platform);
            if (string.IsNullOrWhiteSpace(apiKey))
            {
                continue;
            }

            var client = _httpClientFactory.CreateClient();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
            client.DefaultRequestHeaders.Accept.Add(new MediaTypeWithQualityHeaderValue("application/json"));

            using var response = await client.GetAsync(
                $"https://api.revenuecat.com/v1/subscribers/{Uri.EscapeDataString(appUserId)}",
                cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                continue;
            }

            await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
            using var document = await JsonDocument.ParseAsync(stream, cancellationToken: cancellationToken);
            return ParseStatus(document.RootElement, platform);
        }

        return null;
    }

    private SubscriptionStatusDto ParseStatus(JsonElement root, string? platform)
    {
        if (!root.TryGetProperty("subscriber", out var subscriber))
        {
            return new SubscriptionStatusDto(false, null, null, platform);
        }

        if (!subscriber.TryGetProperty("entitlements", out var entitlements) ||
            entitlements.ValueKind != JsonValueKind.Object)
        {
            return new SubscriptionStatusDto(false, null, null, platform);
        }

        var now = DateTimeOffset.UtcNow;

        foreach (var entitlement in entitlements.EnumerateObject())
        {
            var entitlementInfo = entitlement.Value;
            var expiresAt = TryReadDateTimeOffset(entitlementInfo, "expires_date");
            var productId = TryReadString(entitlementInfo, "product_identifier");

            var isActive = !expiresAt.HasValue || expiresAt > now;
            if (isActive)
            {
                return new SubscriptionStatusDto(true, productId, expiresAt?.UtcDateTime, platform);
            }
        }

        return new SubscriptionStatusDto(false, null, null, platform);
    }

    private IEnumerable<string> BuildCandidateAppUserIds(User user)
    {
        var values = new[]
        {
            user.Id.ToString(),
            user.FirebaseUid
        };

        return values
            .Where(v => !string.IsNullOrWhiteSpace(v))
            .Distinct(StringComparer.Ordinal);
    }

    private IEnumerable<string?> BuildPlatformCandidates(string? preferredPlatform)
    {
        if (!string.IsNullOrWhiteSpace(preferredPlatform))
        {
            yield return preferredPlatform.ToLowerInvariant();
        }

        yield return "apple";
        yield return "google";
    }

    private string? GetApiKey(string? platform)
    {
        return platform switch
        {
            "apple" or "ios" => _configuration["RevenueCat:AppleApiKey"],
            "google" or "android" => _configuration["RevenueCat:GoogleApiKey"],
            _ => null
        };
    }

    private static string? TryReadString(JsonElement element, string propertyName)
    {
        return element.TryGetProperty(propertyName, out var property) && property.ValueKind == JsonValueKind.String
            ? property.GetString()
            : null;
    }

    private static DateTimeOffset? TryReadDateTimeOffset(JsonElement element, string propertyName)
    {
        if (!element.TryGetProperty(propertyName, out var property) || property.ValueKind != JsonValueKind.String)
        {
            return null;
        }

        return DateTimeOffset.TryParse(property.GetString(), out var parsed)
            ? parsed
            : null;
    }
}
