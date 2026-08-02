using Pgvector;

namespace SomineApi.Infrastructure.Entities;

/// <summary>
/// Bir item'ın semantik arama vektörü. PostgreSQL'e özgü (pgvector) olduğu için
/// bilinçli olarak Domain yerine Infrastructure katmanında yaşar ve model'e
/// yalnızca Npgsql provider'ında dahil edilir (SQLite testlerinde map dışıdır).
/// </summary>
public class ItemEmbedding
{
    public Guid ItemId { get; set; }
    public Vector Embedding { get; set; } = null!;
    public string Model { get; set; } = string.Empty;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
}
