using Microsoft.EntityFrameworkCore;
using SomineApi.Domain.Entities;
using SomineApi.Infrastructure.Configurations;
using SomineApi.Infrastructure.Entities;
using System.Text.Json;

namespace SomineApi.Infrastructure.Data;

public class SomineDbContext : DbContext
{
    public SomineDbContext(DbContextOptions<SomineDbContext> options) : base(options)
    {
    }

    public DbSet<User> Users => Set<User>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Item> Items => Set<Item>();
    public DbSet<AuthSession> AuthSessions => Set<AuthSession>();
    public DbSet<UploadedFile> UploadedFiles => Set<UploadedFile>();
    public DbSet<CollectionShare> CollectionShares => Set<CollectionShare>();
    public DbSet<Notification> Notifications => Set<Notification>();
    public DbSet<Reminder> Reminders => Set<Reminder>();
    public DbSet<RequestLog> RequestLogs => Set<RequestLog>();
    public DbSet<ExceptionLog> ExceptionLogs => Set<ExceptionLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Apply all configurations from assembly.
        // ItemEmbeddingConfiguration hariç: vector(512) kolonu yalnızca Npgsql'de
        // map'lenir; SQLite (test) modelinde entity tamamen dışarıda bırakılır.
        modelBuilder.ApplyConfigurationsFromAssembly(
            typeof(SomineDbContext).Assembly,
            type => type != typeof(ItemEmbeddingConfiguration));

        if (Database.IsNpgsql())
        {
            modelBuilder.HasPostgresExtension("vector");

            // Trigram araması: pg_trgm benzerlik/index desteği, unaccent Türkçe
            // diyakritiklerinin (ü/ö/ç/ş/ğ/ı) normalize edilmesi için.
            modelBuilder.HasPostgresExtension("pg_trgm");
            modelBuilder.HasPostgresExtension("unaccent");

            // AddTrigramSearch migration'ında oluşturulan IMMUTABLE sarmalayıcı.
            // GIN trigram index ifadeleriyle sorgu ifadelerinin birebir eşleşmesini sağlar.
            modelBuilder
                .HasDbFunction(typeof(SomineDbFunctions).GetMethod(nameof(SomineDbFunctions.SearchNormalize))!)
                .HasName(SomineDbFunctions.SearchNormalizeFunctionName)
                .HasSchema("public");

            modelBuilder.ApplyConfiguration(new ItemEmbeddingConfiguration());
        }
        else
        {
            modelBuilder.Ignore<ItemEmbedding>();
        }

        if (Database.ProviderName == "Microsoft.EntityFrameworkCore.Sqlite")
        {
            modelBuilder.Entity<Notification>()
                .Property(n => n.Data)
                .HasConversion(
                    value => value == null ? null : value.RootElement.GetRawText(),
                    value => string.IsNullOrWhiteSpace(value) ? null : JsonDocument.Parse(value, new JsonDocumentOptions()))
                .HasColumnType("TEXT");
        }

        // Global query filter for soft delete on Items
        modelBuilder.Entity<Item>().HasQueryFilter(i => !i.IsDeleted);
    }

    public override int SaveChanges()
    {
        UpdateAuditableEntities();
        return base.SaveChanges();
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        UpdateAuditableEntities();
        return base.SaveChangesAsync(cancellationToken);
    }

    private void UpdateAuditableEntities()
    {
        foreach (var entry in ChangeTracker.Entries<Domain.Interfaces.IAuditableEntity>())
        {
            if (entry.State == EntityState.Modified)
            {
                entry.Entity.UpdatedAt = DateTime.UtcNow;
            }
        }
    }
}
