using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using SomineApi.Application.Interfaces;
using SomineApi.Infrastructure.Options;

namespace SomineApi.Infrastructure.Services;

public sealed class OpenAiEmbeddingService : IEmbeddingService
{
    private const string EmbeddingsEndpoint = "https://api.openai.com/v1/embeddings";

    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IOptions<EmbeddingOptions> _options;
    private readonly ILogger<OpenAiEmbeddingService> _logger;

    public OpenAiEmbeddingService(
        IHttpClientFactory httpClientFactory,
        IOptions<EmbeddingOptions> options,
        ILogger<OpenAiEmbeddingService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _options = options;
        _logger = logger;
    }

    public async Task<IReadOnlyList<float[]>> EmbedAsync(IReadOnlyList<string> texts, CancellationToken ct)
    {
        var options = _options.Value;

        if (texts.Count == 0 || !options.IsConfigured)
        {
            return [];
        }

        try
        {
            var client = _httpClientFactory.CreateClient(nameof(OpenAiEmbeddingService));
            using var request = new HttpRequestMessage(HttpMethod.Post, EmbeddingsEndpoint);
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", options.ApiKey);
            request.Content = JsonContent.Create(new OpenAiEmbeddingRequest(
                options.Model,
                texts,
                options.Dimensions));

            using var response = await client.SendAsync(request, ct);

            if (!response.IsSuccessStatusCode)
            {
                var body = await response.Content.ReadAsStringAsync(ct);
                _logger.LogWarning(
                    "OpenAI embeddings request failed with status {StatusCode}: {Body}",
                    (int)response.StatusCode,
                    body.Length > 500 ? body[..500] : body);
                return [];
            }

            var payload = await response.Content.ReadFromJsonAsync<OpenAiEmbeddingResponse>(ct);
            if (payload?.Data == null || payload.Data.Count != texts.Count)
            {
                _logger.LogWarning(
                    "OpenAI embeddings response had unexpected item count. Expected={Expected}, Actual={Actual}",
                    texts.Count,
                    payload?.Data?.Count ?? 0);
                return [];
            }

            return payload.Data
                .OrderBy(d => d.Index)
                .Select(d => d.Embedding)
                .ToList();
        }
        catch (OperationCanceledException) when (ct.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "OpenAI embeddings request failed; returning empty result.");
            return [];
        }
    }

    private sealed record OpenAiEmbeddingRequest(
        [property: JsonPropertyName("model")] string Model,
        [property: JsonPropertyName("input")] IReadOnlyList<string> Input,
        [property: JsonPropertyName("dimensions")] int Dimensions);

    private sealed class OpenAiEmbeddingResponse
    {
        [JsonPropertyName("data")]
        public List<OpenAiEmbeddingData>? Data { get; set; }
    }

    private sealed class OpenAiEmbeddingData
    {
        [JsonPropertyName("index")]
        public int Index { get; set; }

        [JsonPropertyName("embedding")]
        public float[] Embedding { get; set; } = [];
    }
}
