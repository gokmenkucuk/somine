namespace SomineApi.WebApi.Options;

/// <summary>
/// GSO Studio yönetim paneli için sunucudan sunucuya erişim. <see cref="ApiKey"/> boşsa
/// /api/admin uçları hiç yokmuş gibi 404 döner. Prod'da env: <c>Admin__ApiKey</c>.
/// </summary>
public sealed class AdminApiOptions
{
    public const string SectionName = "Admin";
    public const string HeaderName = "X-Admin-Key";

    public string? ApiKey { get; set; }

    public bool IsConfigured => !string.IsNullOrWhiteSpace(ApiKey);
}
