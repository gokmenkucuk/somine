using System.Security.Cryptography;
using System.Text;

internal static class DeterministicGuid
{
    public static Guid Create(string namespaceName, string value)
    {
        var namespaceBytes = Encoding.UTF8.GetBytes(namespaceName);
        var valueBytes = Encoding.UTF8.GetBytes(value);
        var combined = new byte[namespaceBytes.Length + valueBytes.Length];

        Buffer.BlockCopy(namespaceBytes, 0, combined, 0, namespaceBytes.Length);
        Buffer.BlockCopy(valueBytes, 0, combined, namespaceBytes.Length, valueBytes.Length);

        Span<byte> hash = stackalloc byte[20];
        SHA1.HashData(combined, hash);

        Span<byte> guidBytes = stackalloc byte[16];
        hash[..16].CopyTo(guidBytes);

        guidBytes[6] = (byte)((guidBytes[6] & 0x0F) | 0x50);
        guidBytes[8] = (byte)((guidBytes[8] & 0x3F) | 0x80);

        return new Guid(guidBytes);
    }
}
