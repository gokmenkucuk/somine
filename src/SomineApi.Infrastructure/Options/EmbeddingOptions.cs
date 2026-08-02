namespace SomineApi.Infrastructure.Options;

public class EmbeddingOptions
{
    public const string SectionName = "Embedding";

    public string ApiKey { get; set; } = string.Empty;
    public string Model { get; set; } = "text-embedding-3-small";
    public int Dimensions { get; set; } = 512;
    public bool Enabled { get; set; } = true;

    /// <summary>ApiKey boş ya da placeholder ise özellik fiilen kapalıdır.</summary>
    public bool IsConfigured =>
        Enabled
        && !string.IsNullOrWhiteSpace(ApiKey)
        && !ApiKey.StartsWith("CHANGE_ME", StringComparison.Ordinal);
}
