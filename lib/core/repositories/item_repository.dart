import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:somine_app/core/models/item_model.dart';

class ItemRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _itemsCollection =>
      _firestore.collection('items');

  /// Get all items for a user
  Future<List<ItemModel>> getItems(String userId, {String? categoryId}) async {
    try {
      Query<Map<String, dynamic>> query =
          _itemsCollection.where('userId', isEqualTo: userId);

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      final snapshot = await query.get();

      final items = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .where((item) => !item.isDeleted) // Client-side filter for legacy data
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting items: $e');
      rethrow;
    }
  }

  /// Get PAGINATED items
  Future<QuerySnapshot<Map<String, dynamic>>> getItemsPaginated(String userId, {String? categoryId, int limit = 5, DocumentSnapshot? startAfter}) async {
    try {
      Query<Map<String, dynamic>> query =
          _itemsCollection.where('userId', isEqualTo: userId);

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }
      
      // Order by createdAt desc for feed
      query = query.orderBy('createdAt', descending: true);

      if (startAfter != null) {
          query = query.startAfterDocument(startAfter);
      }
      
      return await query.limit(limit).get();
    } catch (e) {
       debugPrint('❌ [ItemRepository] Error fetching paginated items: $e');
       rethrow;
    }
  }

  /// Get item by ID
  Future<ItemModel?> getItem(String itemId) async {
    try {
      final doc = await _itemsCollection.doc(itemId).get();
      if (doc.exists) {
        return ItemModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting item: $e');
      rethrow;
    }
  }

  /// Create a new item
  Future<ItemModel> createItem(ItemModel item) async {
    try {
      debugPrint('🔵 [ItemRepository] Creating item...');
      final docRef = await _itemsCollection.add(item.toFirestore()).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Bağlantı zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin.');
        },
      );
      debugPrint('✅ [ItemRepository] Item created: ${docRef.id}');

      final doc = await docRef.get();
      return ItemModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error creating item: $e');
      rethrow;
    }
  }

  /// Update an item
  Future<void> updateItem(ItemModel item) async {
    try {
      await _itemsCollection.doc(item.id).update({
        'categoryId': item.categoryId,
        'note': item.note,
        'url': item.url, // Added URL update
        'isFavorite': item.isFavorite,
        'ogMetadata': item.ogMetadata?.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [ItemRepository] Item updated: ${item.id}');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error updating item: $e');
      rethrow;
    }
  }

  /// Toggle favorite status
  Future<void> toggleFavorite(String itemId, bool isFavorite) async {
    try {
      await _itemsCollection.doc(itemId).update({
        'isFavorite': isFavorite,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [ItemRepository] Item favorite toggled: $itemId -> $isFavorite');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error toggling favorite: $e');
      rethrow;
    }
  }

  /// Move item to a different category
  Future<void> moveToCategory(String itemId, String? categoryId) async {
    try {
      await _itemsCollection.doc(itemId).update({
        'categoryId': categoryId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [ItemRepository] Item moved to category: $itemId -> $categoryId');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error moving item: $e');
      rethrow;
    }
  }

  /// Delete an item
  Future<void> deleteItem(String itemId) async {
    try {
      // Soft delete
      await _itemsCollection.doc(itemId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [ItemRepository] Item soft deleted: $itemId');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error deleting item: $e');
      rethrow;
    }
  }

  /// Delete all items in a category (SOFT DELETE - moves to Recently Deleted)
  Future<void> deleteItemsInCategory(String categoryId) async {
    try {
      final snapshot = await _itemsCollection
          .where('categoryId', isEqualTo: categoryId)
          .where('isDeleted', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();

      debugPrint('✅ [ItemRepository] Items in category SOFT deleted: $categoryId (${snapshot.docs.length} items)');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error deleting items in category: $e');
      rethrow;
    }
  }

  /// Soft delete multiple items by IDs (for bulk selection delete)
  Future<void> softDeleteItems(List<String> itemIds) async {
    try {
      if (itemIds.isEmpty) return;
      
      final batch = _firestore.batch();
      for (final id in itemIds) {
        batch.update(_itemsCollection.doc(id), {
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      debugPrint('✅ [ItemRepository] Batch soft deleted ${itemIds.length} items');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error batch deleting items: $e');
      rethrow;
    }
  }

  /// Search items by text
  Future<List<ItemModel>> searchItems(String userId, String query) async {
    try {
      // Note: Firestore doesn't support full-text search
      // This is a simple implementation that searches in notes
      // For production, consider using Algolia or similar
      final snapshot = await _itemsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final lowerQuery = query.toLowerCase();
      final items = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .where((item) => !item.isDeleted) // Client-side filter
          .where((item) {
            final title = item.displayTitle.toLowerCase();
            final note = item.note?.toLowerCase() ?? '';
            final url = item.url?.toLowerCase() ?? '';
            return title.contains(lowerQuery) ||
                note.contains(lowerQuery) ||
                url.contains(lowerQuery);
          })
          .toList();
      
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error searching items: $e');
      rethrow;
    }
  }

  /// Get favorite items
  Future<List<ItemModel>> getFavoriteItems(String userId) async {
    try {
      final snapshot = await _itemsCollection
          .where('userId', isEqualTo: userId)
          .where('isFavorite', isEqualTo: true)
          .get();

      final items = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .where((item) => !item.isDeleted)
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting favorite items: $e');
      rethrow;
    }
  }

  /// Stream items for a user
  Stream<List<ItemModel>> streamItems(String userId, {String? categoryId}) {
    Query<Map<String, dynamic>> query =
        _itemsCollection.where('userId', isEqualTo: userId);

    if (categoryId != null) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.snapshots().map((snapshot) {
      final items = snapshot.docs
          .map((doc) => ItemModel.fromFirestore(doc))
          .where((item) => !item.isDeleted)
          .toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    });
  }

  /// Get item count for a user
  Future<int> getItemCount(String userId) async {
    try {
      final snapshot = await _itemsCollection
          .where('userId', isEqualTo: userId)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting item count: $e');
      return 0;
    }
  }

  /// Get Uncategorized (Quick) item count
  Future<int> getUncategorizedItemCount(String userId) async {
    try {
      int count = 0;

      // 1. Check for literal NULL (legacy uncategorized)
      final nullSnap = await _itemsCollection
          .where('userId', isEqualTo: userId)
          .where('categoryId', isNull: true)
          .where('isDeleted', isEqualTo: false)
          .count()
          .get();
      count += (nullSnap.count ?? 0);

      // 2. Check for "Hızlı" (Quick) category items
      try {
        final categorySnap = await _firestore.collection('categories')
            .where('userId', isEqualTo: userId)
            .where('name', isEqualTo: 'Hızlı')
            .limit(1)
            .get();
            
        if (categorySnap.docs.isNotEmpty) {
          final quickCatId = categorySnap.docs.first.id;
          final quickSnap = await _itemsCollection
              .where('userId', isEqualTo: userId)
              .where('categoryId', isEqualTo: quickCatId)
              .where('isDeleted', isEqualTo: false)
              .count()
              .get();
          count += (quickSnap.count ?? 0);
        }
      } catch (e) {
        debugPrint('⚠️ Error fetching Quick category count: $e');
      }

      return count;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting pending item count: $e');
      return 0;
    }
  }

  /// Get active item count in a specific category
  Future<int> getActiveItemCountInCategory(String userId, String categoryId) async {
    try {
      final snapshot = await _itemsCollection
          .where('userId', isEqualTo: userId)
          .where('categoryId', isEqualTo: categoryId)
          .where('isDeleted', isEqualTo: false)
          .count()
          .get();
      
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting category item count: $e');
      return 0;
    }
  }

  /// Get Recent Items for Activity Feed
  Future<List<ItemModel>> getRecentItems(String userId, {int limit = 5}) async {
    try {
      final snapshot = await _itemsCollection
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting recent items: $e');
      return [];
    }
  }

  /// Stream Recent Items for Activity Feed
  Stream<List<ItemModel>> streamRecentItems(String userId, {int limit = 5}) {
    return _itemsCollection
        .where('userId', isEqualTo: userId)
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList());
  }

  /// Move all items from one category to another (or to Uncategorized if newCategoryId is null)
  Future<void> updateItemsCategory(String userId, String oldCategoryId, String? newCategoryId) async {
    try {
      final batch = _firestore.batch();
      
      final snapshot = await _itemsCollection
          .where('userId', isEqualTo: userId)
          .where('categoryId', isEqualTo: oldCategoryId)
          .where('isDeleted', isEqualTo: false) // Only active items
          .get();

      if (snapshot.docs.isEmpty) return; // Nothing to move

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'categoryId': newCategoryId});
      }

      await batch.commit();
      debugPrint('✅ [ItemRepository] Moved ${snapshot.docs.length} items from $oldCategoryId to $newCategoryId');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error moving items: $e');
      rethrow;
    }
  }

  /// RESTORE a soft-deleted item
  Future<void> restoreItem(String itemId) async {
    try {
      await _itemsCollection.doc(itemId).update({
        'isDeleted': false,
        'deletedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [ItemRepository] Item restored: $itemId');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error restoring item: $e');
      rethrow;
    }
  }

  /// PERMANENTLY delete an item
  Future<void> permanentDeleteItem(String itemId) async {
    try {
      await _itemsCollection.doc(itemId).delete();
      debugPrint('✅ [ItemRepository] Item permanently deleted: $itemId');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error permanently deleting item: $e');
      rethrow;
    }
  }

  /// Get DELETED items (for Recently Deleted screen)
  Future<List<ItemModel>> getDeletedItems(String userId) async {
    try {
      final snapshot = await _itemsCollection
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: true)
          .orderBy('deletedAt', descending: true)
          .get();

      final items = snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
      return items;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting deleted items: $e');
      rethrow;
    }
  }

  /// Delete ALL items for a user (for account deletion)
  Future<void> deleteAllUserItems(String userId) async {
    try {
      final snapshot = await _itemsCollection
          .where('userId', isEqualTo: userId)
          .get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      debugPrint('✅ [ItemRepository] All items deleted for user: $userId (${snapshot.docs.length} items)');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error deleting all user items: $e');
      rethrow;
    }
  }

  /// Cleanup items deleted more than 30 days ago (auto-expiry)
  Future<int> cleanupExpiredDeletedItems(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      
      final snapshot = await _itemsCollection
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: true)
          .where('deletedAt', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      if (snapshot.docs.isEmpty) {
        return 0;
      }

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      debugPrint('✅ [ItemRepository] Cleaned up ${snapshot.docs.length} expired deleted items for user: $userId');
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error cleaning up expired items: $e');
      return 0;
    }
  }

  /// Belirtilen öğeleri başka bir kullanıcının koleksiyonuna kopyala (bağımsız kopya)
  Future<int> copyItemsToCollection({
    required List<String> itemIds,
    required String targetUserId,
    required String targetCategoryId,
  }) async {
    try {
      int copiedCount = 0;
      final batch = _firestore.batch();

      for (final itemId in itemIds) {
        final originalDoc = await _itemsCollection.doc(itemId).get();
        if (!originalDoc.exists) continue;

        final originalItem = ItemModel.fromFirestore(originalDoc);
        
        // Bağımsız kopya oluştur
        final copiedItem = originalItem.copyWith(
          userId: targetUserId,
          categoryId: targetCategoryId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isDeleted: false,
          deletedAt: null,
        );

        final newDocRef = _itemsCollection.doc();
        batch.set(newDocRef, copiedItem.toFirestore());
        copiedCount++;
      }

      await batch.commit();
      debugPrint('✅ [ItemRepository] Copied $copiedCount items to collection: $targetCategoryId');
      return copiedCount;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error copying items: $e');
      rethrow;
    }
  }

  /// Belirli bir koleksiyondaki tüm öğeleri getir (paylaşım görüntüleme için)
  Future<List<ItemModel>> getItemsByCategory(String userId, String categoryId) async {
    try {
      final snapshot = await _itemsCollection
          .where('userId', isEqualTo: userId)
          .where('categoryId', isEqualTo: categoryId)
          .where('isDeleted', isEqualTo: false)
          .get();

      final items = snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting items by category: $e');
      rethrow;
    }
  }
}
