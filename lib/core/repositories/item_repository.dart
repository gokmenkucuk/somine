import 'dart:async' hide TimeoutException;
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/exceptions/network_exceptions.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';
import 'package:somine_app/core/services/backend_realtime_service.dart';
import 'package:somine_app/core/services/reminder_scheduler_service.dart';

class PaginatedItemsResult {
  const PaginatedItemsResult({
    required this.items,
    required this.hasMore,
    this.nextPage,
  });

  final List<ItemModel> items;
  final bool hasMore;
  final int? nextPage;
}

class ItemRepository {
  final BackendAuthService _backendAuthService = BackendAuthService();
  final BackendRealtimeService _backendRealtimeService =
      BackendRealtimeService();
  final http.Client _httpClient = http.Client();
  static const Duration _requestTimeout = Duration(seconds: 15);

  Future<List<ItemModel>> getItems(String userId, {String? categoryId}) async {
    try {
      return await _fetchAllItemsFromApi(userId, categoryId: categoryId);
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
  }) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.get(
          _buildUri(
            '/api/items',
            queryParameters: {
              'page': '$page',
              'limit': '$limit',
              if (categoryId != null) 'categoryId': categoryId,
            },
          ),
          headers: _jsonHeaders(accessToken),
        ),
        'fetch paginated items',
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
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error fetching paginated items: $e');
      rethrow;
    }
  }

  Future<PaginatedItemsResult> searchItemsPaginated(
    String userId,
    String queryStr, {
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.get(
          _buildUri(
            '/api/items/search',
            queryParameters: {'q': queryStr, 'page': '$page', 'limit': '$limit'},
          ),
          headers: _jsonHeaders(accessToken),
        ),
        'search items paginated',
      );

      _throwIfNotSuccessful(response, action: 'search items paginated');

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
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error searching paginated items: $e');
      rethrow;
    }
  }

  Future<ItemModel?> getItem(String itemId) async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      return await _getItemFromApi(itemId, userId);
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting item: $e');
      rethrow;
    }
  }

  Future<ItemModel> createItem(ItemModel item) async {
    try {
      return await _createItemViaApi(item);
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error creating item: $e');
      rethrow;
    }
  }

  Future<void> updateItem(ItemModel item) async {
    try {
      await _updateItemViaApi(item.id, item.toApiUpdateRequest());
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error updating item: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(String itemId, bool isFavorite) async {
    try {
      await _updateItemViaApi(itemId, {'isFavorite': isFavorite});
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
      await _updateItemViaApi(itemId, {
        if (categoryId != null) 'categoryId': categoryId,
        'clearCategory': categoryId == null,
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

      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.post(
          _buildUri('/api/items/batch-move'),
          headers: _jsonHeaders(accessToken),
          body: jsonEncode({
            'itemIds': itemIds,
            'targetCategoryId': targetCategoryId,
          }),
        ),
        'move items',
      );

      _throwIfNotSuccessful(response, action: 'move items');
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

      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.delete(
          _buildUri('/api/items/$itemId'),
          headers: _jsonHeaders(accessToken),
        ),
        'delete item',
      );

      _throwIfNotSuccessful(response, action: 'delete item');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error deleting item: $e');
      rethrow;
    }
  }

  Future<void> batchUpdateItemOrders(List<ItemModel> items) async {
    try {
      if (items.isEmpty) return;

      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.patch(
          _buildUri('/api/items/batch-reorder'),
          headers: _jsonHeaders(accessToken),
          body: jsonEncode({
            'items':
                items
                    .map((item) => {'id': item.id, 'sortOrder': item.order})
                    .toList(),
          }),
        ),
        'reorder items',
      );

      _throwIfNotSuccessful(response, action: 'reorder items');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error updating item orders: $e');
      rethrow;
    }
  }

  Future<void> deleteItemsInCategory(String categoryId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return;

      final items = await getItems(currentUserId, categoryId: categoryId);
      await softDeleteItems(items.map((item) => item.id).toList());
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

      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.post(
          _buildUri('/api/items/batch-delete'),
          headers: _jsonHeaders(accessToken),
          body: jsonEncode({'itemIds': itemIds}),
        ),
        'batch delete items',
      );

      _throwIfNotSuccessful(response, action: 'batch delete items');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error batch deleting items: $e');
      rethrow;
    }
  }

  Future<List<ItemModel>> searchItems(String userId, String query) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.get(
          _buildUri('/api/items/search', queryParameters: {'q': query}),
          headers: _jsonHeaders(accessToken),
        ),
        'search items',
      );

      _throwIfNotSuccessful(response, action: 'search items');
      return _parseItemListResponse(
        response.body,
        userId: userId,
        isDeleted: false,
      )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error searching items: $e');
      rethrow;
    }
  }

  Future<List<ItemModel>> getFavoriteItems(String userId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.get(
          _buildUri('/api/items/favorites'),
          headers: _jsonHeaders(accessToken),
        ),
        'fetch favorite items',
      );

      _throwIfNotSuccessful(response, action: 'fetch favorite items');
      return _parseItemListResponse(
        response.body,
        userId: userId,
        isDeleted: false,
      )..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting favorite items: $e');
      rethrow;
    }
  }

  Stream<List<ItemModel>> streamItems(
    String userId, {
    String? categoryId,
  }) async* {
    while (true) {
      try {
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
      } catch (error, stackTrace) {
        debugPrint('❌ [ItemRepository] streamItems failed: $error');
        yield* Stream<List<ItemModel>>.error(error, stackTrace);
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
  }

  Future<int> getItemCount(String userId) async {
    try {
      final items = await _fetchAllItemsFromApi(userId, includeDeleted: false);
      return items.length;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting item count: $e');
      return 0;
    }
  }

  Future<int> getUncategorizedItemCount(String userId) async {
    try {
      final items = await getItems(userId);
      final categories = await CategoryRepository().getCategories(userId);
      final quickCategory =
          categories.where((c) => c.name == 'Hızlı').firstOrNull;

      return items.where((item) {
        if (item.categoryId == null) return true;
        return quickCategory != null && item.categoryId == quickCategory.id;
      }).length;
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
      final items = await getItems(userId, categoryId: categoryId);
      return items.length;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting category item count: $e');
      return 0;
    }
  }

  Future<List<ItemModel>> getRecentItems(String userId, {int limit = 5}) async {
    try {
      final items = await getItems(userId);
      items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return items.take(limit).toList();
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting recent items: $e');
      return [];
    }
  }

  Stream<List<ItemModel>> streamRecentItems(
    String userId, {
    int limit = 5,
  }) async* {
    while (true) {
      try {
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
      } catch (error, stackTrace) {
        debugPrint('❌ [ItemRepository] streamRecentItems failed: $error');
        yield* Stream<List<ItemModel>>.error(error, stackTrace);
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
  }

  Future<void> updateItemsCategory(
    String userId,
    String oldCategoryId,
    String? newCategoryId,
  ) async {
    try {
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
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error moving items: $e');
      rethrow;
    }
  }

  Future<void> restoreItem(String itemId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.post(
          _buildUri('/api/items/$itemId/restore'),
          headers: _jsonHeaders(accessToken),
        ),
        'restore item',
      );

      _throwIfNotSuccessful(response, action: 'restore item');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error restoring item: $e');
      rethrow;
    }
  }

  Future<void> restoreItems(List<String> itemIds) async {
    for (final itemId in itemIds) {
      await restoreItem(itemId);
    }
  }

  Future<void> permanentDeleteItem(String itemId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.delete(
          _buildUri('/api/items/$itemId/permanent'),
          headers: _jsonHeaders(accessToken),
        ),
        'permanently delete item',
      );

      _throwIfNotSuccessful(response, action: 'permanently delete item');
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error permanently deleting item: $e');
      rethrow;
    }
  }

  Future<List<ItemModel>> getDeletedItems(String userId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.get(
          _buildUri('/api/items/deleted'),
          headers: _jsonHeaders(accessToken),
        ),
        'fetch deleted items',
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
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error getting deleted items: $e');
      rethrow;
    }
  }

  Future<void> deleteAllUserItems(String userId) async {
    try {
      final items = await _fetchAllItemsFromApi(userId, includeDeleted: true);
      for (final item in items) {
        await permanentDeleteItem(item.id);
      }
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error deleting all user items: $e');
      rethrow;
    }
  }

  Future<int> cleanupExpiredDeletedItems(String userId) async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final deletedItems = await getDeletedItems(userId);
      final expiredItems =
          deletedItems
              .where(
                (item) =>
                    (item.deletedAt ?? item.updatedAt).isBefore(thirtyDaysAgo),
              )
              .toList();

      for (final item in expiredItems) {
        await permanentDeleteItem(item.id);
      }

      return expiredItems.length;
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
      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.post(
          _buildUri('/api/items/copy'),
          headers: _jsonHeaders(accessToken),
          body: jsonEncode({
            'itemIds': itemIds,
            'targetCategoryId': targetCategoryId,
          }),
        ),
        'copy items',
      );

      _throwIfNotSuccessful(response, action: 'copy items');
      return itemIds.length;
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error copying items: $e');
      rethrow;
    }
  }

  /// Items of a collection shared with (or by) the current user.
  /// Reads via the share-scoped endpoint; requester must be the share's
  /// sender or an accepted receiver.
  Future<List<ItemModel>> getSharedItems({
    required String shareId,
    required String ownerUserId,
  }) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.get(
          _buildUri('/api/shares/$shareId/items'),
          headers: _jsonHeaders(accessToken),
        ),
        'fetch shared items',
      );

      _throwIfNotSuccessful(response, action: 'fetch shared items');

      final data = jsonDecode(response.body) as List<dynamic>;
      return data
          .whereType<Map<String, dynamic>>()
          .map(
            (json) =>
                ItemModel.fromApi(json, userId: ownerUserId, isDeleted: false),
          )
          .toList();
    } catch (e) {
      debugPrint('❌ [ItemRepository] Error fetching shared items: $e');
      rethrow;
    }
  }

  Future<List<ItemModel>> getItemsByCategory(String userId, String categoryId) {
    return getItems(userId, categoryId: categoryId);
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
      final response = await _withTimeout(
        _httpClient.get(
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
        ),
        'fetch items',
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
    final response = await _withTimeout(
      _httpClient.get(
        _buildUri('/api/items/$itemId'),
        headers: _jsonHeaders(accessToken),
      ),
      'fetch item',
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
    final response = await _withTimeout(
      _httpClient.post(
        _buildUri('/api/items'),
        headers: _jsonHeaders(accessToken),
        body: jsonEncode(item.toApiCreateRequest()),
      ),
      'create item',
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
    final response = await _withTimeout(
      _httpClient.put(
        _buildUri('/api/items/$itemId'),
        headers: _jsonHeaders(accessToken),
        body: jsonEncode(requestBody),
      ),
      'update item',
    );

    _throwIfNotSuccessful(response, action: 'update item');
  }

  Future<String> _requireAccessToken() async {
    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      throw const UnauthorizedException(
        'backend access token missing',
        userMessage: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      );
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

  Future<T> _withTimeout<T>(Future<T> future, String action) {
    return future.timeout(
      _requestTimeout,
      onTimeout:
          () =>
              throw TimeoutException(
                '$action timed out after ${_requestTimeout.inSeconds} seconds',
                userMessage:
                    'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.',
              ),
    );
  }

  void _throwIfNotSuccessful(http.Response response, {required String action}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    // Log for debugging (not shown to user)
    debugPrint(
      'API Error [$action]: ${response.statusCode} - ${response.body}',
    );

    // Throw typed exception
    throw switch (response.statusCode) {
      401 => UnauthorizedException(
        '$action: unauthorized',
        userMessage: 'Oturum süreniz doldu. Lütfen tekrar giriş yapın.',
      ),
      409 => ConflictException(
        '$action: conflict',
        userMessage: 'Bu işlem zaten yapıldı.',
      ),
      >= 400 && < 500 => ValidationException(
        '$action failed',
        userMessage: _parseApiError(response.body),
      ),
      >= 500 => ServerException(
        '$action: server error',
        userMessage: 'Sunucu hatası oluştu. Lütfen biraz sonra tekrar deneyin.',
      ),
      _ => ServerException(
        '$action failed',
        userMessage: 'İşlem başarısız oldu. Lütfen tekrar deneyin.',
      ),
    };
  }

  String _parseApiError(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>?;
      return json?['message'] as String? ??
          json?['error'] as String? ??
          'Geçersiz istek. Lütfen tekrar deneyin.';
    } catch (_) {
      return 'İşlem başarısız oldu. Lütfen tekrar deneyin.';
    }
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
