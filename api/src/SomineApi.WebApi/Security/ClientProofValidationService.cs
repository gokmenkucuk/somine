using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Options;
using SomineApi.WebApi.Options;

namespace SomineApi.WebApi.Security;

public class ClientProofValidationService : IClientProofValidationService
{
    private const string ClientIdHeader = "X-SoMine-Client-Id";
    private const string TimestampHeader = "X-SoMine-Timestamp";
    private const string NonceHeader = "X-SoMine-Nonce";
    private const string SignatureHeader = "X-SoMine-Signature";

    private readonly ClientRequestSecurityOptions _options;
    private readonly IMemoryCache _cache;
    private readonly ILogger<ClientProofValidationService> _logger;

    public ClientProofValidationService(
        IOptions<ClientRequestSecurityOptions> options,
        IMemoryCache cache,
        ILogger<ClientProofValidationService> logger)
    {
        _options = options.Value;
        _cache = cache;
        _logger = logger;
    }

    public async Task<ClientProofValidationResult> ValidateAsync(HttpContext httpContext, CancellationToken cancellationToken = default)
    {
        if (!_options.Enabled)
        {
            return new ClientProofValidationResult(true, null, null, null);
        }

        var request = httpContext.Request;

        if (!request.Headers.TryGetValue(ClientIdHeader, out var clientIdValues) ||
            !request.Headers.TryGetValue(TimestampHeader, out var timestampValues) ||
            !request.Headers.TryGetValue(NonceHeader, out var nonceValues) ||
            !request.Headers.TryGetValue(SignatureHeader, out var signatureValues))
        {
            return new ClientProofValidationResult(false, "Missing client proof headers", null, null);
        }

        var clientId = clientIdValues.ToString();
        var timestamp = timestampValues.ToString();
        var nonce = nonceValues.ToString();
        var signature = signatureValues.ToString();

        if (string.IsNullOrWhiteSpace(clientId) ||
            string.IsNullOrWhiteSpace(timestamp) ||
            string.IsNullOrWhiteSpace(nonce) ||
            string.IsNullOrWhiteSpace(signature))
        {
            return new ClientProofValidationResult(false, "Invalid client proof headers", null, null);
        }

        var client = _options.Clients.FirstOrDefault(c =>
            string.Equals(c.ClientId, clientId, StringComparison.Ordinal));

        if (client == null || string.IsNullOrWhiteSpace(client.Secret))
        {
            _logger.LogWarning("Unknown or misconfigured client proof client: {ClientId}", clientId);
            return new ClientProofValidationResult(false, "Unknown client", null, null);
        }

        if (!long.TryParse(timestamp, out var unixSeconds))
        {
            return new ClientProofValidationResult(false, "Invalid timestamp", null, null);
        }

        var requestTime = DateTimeOffset.FromUnixTimeSeconds(unixSeconds);
        var skew = Math.Abs((DateTimeOffset.UtcNow - requestTime).TotalMinutes);

        if (skew > _options.AllowedClockSkewMinutes)
        {
            return new ClientProofValidationResult(false, "Expired client proof", null, null);
        }

        var nonceCacheKey = $"client-proof:{clientId}:{nonce}";
        if (_cache.TryGetValue(nonceCacheKey, out _))
        {
            return new ClientProofValidationResult(false, "Replay detected", null, null);
        }

        request.EnableBuffering();

        string body;
        using (var reader = new StreamReader(request.Body, Encoding.UTF8, leaveOpen: true))
        {
            body = await reader.ReadToEndAsync(cancellationToken);
            request.Body.Position = 0;
        }

        var bodyHash = ComputeSha256Hex(body);
        var canonical = string.Join('\n',
            clientId,
            timestamp,
            nonce,
            request.Method.ToUpperInvariant(),
            request.Path.Value ?? string.Empty,
            bodyHash);

        var expectedSignature = ComputeHmacSha256Hex(canonical, client.Secret);

        if (!FixedTimeEqualsHex(expectedSignature, signature))
        {
            _logger.LogWarning("Invalid client proof signature for client {ClientId}", clientId);
            return new ClientProofValidationResult(false, "Invalid client signature", null, null);
        }

        _cache.Set(
            nonceCacheKey,
            true,
            TimeSpan.FromMinutes(Math.Max(1, _options.AllowedClockSkewMinutes)));

        return new ClientProofValidationResult(true, null, client.ClientId, client.Platform);
    }

    private static string ComputeSha256Hex(string value)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(value));
        return Convert.ToHexString(bytes);
    }

    private static string ComputeHmacSha256Hex(string value, string secret)
    {
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(secret));
        var bytes = hmac.ComputeHash(Encoding.UTF8.GetBytes(value));
        return Convert.ToHexString(bytes);
    }

    private static bool FixedTimeEqualsHex(string left, string right)
    {
        var leftBytes = Encoding.UTF8.GetBytes(left);
        var rightBytes = Encoding.UTF8.GetBytes(right);
        return CryptographicOperations.FixedTimeEquals(leftBytes, rightBytes);
    }
}
