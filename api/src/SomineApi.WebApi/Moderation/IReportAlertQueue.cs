namespace SomineApi.WebApi.Moderation;

/// <summary>Yeni şikâyetlerin e-posta uyarısı için kuyruğu; isteği bekletmemek için gönderim arka planda yapılır.</summary>
public interface IReportAlertQueue
{
    bool Enqueue(Guid reportId);
    ValueTask<bool> WaitToReadAsync(CancellationToken cancellationToken);
    bool TryRead(out Guid reportId);
}
