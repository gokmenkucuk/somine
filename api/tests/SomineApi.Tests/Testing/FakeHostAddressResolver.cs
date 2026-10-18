using System.Collections.Concurrent;
using System.Net;
using SomineApi.WebApi.ImageCache;

namespace SomineApi.Tests.Testing;

public sealed class FakeHostAddressResolver : IHostAddressResolver
{
    private static readonly IPAddress DefaultPublicAddress = IPAddress.Parse("93.184.216.34");

    private readonly ConcurrentDictionary<string, IPAddress[]> _map = new(StringComparer.OrdinalIgnoreCase);

    public void Map(string host, params string[] addresses)
        => _map[host] = addresses.Select(IPAddress.Parse).ToArray();

    public Task<IPAddress[]> ResolveAsync(string host, CancellationToken cancellationToken)
    {
        if (IPAddress.TryParse(host, out var literal))
            return Task.FromResult(new[] { literal });
        if (string.Equals(host, "localhost", StringComparison.OrdinalIgnoreCase))
            return Task.FromResult(new[] { IPAddress.Loopback, IPAddress.IPv6Loopback });
        return Task.FromResult(_map.TryGetValue(host, out var addresses) ? addresses : [DefaultPublicAddress]);
    }
}
