using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using SomineApi.Domain.Entities;
using SomineApi.Infrastructure.Entities;

namespace SomineApi.Infrastructure.Configurations;

/// <summary>
/// DİKKAT: Bu configuration assembly taramasından bilinçli olarak hariç tutulur
/// ve SomineDbContext.OnModelCreating içinde yalnızca Npgsql provider'ında
/// elle uygulanır (vector(512) kolonu SQLite'ta desteklenmez).
/// </summary>
public class ItemEmbeddingConfiguration : IEntityTypeConfiguration<ItemEmbedding>
{
    public void Configure(EntityTypeBuilder<ItemEmbedding> builder)
    {
        builder.ToTable("item_embeddings");

        builder.HasKey(e => e.ItemId);

        builder.Property(e => e.ItemId).HasColumnName("item_id").ValueGeneratedNever();
        builder.Property(e => e.Embedding).HasColumnName("embedding").HasColumnType("vector(512)").IsRequired();
        builder.Property(e => e.Model).HasColumnName("model").HasMaxLength(128).IsRequired();
        builder.Property(e => e.UpdatedAt).HasColumnName("updated_at");

        builder.HasOne<Item>()
            .WithMany()
            .HasForeignKey(e => e.ItemId)
            .OnDelete(DeleteBehavior.Cascade);

        // HNSW cosine index — pgvector'un EF Core eklentisi HasMethod/HasOperators ile üretir.
        builder.HasIndex(e => e.Embedding)
            .HasDatabaseName("ix_item_embeddings_embedding_hnsw_cosine")
            .HasMethod("hnsw")
            .HasOperators("vector_cosine_ops");
    }
}
