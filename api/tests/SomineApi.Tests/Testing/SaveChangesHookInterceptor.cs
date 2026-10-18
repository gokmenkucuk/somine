using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using SomineApi.Domain.Entities;

namespace SomineApi.Tests.Testing;

/// <summary>
/// SaveChanges öncesinde bir kez çalışan test kancası. Yeni bir User eklenmek
/// üzereyken devreye girer; eşzamanlı login yarışını deterministik olarak
/// simüle etmek için kullanılır (kanca içinde aynı firebase_uid'li satır
/// önceden eklenir, asıl SaveChanges unique ihlaliyle DbUpdateException fırlatır).
/// </summary>
public sealed class SaveChangesHookInterceptor : SaveChangesInterceptor
{
    public Func<Task>? OnSavingNewUserAsync { get; set; }

    public override async ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        var hook = OnSavingNewUserAsync;
        if (hook != null &&
            eventData.Context != null &&
            eventData.Context.ChangeTracker.Entries<User>().Any(entry => entry.State == EntityState.Added))
        {
            OnSavingNewUserAsync = null;
            await hook();
        }

        return await base.SavingChangesAsync(eventData, result, cancellationToken);
    }
}
