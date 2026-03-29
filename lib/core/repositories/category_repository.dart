import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';
import 'package:somine_app/core/services/backend_realtime_service.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BackendAuthService _backendAuthService = BackendAuthService();
  final BackendRealtimeService _backendRealtimeService =
      BackendRealtimeService();
  final http.Client _httpClient = http.Client();

  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('categories');

  Future<List<CategoryModel>> getCategories(String userId) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        return _getCategoriesFromApi(userId);
      }

      final snapshot =
          await _categoriesCollection.where('userId', isEqualTo: userId).get();

      final categories =
          snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
      categories.sort((a, b) => a.order.compareTo(b.order));
      return categories;
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error getting categories: $e');
      rethrow;
    }
  }

  Future<CategoryModel?> getCategory(String categoryId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final categories = await _getCategoriesFromApi(currentUserId);
        final match = categories.where((c) => c.id == categoryId).firstOrNull;
        if (match != null) return match;
      }

      final doc = await _categoriesCollection.doc(categoryId).get();
      if (doc.exists) {
        return CategoryModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error getting category: $e');
      rethrow;
    }
  }

  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      if (_useBackendForCurrentUser(category.userId)) {
        return _createCategoryViaApi(category);
      }

      final docRef = await _categoriesCollection.add(category.toFirestore());
      debugPrint('✅ [CategoryRepository] Category created: ${docRef.id}');

      final doc = await docRef.get();
      return CategoryModel.fromFirestore(doc);
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
      if (_useBackendForCurrentUser(category.userId)) {
        await _updateCategoryViaApi(category);
        return;
      }

      await _categoriesCollection.doc(category.id).update({
        'name': category.name,
        'icon': category.icon,
        'color': category.color,
        'order': category.order,
        'isVault': category.isVault,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [CategoryRepository] Category updated: ${category.id}');
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error updating category: $e');
      rethrow;
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      if (_backendAuthService.isEnabled) {
        await _deleteCategoryViaApi(categoryId);
        return;
      }

      await _categoriesCollection.doc(categoryId).delete();
      debugPrint('✅ [CategoryRepository] Category deleted: $categoryId');
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error deleting category: $e');
      rethrow;
    }
  }

  Future<void> reorderCategories(List<CategoryModel> categories) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        await _reorderCategoriesViaApi(categories);
        return;
      }

      final batch = _firestore.batch();

      for (int i = 0; i < categories.length; i++) {
        final category = categories[i];
        batch.update(_categoriesCollection.doc(category.id), {
          'order': i,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
      debugPrint('✅ [CategoryRepository] Categories reordered');
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error reordering categories: $e');
      rethrow;
    }
  }

  Stream<List<CategoryModel>> streamCategories(String userId) async* {
    if (!_useBackendForCurrentUser(userId)) {
      yield* _categoriesCollection
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final categories =
                snapshot.docs
                    .map((doc) => CategoryModel.fromFirestore(doc))
                    .toList();
            categories.sort((a, b) => a.order.compareTo(b.order));
            return categories;
          });
      return;
    }

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

  bool _useBackendForCurrentUser(String userId) {
    return _backendAuthService.isEnabled &&
        FirebaseAuth.instance.currentUser?.uid == userId;
  }

  Future<List<CategoryModel>> _getCategoriesFromApi(String userId) async {
    final accessToken = await _requireAccessToken();
    final response = await _httpClient.get(
      _buildUri('/api/categories'),
      headers: _jsonHeaders(accessToken),
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
    final response = await _httpClient.post(
      _buildUri('/api/categories'),
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(category.toApiCreateRequest()),
    );

    _throwIfNotSuccessful(response, action: 'create category');

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CategoryModel.fromApi(data, userId: category.userId);
  }

  Future<void> _updateCategoryViaApi(CategoryModel category) async {
    final accessToken = await _requireAccessToken();
    final response = await _httpClient.put(
      _buildUri('/api/categories/${category.id}'),
      headers: _jsonHeaders(accessToken),
      body: jsonEncode(category.toApiUpdateRequest()),
    );

    _throwIfNotSuccessful(response, action: 'update category');
  }

  Future<void> _deleteCategoryViaApi(String categoryId) async {
    final accessToken = await _requireAccessToken();
    final response = await _httpClient.delete(
      _buildUri('/api/categories/$categoryId'),
      headers: _jsonHeaders(accessToken),
    );

    _throwIfNotSuccessful(response, action: 'delete category');
  }

  Future<void> _reorderCategoriesViaApi(List<CategoryModel> categories) async {
    final accessToken = await _requireAccessToken();
    final response = await _httpClient.patch(
      _buildUri('/api/categories/reorder'),
      headers: _jsonHeaders(accessToken),
      body: jsonEncode({
        'items': [
          for (int i = 0; i < categories.length; i++)
            {'id': categories[i].id, 'sortOrder': i},
        ],
      }),
    );

    _throwIfNotSuccessful(response, action: 'reorder categories');
  }

  Future<String> _requireAccessToken() async {
    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No backend access token available.');
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

  String _categoriesSignature(List<CategoryModel> categories) {
    return categories
        .map(
          (category) =>
              '${category.id}|${category.name}|${category.icon}|${category.color}|${category.order}|${category.isVault}|${category.updatedAt.toUtc().millisecondsSinceEpoch}',
        )
        .join('||');
  }
}
