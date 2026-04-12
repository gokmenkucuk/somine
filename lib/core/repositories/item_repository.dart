import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';
import 'package:somine_app/core/services/backend_realtime_service.dart';
import 'package:somine_app/core/services/reminder_scheduler_service.dart';

class PaginatedItemsResult {
  const PaginatedItemsResult({
    required this.items,
    required this.hasMore,
    this.lastDocument,
    this.nextPage,
  });

  final List<ItemModel> items;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;
  final int? nextPage;
}

class ItemRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BackendAuthService _backendAuthService = BackendAuthService();
  final BackendRealtimeService _backendRealtimeService =
      BackendRealtimeService();
  final http.Client _httpClient = http.Client();

  CollectionReference<Map<String, dynamic>> get _itemsCollection =>
      _firestore.collection('items');

  Future<List<ItemModel>> getItems(String userId, {String? categoryId}) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        return _fetchAllItemsFromApi(userId, categoryId: categoryId);
      }

      Query<Map<String, dynamic>> query = _itemsCollection.where(
        'userId',
        isEqualTo: userId,
      );

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      final snapshot = await query.get();
      final items =
          snapshot.docs
              .map((doc) => ItemModel.fromFirestore(doc))
              .where((item) => !item.isDeleted)
              .toList();

      _sortItems(items);
      return items;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting items: $e');
      rethrow;
    }
  }

  Future<PaginatedItemsResult> getItemsPaginated(
    String userId, {
    String? categoryId,
    int limit = 5,
    int page = 1,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.get(
          _buildUri(
            '/api/items',
            queryParameters: {
              'page': '$page',
              'limit': '$limit',
              if (categoryId != null) 'categoryId': categoryId,
            },
          ),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'fetch paginated items');

        final payload = jsonDecode(response.body) as Map<String, dynamic>;
        final totalCount = payload['totalCount'] as int? ?? 0;
        final currentPage = payload['page'] as int? ?? page;
        final pageLimit = payload['limit'] as int? ?? limit;
        final items =
            (payload['items'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(
                  (json) =>
                      ItemModel.fromApi(json, userId: userId, isDeleted: false),
                )
                .toList();

        return PaginatedItemsResult(
          items: items,
          hasMore: currentPage * pageLimit < totalCount,
          nextPage: currentPage + 1,
        );
      }

      Query<Map<String, dynamic>> query = _itemsCollection.where(
        'userId',
        isEqualTo: userId,
      );

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      query = query.orderBy('order').orderBy('createdAt', descending: true);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.limit(limit).get();
      final items =
          snapshot.docs
              .map((doc) => ItemModel.fromFirestore(doc))
              .where((item) => !item.isDeleted)
              .toList();

      return PaginatedItemsResult(
        items: items,
        hasMore: snapshot.docs.length == limit,
        lastDocument: snapshot.docs.isEmpty ? startAfter : snapshot.docs.last,
      );
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error fetching paginated items: $e');
      rethrow;
    }
  }

  Future<ItemModel?> getItem(String itemId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        return _getItemFromApi(itemId, currentUserId);
      }

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

  Future<ItemModel> createItem(ItemModel item) async {
    try {
      if (_useBackendForCurrentUser(item.userId)) {
        return _createItemViaApi(item);
      }

      final docRef = await _itemsCollection
          .add(item.toFirestore())
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception(
                'Bağlantı zaman aşımına uğradı. Lütfen internet bağlantınızı kontrol edin.',
              );
            },
          );

      final doc = await docRef.get();
      return ItemModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error creating item: $e');
      rethrow;
    }
  }

  Future<void> updateItem(ItemModel item) async {
    try {
      if (_useBackendForCurrentUser(item.userId)) {
        await _updateItemViaApi(item.id, item.toApiUpdateRequest());
        return;
      }

      await _itemsCollection.doc(item.id).update({
        'categoryId': item.categoryId,
        'note': item.note,
        'url': item.url,
        'imageUrl': item.imageUrl,
        'isFavorite': item.isFavorite,
        'ogMetadata': item.ogMetadata?.toMap(),
        'reminderId': item.reminderId,
        'hasReminder': item.hasReminder,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error updating item: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(String itemId, bool isFavorite) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        await _updateItemViaApi(itemId, {'isFavorite': isFavorite});
        return;
      }

      await _itemsCollection.doc(itemId).update({
        'isFavorite': isFavorite,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error toggling favorite: $e');
      rethrow;
    }
  }

  Future<void> moveItemToCategory(String itemId, String categoryId) async {
    return moveToCategory(itemId, categoryId);
  }

  Future<void> moveToCategory(String itemId, String? categoryId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        await _updateItemViaApi(itemId, {
          if (categoryId != null) 'categoryId': categoryId,
          'clearCategory': categoryId == null,
        });
        return;
      }

      await _itemsCollection.doc(itemId).update({
        'categoryId': categoryId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error moving item: $e');
      rethrow;
    }
  }

  Future<void> moveItemsToCategory(
    List<String> itemIds,
    String targetCategoryId,
  ) async {
    try {
      if (itemIds.isEmpty) return;

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.post(
          _buildUri('/api/items/batch-move'),
          headers: _jsonHeaders(accessToken),
          body: jsonEncode({
            'itemIds': itemIds,
            'targetCategoryId': targetCategoryId,
          }),
        );

        _throwIfNotSuccessful(response, action: 'move items');
        return;
      }

      final batch = _firestore.batch();
      for (final id in itemIds) {
        batch.update(_itemsCollection.doc(id), {
          'categoryId': targetCategoryId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error batch moving items: $e');
      rethrow;
    }
  }

  Future<void> deleteItem(String itemId) async {
    try {
      try {
        await ReminderSchedulerService().cancelReminder(itemId);
      } catch (e) {
        debugPrint('⚠️ [ItemRepository] No reminder to cancel for $itemId: $e');
      }

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.delete(
          _buildUri('/api/items/$itemId'),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'delete item');
        return;
      }

      await _itemsCollection.doc(itemId).update({
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error deleting item: $e');
      rethrow;
    }
  }

  Future<void> batchUpdateItemOrders(List<ItemModel> items) async {
    try {
      if (items.isEmpty) return;

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.patch(
          _buildUri('/api/items/batch-reorder'),
          headers: _jsonHeaders(accessToken),
          body: jsonEncode({
            'items':
                items
                    .map((item) => {'id': item.id, 'sortOrder': item.order})
                    .toList(),
          }),
        );

        _throwIfNotSuccessful(response, action: 'reorder items');
        return;
      }

      final batch = _firestore.batch();
      for (final item in items) {
        batch.update(_itemsCollection.doc(item.id), {
          'order': item.order,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error updating item orders: $e');
      rethrow;
    }
  }

  Future<void> deleteItemsInCategory(String categoryId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final items = await getItems(currentUserId, categoryId: categoryId);
        await softDeleteItems(items.map((item) => item.id).toList());
        return;
      }

      final snapshot =
          await _itemsCollection
              .where('categoryId', isEqualTo: categoryId)
              .where('isDeleted', isEqualTo: false)
              .get();

      if (snapshot.docs.isEmpty) return;

      for (final doc in snapshot.docs) {
        try {
          await ReminderSchedulerService().cancelReminder(doc.id);
        } catch (_) {}
      }

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error deleting items in category: $e');
      rethrow;
    }
  }

  Future<void> softDeleteItems(List<String> itemIds) async {
    try {
      if (itemIds.isEmpty) return;

      for (final itemId in itemIds) {
        try {
          await ReminderSchedulerService().cancelReminder(itemId);
        } catch (_) {}
      }

      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.post(
          _buildUri('/api/items/batch-delete'),
          headers: _jsonHeaders(accessToken),
          body: jsonEncode({'itemIds': itemIds}),
        );

        _throwIfNotSuccessful(response, action: 'batch delete items');
        return;
      }

      final batch = _firestore.batch();
      for (final id in itemIds) {
        batch.update(_itemsCollection.doc(id), {
          'isDeleted': true,
          'deletedAt': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error batch deleting items: $e');
      rethrow;
    }
  }

  Future<List<ItemModel>> searchItems(String userId, String query) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.get(
          _buildUri('/api/items/search', queryParameters: {'q': query}),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'search items');
        return _parseItemListResponse(
          response.body,
          userId: userId,
          isDeleted: false,
        )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      final snapshot =
          await _itemsCollection.where('userId', isEqualTo: userId).get();

      final lowerQuery = query.toLowerCase();
      final items =
          snapshot.docs
              .map((doc) => ItemModel.fromFirestore(doc))
              .where((item) => !item.isDeleted)
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

  Future<List<ItemModel>> getFavoriteItems(String userId) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.get(
          _buildUri('/api/items/favorites'),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'fetch favorite items');
        return _parseItemListResponse(
          response.body,
          userId: userId,
          isDeleted: false,
        )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      final snapshot =
          await _itemsCollection
              .where('userId', isEqualTo: userId)
              .where('isFavorite', isEqualTo: true)
              .get();

      final items =
          snapshot.docs
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

  Stream<List<ItemModel>> streamItems(
    String userId, {
    String? categoryId,
  }) async* {
    if (!_useBackendForCurrentUser(userId)) {
      Query<Map<String, dynamic>> query = _itemsCollection.where(
        'userId',
        isEqualTo: userId,
      );

      if (categoryId != null) {
        query = query.where('categoryId', isEqualTo: categoryId);
      }

      yield* query.snapshots().map((snapshot) {
        final items =
            snapshot.docs
                .map((doc) => ItemModel.fromFirestore(doc))
                .where((item) => !item.isDeleted)
                .toList();

        _sortItems(items);
        return items;
      });
      return;
    }

    var items = await _fetchAllItemsFromApi(userId, categoryId: categoryId);
    var lastSignature = _itemsSignature(items);
    yield items;

    await for (final _ in _backendRealtimeService.itemsChanges) {
      items = await _fetchAllItemsFromApi(userId, categoryId: categoryId);
      final signature = _itemsSignature(items);

      if (signature == lastSignature) {
        continue;
      }

      lastSignature = signature;
      yield items;
    }
  }

  Future<int> getItemCount(String userId) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        final items = await _fetchAllItemsFromApi(userId, includeDeleted: true);
        return items.length;
      }

      final snapshot =
          await _itemsCollection
              .where('userId', isEqualTo: userId)
              .count()
              .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting item count: $e');
      return 0;
    }
  }

  Future<int> getUncategorizedItemCount(String userId) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        final items = await getItems(userId);
        final categories = await CategoryRepository().getCategories(userId);
        final quickCategory =
            categories.where((c) => c.name == 'Hızlı').firstOrNull;

        return items.where((item) {
          if (item.categoryId == null) return true;
          return quickCategory != null && item.categoryId == quickCategory.id;
        }).length;
      }

      var count = 0;
      final nullSnap =
          await _itemsCollection
              .where('userId', isEqualTo: userId)
              .where('categoryId', isNull: true)
              .where('isDeleted', isEqualTo: false)
              .count()
              .get();
      count += nullSnap.count ?? 0;

      try {
        final categorySnap =
            await _firestore
                .collection('categories')
                .where('userId', isEqualTo: userId)
                .where('name', isEqualTo: 'Hızlı')
                .limit(1)
                .get();

        if (categorySnap.docs.isNotEmpty) {
          final quickCatId = categorySnap.docs.first.id;
          final quickSnap =
              await _itemsCollection
                  .where('userId', isEqualTo: userId)
                  .where('categoryId', isEqualTo: quickCatId)
                  .where('isDeleted', isEqualTo: false)
                  .count()
                  .get();
          count += quickSnap.count ?? 0;
        }
      } catch (e) {
        debugPrint(
          '⚠️ [ItemRepository] Error fetching Quick category count: $e',
        );
      }

      return count;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting pending item count: $e');
      return 0;
    }
  }

  Future<int> getActiveItemCountInCategory(
    String userId,
    String categoryId,
  ) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        final items = await getItems(userId, categoryId: categoryId);
        return items.length;
      }

      final snapshot =
          await _itemsCollection
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

  Future<List<ItemModel>> getRecentItems(String userId, {int limit = 5}) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        final items = await getItems(userId);
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return items.take(limit).toList();
      }

      final snapshot =
          await _itemsCollection
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

  Stream<List<ItemModel>> streamRecentItems(
    String userId, {
    int limit = 5,
  }) async* {
    if (!_useBackendForCurrentUser(userId)) {
      yield* _itemsCollection
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('order')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs
                    .map((doc) => ItemModel.fromFirestore(doc))
                    .toList(),
          );
      return;
    }

    var items = await getRecentItems(userId, limit: limit);
    var lastSignature = _itemsSignature(items);
    yield items;

    await for (final _ in _backendRealtimeService.itemsChanges) {
      items = await getRecentItems(userId, limit: limit);
      final signature = _itemsSignature(items);

      if (signature == lastSignature) {
        continue;
      }

      lastSignature = signature;
      yield items;
    }
  }

  Future<void> updateItemsCategory(
    String userId,
    String oldCategoryId,
    String? newCategoryId,
  ) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        final items = await getItems(userId, categoryId: oldCategoryId);
        if (items.isEmpty) return;

        if (newCategoryId == null) {
          for (final item in items) {
            await moveToCategory(item.id, null);
          }
          return;
        }

        await moveItemsToCategory(
          items.map((item) => item.id).toList(),
          newCategoryId,
        );
        return;
      }

      final batch = _firestore.batch();
      final snapshot =
          await _itemsCollection
              .where('userId', isEqualTo: userId)
              .where('categoryId', isEqualTo: oldCategoryId)
              .where('isDeleted', isEqualTo: false)
              .get();

      if (snapshot.docs.isEmpty) return;

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'categoryId': newCategoryId});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error moving items: $e');
      rethrow;
    }
  }

  Future<void> restoreItem(String itemId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.post(
          _buildUri('/api/items/$itemId/restore'),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'restore item');
        return;
      }

      await _itemsCollection.doc(itemId).update({
        'isDeleted': false,
        'deletedAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error restoring item: $e');
      rethrow;
    }
  }

  Future<void> permanentDeleteItem(String itemId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.delete(
          _buildUri('/api/items/$itemId/permanent'),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'permanently delete item');
        return;
      }

      await _itemsCollection.doc(itemId).delete();
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error permanently deleting item: $e');
      rethrow;
    }
  }

  Future<List<ItemModel>> getDeletedItems(String userId) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.get(
          _buildUri('/api/items/deleted'),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'fetch deleted items');
        final items = _parseItemListResponse(
          response.body,
          userId: userId,
          isDeleted: true,
        );
        items.sort((a, b) {
          final aDeleted = a.deletedAt ?? a.updatedAt;
          final bDeleted = b.deletedAt ?? b.updatedAt;
          return bDeleted.compareTo(aDeleted);
        });
        return items;
      }

      final snapshot =
          await _itemsCollection
              .where('userId', isEqualTo: userId)
              .where('isDeleted', isEqualTo: true)
              .orderBy('deletedAt', descending: true)
              .get();

      return snapshot.docs.map((doc) => ItemModel.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting deleted items: $e');
      rethrow;
    }
  }

  Future<void> deleteAllUserItems(String userId) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        final items = await _fetchAllItemsFromApi(userId, includeDeleted: true);
        for (final item in items) {
          await permanentDeleteItem(item.id);
        }
        return;
      }

      final snapshot =
          await _itemsCollection.where('userId', isEqualTo: userId).get();

      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error deleting all user items: $e');
      rethrow;
    }
  }

  Future<int> cleanupExpiredDeletedItems(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      if (_useBackendForCurrentUser(userId)) {
        final deletedItems = await getDeletedItems(userId);
        final expiredItems =
            deletedItems
                .where(
                  (item) => (item.deletedAt ?? item.updatedAt).isBefore(
                    thirtyDaysAgo,
                  ),
                )
                .toList();

        for (final item in expiredItems) {
          await permanentDeleteItem(item.id);
        }

        return expiredItems.length;
      }

      final snapshot =
          await _itemsCollection
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

      return snapshot.docs.length;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error cleaning up expired items: $e');
      return 0;
    }
  }

  Future<int> copyItemsToCollection({
    required List<String> itemIds,
    required String targetUserId,
    required String targetCategoryId,
  }) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled &&
          currentUserId != null &&
          currentUserId == targetUserId) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.post(
          _buildUri('/api/items/copy'),
          headers: _jsonHeaders(accessToken),
          body: jsonEncode({
            'itemIds': itemIds,
            'targetCategoryId': targetCategoryId,
          }),
        );

        _throwIfNotSuccessful(response, action: 'copy items');
        return itemIds.length;
      }

      var copiedCount = 0;
      final batch = _firestore.batch();

      for (final itemId in itemIds) {
        final originalDoc = await _itemsCollection.doc(itemId).get();
        if (!originalDoc.exists) continue;

        final originalItem = ItemModel.fromFirestore(originalDoc);
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
      return copiedCount;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error copying items: $e');
      rethrow;
    }
  }

  Future<List<ItemModel>> getItemsByCategory(String userId, String categoryId) {
    return getItems(userId, categoryId: categoryId);
  }

  bool _useBackendForCurrentUser(String userId) {
    return _backendAuthService.isEnabled &&
        FirebaseAuth.instance.currentUser?.uid == userId;
  }

  Future<List<ItemModel>> _fetchAllItemsFromApi(
    String userId, {
    String? categoryId,
    bool includeDeleted = false,
  }) async {
    final accessToken = await _requireAccessToken();
    final items = <ItemModel>[];
    var page = 1;
    const limit = 100;
    var totalCount = 0;

    do {
      final response = await _httpClient.get(
        _buildUri(
          '/api/items',
          queryParameters: {
            'page': '$page',
            'limit': '$limit',
            if (categoryId != null) 'categoryId': categoryId,
            if (includeDeleted) 'includeDeleted': 'true',
          },
        ),
        headers: _jsonHeaders(accessToken),
      );

      _throwIfNotSuccessful(response, action: 'fetch items');

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      totalCount = payload['totalCount'] as int? ?? 0;

      final pageItems =
          (payload['items'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(
                (json) =>
                    ItemModel.fromApi(json, userId: userId, isDeleted: false),
              )
              .toList();

      items.addAll(pageItems);
      page++;

      if (pageItems.isEmpty) {
        break;
      }
    } while (items.length < totalCount);

    if (!includeDeleted) {
      items.removeWhere((item) => item.isDeleted);
    }

    _sortItems(items);
    return items;
  }

  Future<ItemModel?> _getItemFromApi(String itemId, String userId) async {
    final accessToken = await _requireAccessToken();
    final response = await _httpClient.get(
      _buildUri('/api/items/$itemId'),
      headers: _jsonHeaders(accessToken),
    );

    if (response.statusCode == 404) {
      return null;
    }

    _throwIfNotSuccessful(response, action: 'fetch item');
    return ItemModel.fromApi(
      jsonDecode(response.body) as Map<String, dynamic>,
      userId: userId,
    );
  }

  Future<ItemModel> _createItemViaApi(ItemModel item) async {
    final accessToken = await _requireAccessToken();
    final response = await _httpClient.post(
      _buildUri('/api/items'),
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(item.toApiCreateRequest()),
    );

    _throwIfNotSuccessful(response, action: 'create item');
    return ItemModel.fromApi(
      jsonDecode(response.body) as Map<String, dynamic>,
      userId: item.userId,
    );
  }

  Future<void> _updateItemViaApi(
    String itemId,
    Map<String, dynamic> requestBody,
  ) async {
    final accessToken = await _requireAccessToken();
    final response = await _httpClient.put(
      _buildUri('/api/items/$itemId'),
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(requestBody),
    );

    _throwIfNotSuccessful(response, action: 'update item');
  }

  Future<String> _requireAccessToken() async {
    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Backend access token could not be obtained.');
    }

    return accessToken;
  }

  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final baseUrl = ApiConfig.baseUrl;
    final normalizedBase =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    return Uri.parse('$normalizedBase$path').replace(
      queryParameters:
          queryParameters?.isEmpty == true ? null : queryParameters,
    );
  }

  Map<String, String> _jsonHeaders(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (ApiConfig.apiKey.isNotEmpty) 'X-SoMine-Api-Key': ApiConfig.apiKey,
      'Authorization': 'Bearer $accessToken',
    };
  }

  void _throwIfNotSuccessful(http.Response response, {required String action}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'Failed to $action. Status: ${response.statusCode}. Body: ${response.body}',
    );
  }

  List<ItemModel> _parseItemListResponse(
    String responseBody, {
    required String userId,
    required bool isDeleted,
  }) {
    final payload = jsonDecode(responseBody) as List<dynamic>;
    return payload
        .whereType<Map<String, dynamic>>()
        .map(
          (json) =>
              ItemModel.fromApi(json, userId: userId, isDeleted: isDeleted),
        )
        .toList();
  }

  void _sortItems(List<ItemModel> items) {
    items.sort((a, b) {
      final orderDiff = a.order.compareTo(b.order);
      if (orderDiff != 0) return orderDiff;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  String _itemsSignature(List<ItemModel> items) {
    return items
        .map(
          (item) =>
              '${item.id}|${item.categoryId}|${item.order}|${item.isFavorite}|${item.isDeleted}|${item.hasReminder}|${item.updatedAt.toUtc().millisecondsSinceEpoch}',
        )
        .join('||');
  }
}
