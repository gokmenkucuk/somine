using System.Net;

namespace SomineApi.WebApi.ImageCache;

/// <summary>DNS çözümleme soyutlaması (testlerde gerçek ağa çıkmamak için sahtelenir).</summary>
public interface IHostAddressResolver
{
    Task<IPAddress[]> ResolveAsync(string host, CancellationToken cancellationToken);
}

public sealed class DnsHostAddressResolver : IHostAddressResolver
{
    public async Task<IPAddress[]> ResolveAsync(string host, CancellationToken cancellationToken)
    {
        if (IPAddress.TryParse(host, out var literal))
            return [literal];

        return await Dns.GetHostAddressesAsync(host, cancellationToken);
    }
}
