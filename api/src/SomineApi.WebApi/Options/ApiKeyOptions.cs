namespace SomineApi.WebApi.Options;

public class ApiKeyOptions
{
    public const string SectionName = "ApiKey";

    public bool Enabled { get; set; }
    public string Key { get; set; } = string.Empty;
    public string HeaderName { get; set; } = "X-SoMine-Api-Key";
    public string[] ExemptPaths { get; set; } = ["/health", "/openapi", "/public"];
}
