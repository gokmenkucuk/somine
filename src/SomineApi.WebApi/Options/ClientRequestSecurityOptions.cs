namespace SomineApi.WebApi.Options;

public class ClientRequestSecurityOptions
{
    public const string SectionName = "ClientRequestSecurity";

    public bool Enabled { get; set; }
    public int AllowedClockSkewMinutes { get; set; } = 5;
    public List<ClientRequestSecurityClientOptions> Clients { get; set; } = [];
}

public class ClientRequestSecurityClientOptions
{
    public string ClientId { get; set; } = string.Empty;
    public string Secret { get; set; } = string.Empty;
    public string Platform { get; set; } = string.Empty;
}
