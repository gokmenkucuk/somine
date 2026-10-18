using System.Net;
using System.Net.Sockets;

namespace SomineApi.WebApi.ImageCache;

/// <summary>
/// SSRF koruması: yalnızca genel internete yönlendirilebilir adreslere bağlanılır.
/// Loopback, özel ağ, link-local (bulut metadata 169.254.169.254 dahil), CGNAT, multicast,
/// belgeleme/ayrılmış bloklar ve IPv4'ü gömen IPv6 geçiş önekleri engellenir.
/// </summary>
public static class IpAddressPolicy
{
    public static bool IsPublic(IPAddress address)
    {
        if (address.IsIPv4MappedToIPv6)
            address = address.MapToIPv4();

        return address.AddressFamily switch
        {
            AddressFamily.InterNetwork => IsPublicIPv4(address.GetAddressBytes()),
            AddressFamily.InterNetworkV6 => IsPublicIPv6(address),
            _ => false
        };
    }

    private static bool IsPublicIPv4(byte[] b)
    {
        return !(
            b[0] == 0 ||                                   // 0.0.0.0/8 "bu ağ"
            b[0] == 10 ||                                  // 10.0.0.0/8
            (b[0] == 100 && b[1] >= 64 && b[1] <= 127) ||  // 100.64.0.0/10 CGNAT
            b[0] == 127 ||                                 // loopback
            (b[0] == 169 && b[1] == 254) ||                // link-local / bulut metadata
            (b[0] == 172 && b[1] >= 16 && b[1] <= 31) ||   // 172.16.0.0/12
            (b[0] == 192 && b[1] == 0 && b[2] == 0) ||     // 192.0.0.0/24 IETF
            (b[0] == 192 && b[1] == 0 && b[2] == 2) ||     // TEST-NET-1
            (b[0] == 192 && b[1] == 88 && b[2] == 99) ||   // 6to4 relay anycast
            (b[0] == 192 && b[1] == 168) ||                // 192.168.0.0/16
            (b[0] == 198 && (b[1] == 18 || b[1] == 19)) || // benchmark
            (b[0] == 198 && b[1] == 51 && b[2] == 100) ||  // TEST-NET-2
            (b[0] == 203 && b[1] == 0 && b[2] == 113) ||   // TEST-NET-3
            b[0] >= 224);                                  // multicast + 240/4 ayrılmış + broadcast
    }

    private static bool IsPublicIPv6(IPAddress address)
    {
        if (address.Equals(IPAddress.IPv6Any) || address.Equals(IPAddress.IPv6Loopback))
            return false;
        if (address.IsIPv6LinkLocal || address.IsIPv6SiteLocal || address.IsIPv6Multicast)
            return false;

        var b = address.GetAddressBytes();
        if ((b[0] & 0xFE) == 0xFC) return false;                                    // fc00::/7 ULA
        if (b[0] == 0xFF) return false;                                             // multicast
        if (b.Take(12).All(x => x == 0)) return false;                              // ::/96 IPv4-uyumlu
        if (b[0] == 0x00 && b[1] == 0x64 && b[2] == 0xFF && b[3] == 0x9B) return false; // 64:ff9b::/96 NAT64
        if (b[0] == 0x20 && b[1] == 0x02) return false;                             // 2002::/16 6to4
        if (b[0] == 0x20 && b[1] == 0x01 && b[2] == 0x00 && b[3] == 0x00) return false; // 2001::/32 Teredo
        if (b[0] == 0x20 && b[1] == 0x01 && b[2] == 0x0D && b[3] == 0xB8) return false; // 2001:db8::/32 belgeleme
        if (b[0] == 0x01 && b[1] == 0x00 && b.Skip(2).Take(6).All(x => x == 0)) return false; // 100::/64 discard
        return true;
    }
}
