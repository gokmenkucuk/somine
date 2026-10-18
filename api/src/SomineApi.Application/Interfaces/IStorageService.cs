namespace SomineApi.Application.Interfaces;

public interface IStorageService
{
    Task<string> UploadAsync(Stream fileStream, string fileName, string contentType);
    Task DeleteAsync(string fileName);
    string GetUrl(string fileName);
    Stream? GetStream(string fileName);

    // ----- İçerik adresli, herkese açık nesneler (ör. önbelleğe alınmış OG görselleri) -----
    // relativePath "og/{sha256}.jpg" biçimindedir; yalnızca [a-z0-9._-] segmentlerine izin verilir.

    /// <summary>Nesne zaten varsa dokunmaz (içerik adresli: aynı ad = aynı bayt). Yazım atomiktir.</summary>
    Task SavePublicObjectAsync(string relativePath, ReadOnlyMemory<byte> content, CancellationToken cancellationToken = default);

    bool PublicObjectExists(string relativePath);

    Stream? OpenPublicObject(string relativePath);

    /// <summary>Kimlik doğrulaması gerektirmeyen public adres: {BaseUrl}/public/{relativePath}.</summary>
    string GetPublicObjectUrl(string relativePath);
}
