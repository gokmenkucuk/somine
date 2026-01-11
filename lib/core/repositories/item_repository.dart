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

      final items = snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
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
      await _itemsCollection.doc(itemId).delete();
      debugPrint('✅ [ItemRepository] Item deleted: $itemId');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error deleting item: $e');
      rethrow;
    }
  }

  /// Delete all items in a category
  Future<void> deleteItemsInCategory(String categoryId) async {
    try {
      final snapshot = await _itemsCollection
          .where('categoryId', isEqualTo: categoryId)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('✅ [ItemRepository] Items in category deleted: $categoryId');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error deleting items in category: $e');
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

      final items = snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
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
      final items = snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
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

  /// Move all items from one category to another (or to Uncategorized if newCategoryId is null)
  Future<void> updateItemsCategory(String userId, String oldCategoryId, String? newCategoryId) async {
    try {
      final batch = _firestore.batch();
      
      final snapshot = await _itemsCollection
          .where('userId', isEqualTo: userId)
          .where('categoryId', isEqualTo: oldCategoryId)
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
}


