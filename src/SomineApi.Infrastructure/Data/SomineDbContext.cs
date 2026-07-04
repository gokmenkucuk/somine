using Microsoft.EntityFrameworkCore;
using SomineApi.Domain.Entities;

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

        // Apply all configurations from assembly
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(SomineDbContext).Assembly);

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
