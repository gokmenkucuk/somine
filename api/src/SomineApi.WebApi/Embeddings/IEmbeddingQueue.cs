namespace SomineApi.WebApi.Embeddings;

public interface IEmbeddingQueue
{
    bool Enqueue(Guid itemId);
    ValueTask<bool> WaitToReadAsync(CancellationToken cancellationToken);
    bool TryRead(out Guid itemId);
}
