import 'dart:async' hide TimeoutException;
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/exceptions/network_exceptions.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';
import 'package:somine_app/core/services/backend_realtime_service.dart';

class CategoryRepository {
  final BackendAuthService _backendAuthService = BackendAuthService();
  final BackendRealtimeService _backendRealtimeService =
      BackendRealtimeService();
  final http.Client _httpClient = http.Client();
  static const Duration _requestTimeout = Duration(seconds: 15);

  Future<List<CategoryModel>> getCategories(String userId) async {
    try {
      return await _getCategoriesFromApi(userId);
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error getting categories: $e');
      rethrow;
    }
  }

  Future<CategoryModel?> getCategory(String categoryId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) return null;

      final categories = await _getCategoriesFromApi(currentUserId);
      return categories.where((c) => c.id == categoryId).firstOrNull;
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error getting category: $e');
      rethrow;
    }
  }

  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      return await _createCategoryViaApi(category);
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error creating category: $e');
      rethrow;
    }
  }

  Future<List<CategoryModel>> createDefaultCategories(String userId) async {
    try {
      final defaults = CategoryModel.defaultCategories(userId);
      final createdCategories = <CategoryModel>[];

      for (final category in defaults) {
        final created = await createCategory(category);
        createdCategories.add(created);
      }

      debugPrint(
        '✅ [CategoryRepository] Default categories created for user: $userId',
      );
      return createdCategories;
    } catch (e) {
      debugPrint(
        '❌ [CategoryRepository] Error creating default categories: $e',
      );
      rethrow;
    }
  }

  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _updateCategoryViaApi(category);
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await _deleteCategoryViaApi(categoryId);
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error deleting category: $e');
      rethrow;
    }
  }

  Future<void> reorderCategories(List<CategoryModel> categories) async {
    try {
      await _reorderCategoriesViaApi(categories);
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error reordering categories: $e');
      rethrow;
    }
  }

  Stream<List<CategoryModel>> streamCategories(String userId) async* {
    while (true) {
      try {
        var categories = await _getCategoriesFromApi(userId);
        var lastSignature = _categoriesSignature(categories);
        yield categories;

        await for (final _ in _backendRealtimeService.categoriesChanges) {
          categories = await _getCategoriesFromApi(userId);
          final signature = _categoriesSignature(categories);

          if (signature == lastSignature) {
            continue;
          }

          lastSignature = signature;
          yield categories;
        }
      } catch (error, stackTrace) {
        debugPrint('❌ [CategoryRepository] streamCategories failed: $error');
        yield* Stream<List<CategoryModel>>.error(error, stackTrace);
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
  }

  Future<void> deleteAllUserCategories(String userId) async {
    try {
      final categories = await getCategories(userId);
      for (final category in categories) {
        await deleteCategory(category.id);
      }

      debugPrint(
        '✅ [CategoryRepository] All categories deleted for user: $userId',
      );
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error deleting all categories: $e');
      rethrow;
    }
  }

  Future<List<CategoryModel>> _getCategoriesFromApi(String userId) async {
    final accessToken = await _requireAccessToken();
    final response = await _withTimeout(
      _httpClient.get(
        _buildUri('/api/categories'),
        headers: _jsonHeaders(accessToken),
      ),
      'fetch categories',
    );

    _throwIfNotSuccessful(response, action: 'fetch categories');

    final data = jsonDecode(response.body) as List<dynamic>;
    final categories =
        data
            .whereType<Map<String, dynamic>>()
            .map((json) => CategoryModel.fromApi(json, userId: userId))
            .toList();
    categories.sort((a, b) => a.order.compareTo(b.order));
    return categories;
  }

  Future<CategoryModel> _createCategoryViaApi(CategoryModel category) async {
    final accessToken = await _requireAccessToken();
    final response = await _withTimeout(
      _httpClient.post(
        _buildUri('/api/categories'),
        headers: _jsonHeaders(accessToken),
        body: jsonEncode(category.toApiCreateRequest()),
      ),
      'create category',
    );

    _throwIfNotSuccessful(response, action: 'create category');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CategoryModel.fromApi(data, userId: category.userId);
  }

  Future<void> _updateCategoryViaApi(CategoryModel category) async {
    final accessToken = await _requireAccessToken();
    final response = await _withTimeout(
      _httpClient.put(
        _buildUri('/api/categories/${category.id}'),
        headers: _jsonHeaders(accessToken),
        body: jsonEncode(category.toApiUpdateRequest()),
      ),
      'update category',
    );

    _throwIfNotSuccessful(response, action: 'update category');
  }

  Future<void> _deleteCategoryViaApi(String categoryId) async {
    final accessToken = await _requireAccessToken();
    final response = await _withTimeout(
      _httpClient.delete(
        _buildUri('/api/categories/$categoryId'),
        headers: _jsonHeaders(accessToken),
      ),
      'delete category',
    );

    _throwIfNotSuccessful(response, action: 'delete category');
  }

  Future<void> _reorderCategoriesViaApi(List<CategoryModel> categories) async {
    final accessToken = await _requireAccessToken();
    final response = await _withTimeout(
      _httpClient.patch(
        _buildUri('/api/categories/reorder'),
        headers: _jsonHeaders(accessToken),
        body: jsonEncode({
          'items': [
            for (int i = 0; i < categories.length; i++)
              {'id': categories[i].id, 'sortOrder': i},
          ],
        }),
      ),
      'reorder categories',
    );

    _throwIfNotSuccessful(response, action: 'reorder categories');
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

  Uri _buildUri(String path) {
    final baseUrl = ApiConfig.baseUrl;
    final normalizedBase =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    return Uri.parse('$normalizedBase$path');
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

  String _categoriesSignature(List<CategoryModel> categories) {
    return categories
        .map(
          (category) =>
              '${category.id}|${category.name}|${category.icon}|${category.color}|${category.order}|${category.isVault}|${category.updatedAt.toUtc().millisecondsSinceEpoch}',
        )
        .join('||');
  }
}
