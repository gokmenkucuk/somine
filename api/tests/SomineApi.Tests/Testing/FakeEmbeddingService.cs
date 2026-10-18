using SomineApi.Application.Interfaces;

namespace SomineApi.Tests.Testing;

/// <summary>
/// Deterministik embedding sahtesi: aynı metin her zaman aynı 512 boyutlu vektörü üretir.
/// </summary>
public sealed class FakeEmbeddingService : IEmbeddingService
{
    public const int Dimensions = 512;

    public List<IReadOnlyList<string>> Requests { get; } = [];

    public Task<IReadOnlyList<float[]>> EmbedAsync(IReadOnlyList<string> texts, CancellationToken ct)
    {
        Requests.Add(texts);
        IReadOnlyList<float[]> result = texts.Select(CreateDeterministicVector).ToList();
        return Task.FromResult(result);
    }

    private static float[] CreateDeterministicVector(string text)
    {
        var seed = 17;
        foreach (var character in text)
        {
            seed = unchecked(seed * 31 + character);
        }

        var random = new Random(seed);
        var vector = new float[Dimensions];
        for (var i = 0; i < Dimensions; i++)
        {
            vector[i] = (float)(random.NextDouble() * 2 - 1);
        }

        return vector;
    }
}
