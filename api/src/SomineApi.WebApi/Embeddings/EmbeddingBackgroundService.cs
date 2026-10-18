using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Pgvector;
using SomineApi.Application.Interfaces;
using SomineApi.Infrastructure.Data;
using SomineApi.Infrastructure.Entities;
using SomineApi.Infrastructure.Options;

namespace SomineApi.WebApi.Embeddings;

public sealed class EmbeddingBackgroundService : BackgroundService
{
    private const int BatchSize = 64;

    private readonly IServiceScopeFactory _scopeFactory;
    private readonly IEmbeddingQueue _queue;
    private readonly IEmbeddingService _embeddingService;
    private readonly IOptions<EmbeddingOptions> _options;
    private readonly ILogger<EmbeddingBackgroundService> _logger;

    public EmbeddingBackgroundService(
        IServiceScopeFactory scopeFactory,
        IEmbeddingQueue queue,
        IEmbeddingService embeddingService,
        IOptions<EmbeddingOptions> options,
        ILogger<EmbeddingBackgroundService> logger)
    {
        _scopeFactory = scopeFactory;
        _queue = queue;
        _embeddingService = embeddingService;
        _options = options;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (await _queue.WaitToReadAsync(stoppingToken))
        {
            var itemIds = new HashSet<Guid>();
            while (itemIds.Count < BatchSize && _queue.TryRead(out var itemId))
            {
                itemIds.Add(itemId);
            }

            if (itemIds.Count == 0)
            {
                continue;
            }

            // ApiKey yapılandırılmamışsa özellik kapalıdır; kuyruğu boşaltıp devam et.
            if (!_options.Value.IsConfigured)
            {
                continue;
            }

            try
            {
                await ProcessBatchAsync(itemIds, stoppingToken);
            }
            catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
            {
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to persist item embeddings. ItemCount={ItemCount}", itemIds.Count);
            }
        }
    }

    private async Task ProcessBatchAsync(HashSet<Guid> itemIds, CancellationToken stoppingToken)
    {
        using var scope = _scopeFactory.CreateScope();
        var dbContext = scope.ServiceProvider.GetRequiredService<SomineDbContext>();

        // Global soft-delete filtresi aktif: silinmiş item'lar için embedding üretilmez.
        var items = await dbContext.Items
            .Where(i => itemIds.Contains(i.Id))
            .Select(i => new { i.Id, i.OgTitle, i.Note, i.Url })
            .ToListAsync(stoppingToken);

        var candidates = items
            .Select(i => new { i.Id, Text = BuildEmbeddingText(i.OgTitle, i.Note, i.Url) })
            .Where(i => !string.IsNullOrWhiteSpace(i.Text))
            .ToList();

        if (candidates.Count == 0)
        {
            return;
        }

        var vectors = await _embeddingService.EmbedAsync(
            candidates.Select(c => c.Text).ToList(),
            stoppingToken);

        if (vectors.Count != candidates.Count)
        {
            _logger.LogWarning(
                "Embedding service returned {VectorCount} vectors for {CandidateCount} items; skipping batch.",
                vectors.Count,
                candidates.Count);
            return;
        }

        var candidateIds = candidates.Select(c => c.Id).ToList();
        var existingEmbeddings = await dbContext.Set<ItemEmbedding>()
            .Where(e => candidateIds.Contains(e.ItemId))
            .ToDictionaryAsync(e => e.ItemId, stoppingToken);

        var model = _options.Value.Model;
        for (var index = 0; index < candidates.Count; index++)
        {
            var vector = new Vector(vectors[index]);
            if (existingEmbeddings.TryGetValue(candidates[index].Id, out var existing))
            {
                existing.Embedding = vector;
                existing.Model = model;
                existing.UpdatedAt = DateTime.UtcNow;
            }
            else
            {
                dbContext.Set<ItemEmbedding>().Add(new ItemEmbedding
                {
                    ItemId = candidates[index].Id,
                    Embedding = vector,
                    Model = model,
                    UpdatedAt = DateTime.UtcNow
                });
            }
        }

        await dbContext.SaveChangesAsync(stoppingToken);
    }

    internal static string BuildEmbeddingText(string? ogTitle, string? note, string? url)
    {
        var parts = new[] { ogTitle, note, url }
            .Where(part => !string.IsNullOrWhiteSpace(part))
            .Select(part => part!.Trim());

        return string.Join("\n", parts);
    }
}
