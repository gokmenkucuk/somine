namespace SomineApi.Application.Interfaces;

public interface IStorageService
{
    Task<string> UploadAsync(Stream fileStream, string fileName, string contentType);
    Task DeleteAsync(string fileName);
    string GetUrl(string fileName);
    Stream? GetStream(string fileName);
}
