using FirebaseAdmin.Auth;
using Google.Cloud.Firestore;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using SomineApi.Domain.Entities;
using SomineApi.Domain.Enums;
using SomineApi.Infrastructure.Data;
using System.Text.Json;

internal sealed class FirebaseContentMigrationRunner(
    SomineDbContext dbContext,
    FirestoreDb firestoreDb,
    FirebaseAuth firebaseAuth,
    ILogger<FirebaseContentMigrationRunner> logger)
{
    private const string NamespaceRoot = "somine/firebase";

    public async Task<int> RunAsync(FirebaseMigrationOptions options, CancellationToken cancellationToken)
    {
        logger.LogInformation("Migration started. Mode={Mode}, Modules={Modules}, IncludeAuthUsers={IncludeAuthUsers}",
            options.Commit ? "commit" : "dry-run",
            string.Join(",", options.Modules),
            options.IncludeFirebaseAuthUsers);

        await dbContext.Database.CanConnectAsync(cancellationToken);

        var report = new FirebaseMigrationReport();

        await using var transaction = await dbContext.Database.BeginTransactionAsync(cancellationToken);

        try
        {
            var usersByFirebaseUid = await dbContext.Users
                .AsNoTracking()
                .ToDictionaryAsync(user => user.FirebaseUid, user => user.Id, StringComparer.Ordinal, cancellationToken);

            if (options.ShouldRun("users"))
            {
                usersByFirebaseUid = await ImportFirestoreUsersAsync(report, cancellationToken);

                if (options.IncludeFirebaseAuthUsers)
                {
                    usersByFirebaseUid = await ImportFirebaseAuthUsersAsync(report, usersByFirebaseUid, options.AuthPageSize, cancellationToken);
                }
            }

            if (options.ShouldRun("categories"))
            {
                await ImportCategoriesAsync(report, usersByFirebaseUid, cancellationToken);
            }

            if (options.ShouldRun("items"))
            {
                await ImportItemsAsync(report, usersByFirebaseUid, cancellationToken);
            }

            if (options.ShouldRun("reminders"))
            {
                await ImportRemindersAsync(report, cancellationToken);
            }

            if (options.ShouldRun("notifications"))
            {
                await ImportNotificationsAsync(report, usersByFirebaseUid, cancellationToken);
            }

            if (options.ShouldRun("shares"))
            {
                await ImportSharesAsync(report, usersByFirebaseUid, cancellationToken);
            }

            await dbContext.SaveChangesAsync(cancellationToken);

            if (options.Commit)
            {
                await transaction.CommitAsync(cancellationToken);
            }
            else
            {
                await transaction.RollbackAsync(cancellationToken);
            }

            LogSummary(report, options.Commit);
            return 0;
        }
        catch (Exception ex)
        {
            await transaction.RollbackAsync(cancellationToken);
            logger.LogError(ex, "Migration failed.");
            return 1;
        }
    }

    private async Task<Dictionary<string, Guid>> ImportFirestoreUsersAsync(FirebaseMigrationReport report, CancellationToken cancellationToken)
    {
        var counters = report.For("users");
        var userSnapshots = await firestoreDb.Collection("users").GetSnapshotAsync(cancellationToken);

        foreach (var document in userSnapshots.Documents)
        {
            var sourceUser = document.ToDictionary();
            var firebaseUid = document.Id.Trim();
            if (string.IsNullOrWhiteSpace(firebaseUid))
            {
                counters.Skipped++;
                report.AddWarning("Encountered a Firestore user document with empty uid.");
                continue;
            }

            var existingUser = await dbContext.Users.FirstOrDefaultAsync(user => user.FirebaseUid == firebaseUid, cancellationToken);
            var normalizedUsername = await ResolveUsernameAsync(
                GetOptionalString(sourceUser, "username"),
                existingUser?.Id,
                firebaseUid,
                cancellationToken);

            if (existingUser is null)
            {
                existingUser = new User
                {
                    Id = DeterministicGuid.Create($"{NamespaceRoot}/users", firebaseUid),
                    FirebaseUid = firebaseUid
                };

                dbContext.Users.Add(existingUser);
                counters.Created++;
            }
            else
            {
                counters.Updated++;
            }

            existingUser.Email = GetOptionalString(sourceUser, "email") ?? existingUser.Email;
            existingUser.DisplayName = GetOptionalString(sourceUser, "displayName") ?? existingUser.DisplayName;
            existingUser.Username = normalizedUsername;
            existingUser.PhotoUrl = GetOptionalString(sourceUser, "photoURL") ?? existingUser.PhotoUrl;
            existingUser.PhotoBase64 = GetOptionalString(sourceUser, "photoBase64") ?? existingUser.PhotoBase64;
            existingUser.SearchHistoryJson = await ReadSearchHistoryJsonAsync(document, cancellationToken) ?? existingUser.SearchHistoryJson;
            existingUser.CreatedAt = GetOptionalDateTime(sourceUser, "createdAt") ?? existingUser.CreatedAt;
            existingUser.UpdatedAt = GetOptionalDateTime(sourceUser, "updatedAt") ?? existingUser.UpdatedAt;
        }

        await dbContext.SaveChangesAsync(cancellationToken);

        return await dbContext.Users
            .AsNoTracking()
            .ToDictionaryAsync(user => user.FirebaseUid, user => user.Id, StringComparer.Ordinal, cancellationToken);
    }

    private async Task<Dictionary<string, Guid>> ImportFirebaseAuthUsersAsync(
        FirebaseMigrationReport report,
        Dictionary<string, Guid> usersByFirebaseUid,
        int authPageSize,
        CancellationToken cancellationToken)
    {
        var counters = report.For("users");
        string? pageToken = null;

        do
        {
            var page = await firebaseAuth.ListUsersAsync(new ListUsersOptions
            {
                PageSize = authPageSize,
                PageToken = pageToken
            }).ReadPageAsync(authPageSize, cancellationToken);

            foreach (var authUser in page)
            {
                if (usersByFirebaseUid.ContainsKey(authUser.Uid))
                {
                    var existingUser = await dbContext.Users.FirstAsync(user => user.FirebaseUid == authUser.Uid, cancellationToken);
                    var normalizedUsername = await ResolveUsernameAsync(existingUser.Username, existingUser.Id, authUser.Uid, cancellationToken);

                    existingUser.Email ??= authUser.Email;
                    existingUser.DisplayName ??= authUser.DisplayName;
                    existingUser.PhotoUrl ??= authUser.PhotoUrl;
                    existingUser.Username = normalizedUsername;
                    existingUser.CreatedAt = authUser.UserMetaData?.CreationTimestamp ?? existingUser.CreatedAt;
                    existingUser.UpdatedAt = authUser.UserMetaData?.LastSignInTimestamp ?? existingUser.UpdatedAt;

                    counters.Updated++;
                    continue;
                }

                var createdUser = new User
                {
                    Id = DeterministicGuid.Create($"{NamespaceRoot}/users", authUser.Uid),
                    FirebaseUid = authUser.Uid,
                    Email = authUser.Email,
                    DisplayName = authUser.DisplayName,
                    PhotoUrl = authUser.PhotoUrl,
                    CreatedAt = authUser.UserMetaData?.CreationTimestamp ?? DateTime.UtcNow,
                    UpdatedAt = authUser.UserMetaData?.LastSignInTimestamp ?? authUser.UserMetaData?.CreationTimestamp ?? DateTime.UtcNow
                };

                dbContext.Users.Add(createdUser);
                counters.Created++;
                usersByFirebaseUid[authUser.Uid] = createdUser.Id;
            }

            await dbContext.SaveChangesAsync(cancellationToken);
            pageToken = page.NextPageToken;
        }
        while (!string.IsNullOrWhiteSpace(pageToken));

        return await dbContext.Users
            .AsNoTracking()
            .ToDictionaryAsync(user => user.FirebaseUid, user => user.Id, StringComparer.Ordinal, cancellationToken);
    }

    private async Task ImportCategoriesAsync(
        FirebaseMigrationReport report,
        IReadOnlyDictionary<string, Guid> usersByFirebaseUid,
        CancellationToken cancellationToken)
    {
        var counters = report.For("categories");
        var snapshots = await firestoreDb.Collection("categories").GetSnapshotAsync(cancellationToken);

        foreach (var document in snapshots.Documents)
        {
            var sourceCategory = document.ToDictionary();
            var sourceUserId = GetRequiredString(sourceCategory, "userId");

            if (!usersByFirebaseUid.TryGetValue(sourceUserId, out var targetUserId))
            {
                counters.Skipped++;
                report.AddWarning($"Category {document.Id} skipped because user {sourceUserId} was not found.");
                continue;
            }

            var categoryId = DeterministicGuid.Create($"{NamespaceRoot}/categories", document.Id);
            var existingCategory = await dbContext.Categories.FindAsync([categoryId], cancellationToken);

            if (existingCategory is null)
            {
                existingCategory = new Category
                {
                    Id = categoryId
                };

                dbContext.Categories.Add(existingCategory);
                counters.Created++;
            }
            else
            {
                counters.Updated++;
            }

            existingCategory.UserId = targetUserId;
            existingCategory.Name = GetRequiredString(sourceCategory, "name");
            existingCategory.Icon = GetOptionalString(sourceCategory, "icon");
            existingCategory.Color = GetOptionalString(sourceCategory, "color");
            existingCategory.SortOrder = GetInt32(sourceCategory, "order") ?? 0;
            existingCategory.IsVault = GetBoolean(sourceCategory, "isVault") ?? false;
            existingCategory.CreatedAt = GetOptionalDateTime(sourceCategory, "createdAt") ?? existingCategory.CreatedAt;
            existingCategory.UpdatedAt = GetOptionalDateTime(sourceCategory, "updatedAt") ?? existingCategory.UpdatedAt;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task ImportItemsAsync(
        FirebaseMigrationReport report,
        IReadOnlyDictionary<string, Guid> usersByFirebaseUid,
        CancellationToken cancellationToken)
    {
        var counters = report.For("items");
        var snapshots = await firestoreDb.Collection("items").GetSnapshotAsync(cancellationToken);

        foreach (var document in snapshots.Documents)
        {
            var sourceItem = document.ToDictionary();
            var sourceUserId = GetRequiredString(sourceItem, "userId");

            if (!usersByFirebaseUid.TryGetValue(sourceUserId, out var targetUserId))
            {
                counters.Skipped++;
                report.AddWarning($"Item {document.Id} skipped because user {sourceUserId} was not found.");
                continue;
            }

            Guid? targetCategoryId = null;
            var sourceCategoryId = GetOptionalString(sourceItem, "categoryId");
            if (!string.IsNullOrWhiteSpace(sourceCategoryId))
            {
                var deterministicCategoryId = DeterministicGuid.Create($"{NamespaceRoot}/categories", sourceCategoryId);
                var categoryExists = await dbContext.Categories.AsNoTracking().AnyAsync(category => category.Id == deterministicCategoryId, cancellationToken);
                if (categoryExists)
                {
                    targetCategoryId = deterministicCategoryId;
                }
                else
                {
                    report.AddWarning($"Item {document.Id} references missing category {sourceCategoryId}; category_id set to null.");
                }
            }

            var itemId = DeterministicGuid.Create($"{NamespaceRoot}/items", document.Id);
            var existingItem = await dbContext.Items
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(item => item.Id == itemId, cancellationToken);

            if (existingItem is null)
            {
                existingItem = new Item
                {
                    Id = itemId
                };

                dbContext.Items.Add(existingItem);
                counters.Created++;
            }
            else
            {
                counters.Updated++;
            }

            var ogMetadata = GetDictionary(sourceItem, "ogMetadata");
            existingItem.UserId = targetUserId;
            existingItem.CategoryId = targetCategoryId;
            existingItem.Type = ParseItemType(GetOptionalString(sourceItem, "type"));
            existingItem.Url = GetOptionalString(sourceItem, "url");
            existingItem.Note = GetOptionalString(sourceItem, "note");
            existingItem.ImageUrl = GetOptionalString(sourceItem, "imageUrl");
            existingItem.OgTitle = GetOptionalString(ogMetadata, "title");
            existingItem.OgDescription = GetOptionalString(ogMetadata, "description");
            existingItem.OgImageUrl = GetOptionalString(ogMetadata, "imageUrl");
            existingItem.OgSiteName = GetOptionalString(ogMetadata, "siteName");
            existingItem.OgFaviconUrl = GetOptionalString(ogMetadata, "faviconUrl");
            existingItem.IsFavorite = GetBoolean(sourceItem, "isFavorite") ?? false;
            existingItem.SortOrder = GetInt32(sourceItem, "order") ?? 0;
            existingItem.IsDeleted = GetBoolean(sourceItem, "isDeleted") ?? false;
            existingItem.DeletedAt = GetOptionalDateTime(sourceItem, "deletedAt");
            existingItem.HasReminder = GetBoolean(sourceItem, "hasReminder") ?? false;
            existingItem.CreatedAt = GetOptionalDateTime(sourceItem, "createdAt") ?? existingItem.CreatedAt;
            existingItem.UpdatedAt = GetOptionalDateTime(sourceItem, "updatedAt") ?? existingItem.UpdatedAt;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task ImportRemindersAsync(FirebaseMigrationReport report, CancellationToken cancellationToken)
    {
        var counters = report.For("reminders");
        var snapshots = await firestoreDb.Collection("reminders").GetSnapshotAsync(cancellationToken);

        foreach (var document in snapshots.Documents)
        {
            var sourceReminder = document.ToDictionary();
            var sourceItemId = GetRequiredString(sourceReminder, "itemId");
            var targetItemId = DeterministicGuid.Create($"{NamespaceRoot}/items", sourceItemId);
            var targetItem = await dbContext.Items
                .IgnoreQueryFilters()
                .FirstOrDefaultAsync(item => item.Id == targetItemId, cancellationToken);

            if (targetItem is null)
            {
                counters.Skipped++;
                report.AddWarning($"Reminder {document.Id} skipped because item {sourceItemId} was not found.");
                continue;
            }

            var reminderId = DeterministicGuid.Create($"{NamespaceRoot}/reminders", document.Id);
            var existingReminder = await dbContext.Reminders.FindAsync([reminderId], cancellationToken);

            if (existingReminder is null)
            {
                existingReminder = new Reminder
                {
                    Id = reminderId
                };

                dbContext.Reminders.Add(existingReminder);
                counters.Created++;
            }
            else
            {
                counters.Updated++;
            }

            var reminderTime = GetDictionary(sourceReminder, "reminderTime");
            var reminderDate = GetOptionalDateTime(sourceReminder, "reminderDate")?.Date ?? targetItem.CreatedAt.Date;

            existingReminder.ItemId = targetItemId;
            existingReminder.ReminderDate = DateOnly.FromDateTime(reminderDate);
            existingReminder.ReminderHour = GetInt32(reminderTime, "hour") ?? 0;
            existingReminder.ReminderMinute = GetInt32(reminderTime, "minute") ?? 0;
            existingReminder.RepeatType = ParseRepeatType(GetOptionalString(sourceReminder, "repeat"));
            existingReminder.IsActive = GetBoolean(sourceReminder, "isActive") ?? true;
            existingReminder.CreatedAt = GetOptionalDateTime(sourceReminder, "createdAt") ?? existingReminder.CreatedAt;
            existingReminder.LastTriggered = GetOptionalDateTime(sourceReminder, "lastTriggered");
            existingReminder.CustomRepeatDays = GetInt32(sourceReminder, "customRepeatDays");
            existingReminder.CustomRepeatMinutes = GetInt32(sourceReminder, "customRepeatMinutes");

            targetItem.HasReminder = true;
            targetItem.ReminderId = reminderId;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task ImportNotificationsAsync(
        FirebaseMigrationReport report,
        IReadOnlyDictionary<string, Guid> usersByFirebaseUid,
        CancellationToken cancellationToken)
    {
        var counters = report.For("notifications");
        var snapshots = await firestoreDb.Collection("notifications").GetSnapshotAsync(cancellationToken);

        foreach (var document in snapshots.Documents)
        {
            var sourceNotification = document.ToDictionary();
            var sourceUserId = GetRequiredString(sourceNotification, "userId");

            if (!usersByFirebaseUid.TryGetValue(sourceUserId, out var targetUserId))
            {
                counters.Skipped++;
                report.AddWarning($"Notification {document.Id} skipped because user {sourceUserId} was not found.");
                continue;
            }

            var notificationId = DeterministicGuid.Create($"{NamespaceRoot}/notifications", document.Id);
            var existingNotification = await dbContext.Notifications.FindAsync([notificationId], cancellationToken);

            if (existingNotification is null)
            {
                existingNotification = new Notification
                {
                    Id = notificationId
                };

                dbContext.Notifications.Add(existingNotification);
                counters.Created++;
            }
            else
            {
                counters.Updated++;
            }

            var notificationData = GetDictionary(sourceNotification, "data");

            existingNotification.UserId = targetUserId;
            existingNotification.Type = GetOptionalString(sourceNotification, "type") ?? "shareRequest";
            existingNotification.Title = GetOptionalString(sourceNotification, "title") ?? string.Empty;
            existingNotification.Message = GetOptionalString(sourceNotification, "message") ?? string.Empty;
            existingNotification.Data = JsonSerializer.SerializeToDocument(NormalizeForJson(notificationData));
            existingNotification.IsRead = GetBoolean(sourceNotification, "isRead") ?? false;
            existingNotification.CreatedAt = GetOptionalDateTime(sourceNotification, "createdAt") ?? existingNotification.CreatedAt;
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task ImportSharesAsync(
        FirebaseMigrationReport report,
        IReadOnlyDictionary<string, Guid> usersByFirebaseUid,
        CancellationToken cancellationToken)
    {
        var counters = report.For("shares");
        var snapshots = await firestoreDb.Collection("collection_shares").GetSnapshotAsync(cancellationToken);

        foreach (var document in snapshots.Documents)
        {
            var sourceShare = document.ToDictionary();
            var sourceFromUserId = GetRequiredString(sourceShare, "fromUserId");
            var sourceToUserId = GetRequiredString(sourceShare, "toUserId");
            var sourceCategoryId = GetRequiredString(sourceShare, "categoryId");

            if (!usersByFirebaseUid.TryGetValue(sourceFromUserId, out var targetFromUserId))
            {
                counters.Skipped++;
                report.AddWarning($"Share {document.Id} skipped because sender {sourceFromUserId} was not found.");
                continue;
            }

            if (!usersByFirebaseUid.TryGetValue(sourceToUserId, out var targetToUserId))
            {
                counters.Skipped++;
                report.AddWarning($"Share {document.Id} skipped because target user {sourceToUserId} was not found.");
                continue;
            }

            var targetCategoryId = DeterministicGuid.Create($"{NamespaceRoot}/categories", sourceCategoryId);
            var categoryExists = await dbContext.Categories.AsNoTracking().AnyAsync(category => category.Id == targetCategoryId, cancellationToken);
            if (!categoryExists)
            {
                counters.Skipped++;
                report.AddWarning($"Share {document.Id} skipped because category {sourceCategoryId} was not found.");
                continue;
            }

            var shareId = DeterministicGuid.Create($"{NamespaceRoot}/shares", document.Id);
            var existingShare = await dbContext.CollectionShares.FindAsync([shareId], cancellationToken);

            if (existingShare is null)
            {
                existingShare = new CollectionShare
                {
                    Id = shareId
                };

                dbContext.CollectionShares.Add(existingShare);
                counters.Created++;
            }
            else
            {
                counters.Updated++;
            }

            existingShare.FromUserId = targetFromUserId;
            existingShare.ToUserId = targetToUserId;
            existingShare.CategoryId = targetCategoryId;
            existingShare.FromUserName = GetOptionalString(sourceShare, "fromUserName");
            existingShare.FromUserEmail = GetOptionalString(sourceShare, "fromUserEmail");
            existingShare.ToUserEmail = GetOptionalString(sourceShare, "toUserEmail");
            existingShare.CategoryName = GetOptionalString(sourceShare, "categoryName");
            existingShare.Status = ParseShareStatus(GetOptionalString(sourceShare, "status"));
            existingShare.CreatedAt = GetOptionalDateTime(sourceShare, "createdAt") ?? existingShare.CreatedAt;
            existingShare.AcceptedAt = GetOptionalDateTime(sourceShare, "acceptedAt");
            existingShare.RejectedAt = GetOptionalDateTime(sourceShare, "rejectedAt");
        }

        await dbContext.SaveChangesAsync(cancellationToken);
    }

    private async Task<string?> ResolveUsernameAsync(
        string? requestedUsername,
        Guid? existingUserId,
        string fallbackSeed,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(requestedUsername))
        {
            return null;
        }

        var normalized = requestedUsername.Trim().ToLowerInvariant();
        var conflictingUser = await dbContext.Users
            .AsNoTracking()
            .Where(user => user.Username == normalized)
            .Select(user => new { user.Id, user.Username })
            .FirstOrDefaultAsync(cancellationToken);

        if (conflictingUser is null || conflictingUser.Id == existingUserId)
        {
            return normalized;
        }

        var suffix = fallbackSeed.Length >= 6 ? fallbackSeed[..6].ToLowerInvariant() : fallbackSeed.ToLowerInvariant();
        var candidate = $"{normalized}_{suffix}";
        if (candidate.Length > 64)
        {
            candidate = candidate[..64];
        }

        var collision = await dbContext.Users
            .AsNoTracking()
            .AnyAsync(user => user.Username == candidate && user.Id != existingUserId, cancellationToken);

        if (!collision)
        {
            logger.LogWarning("Username {Username} duplicated. Using fallback {FallbackUsername}.", normalized, candidate);
            return candidate;
        }

        logger.LogWarning("Username {Username} duplicated more than once. Username cleared for {FallbackSeed}.", normalized, fallbackSeed);
        return null;
    }

    private static async Task<string?> ReadSearchHistoryJsonAsync(DocumentSnapshot userDocument, CancellationToken cancellationToken)
    {
        var searchHistoryDocument = await userDocument.Reference
            .Collection("metadata")
            .Document("search_history")
            .GetSnapshotAsync(cancellationToken);

        if (!searchHistoryDocument.Exists)
        {
            return null;
        }

        var source = searchHistoryDocument.ToDictionary();
        if (!source.TryGetValue("terms", out var termsValue) || termsValue is not IEnumerable<object> terms)
        {
            return null;
        }

        var normalizedTerms = terms
            .Select(term => term?.ToString()?.Trim())
            .Where(term => !string.IsNullOrWhiteSpace(term))
            .Cast<string>()
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(10)
            .ToList();

        return normalizedTerms.Count == 0
            ? null
            : JsonSerializer.Serialize(normalizedTerms);
    }

    private static object? NormalizeForJson(object? value)
    {
        return value switch
        {
            null => null,
            Timestamp timestamp => timestamp.ToDateTime(),
            IDictionary<string, object> dictionary => dictionary.ToDictionary(pair => pair.Key, pair => NormalizeForJson(pair.Value)),
            IEnumerable<object> list => list.Select(NormalizeForJson).ToList(),
            _ => value
        };
    }

    private static Dictionary<string, object> GetDictionary(IDictionary<string, object> source, string fieldName)
    {
        if (!source.TryGetValue(fieldName, out var value) || value is not IDictionary<string, object> dictionary)
        {
            return [];
        }

        return dictionary.ToDictionary(pair => pair.Key, pair => pair.Value);
    }

    private static string GetRequiredString(IDictionary<string, object> source, string fieldName)
    {
        var value = GetOptionalString(source, fieldName);
        if (string.IsNullOrWhiteSpace(value))
        {
            throw new InvalidOperationException($"Field {fieldName} is required.");
        }

        return value;
    }

    private static string? GetOptionalString(IDictionary<string, object> source, string fieldName)
    {
        if (!source.TryGetValue(fieldName, out var value) || value is null)
        {
            return null;
        }

        return value switch
        {
            string stringValue => string.IsNullOrWhiteSpace(stringValue) ? null : stringValue.Trim(),
            _ => value.ToString()
        };
    }

    private static int? GetInt32(IDictionary<string, object> source, string fieldName)
    {
        if (!source.TryGetValue(fieldName, out var value) || value is null)
        {
            return null;
        }

        return value switch
        {
            int intValue => intValue,
            long longValue => (int)longValue,
            double doubleValue => (int)doubleValue,
            _ when int.TryParse(value.ToString(), out var parsed) => parsed,
            _ => null
        };
    }

    private static bool? GetBoolean(IDictionary<string, object> source, string fieldName)
    {
        if (!source.TryGetValue(fieldName, out var value) || value is null)
        {
            return null;
        }

        return value switch
        {
            bool boolValue => boolValue,
            _ when bool.TryParse(value.ToString(), out var parsed) => parsed,
            _ => null
        };
    }

    private static DateTime? GetOptionalDateTime(IDictionary<string, object> source, string fieldName)
    {
        if (!source.TryGetValue(fieldName, out var value) || value is null)
        {
            return null;
        }

        return value switch
        {
            Timestamp timestamp => timestamp.ToDateTime(),
            DateTime dateTime => DateTime.SpecifyKind(dateTime, DateTimeKind.Utc),
            _ when DateTime.TryParse(value.ToString(), out var parsed) => DateTime.SpecifyKind(parsed, DateTimeKind.Utc),
            _ => null
        };
    }

    private static ItemType ParseItemType(string? value)
    {
        return Enum.TryParse<ItemType>(value, ignoreCase: true, out var parsed)
            ? parsed
            : ItemType.Link;
    }

    private static RepeatFrequency ParseRepeatType(string? value)
    {
        return Enum.TryParse<RepeatFrequency>(value, ignoreCase: true, out var parsed)
            ? parsed
            : RepeatFrequency.None;
    }

    private static ShareStatus ParseShareStatus(string? value)
    {
        return Enum.TryParse<ShareStatus>(value, ignoreCase: true, out var parsed)
            ? parsed
            : ShareStatus.Pending;
    }

    private void LogSummary(FirebaseMigrationReport report, bool committed)
    {
        logger.LogInformation("Migration finished. Persisted={Persisted}", committed);

        foreach (var (module, counters) in report.Modules.OrderBy(pair => pair.Key, StringComparer.OrdinalIgnoreCase))
        {
            logger.LogInformation(
                "Module={Module} Created={Created} Updated={Updated} Skipped={Skipped}",
                module,
                counters.Created,
                counters.Updated,
                counters.Skipped);
        }

        foreach (var warning in report.Warnings.Take(50))
        {
            logger.LogWarning("{Warning}", warning);
        }

        if (report.Warnings.Count > 50)
        {
            logger.LogWarning("Additional warnings truncated: {Count}", report.Warnings.Count - 50);
        }
    }
}
