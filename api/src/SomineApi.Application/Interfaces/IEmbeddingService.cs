namespace SomineApi.Application.Interfaces;

public interface IEmbeddingService
{
    /// <summary>
    /// Verilen metinler için embedding vektörleri üretir. Servis kapalıysa veya
    /// hata oluşursa boş liste döner (özellik keyword aramaya geri düşer).
    /// Başarılı durumda dönen liste, girişle aynı sırada ve aynı uzunluktadır.
    /// </summary>
    Task<IReadOnlyList<float[]>> EmbedAsync(IReadOnlyList<string> texts, CancellationToken ct);
}
