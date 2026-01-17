import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:somine_app/core/models/category_model.dart';

class CategoryRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _categoriesCollection =>
      _firestore.collection('categories');

  /// Get all categories for a user
  Future<List<CategoryModel>> getCategories(String userId) async {
    try {
      final snapshot = await _categoriesCollection
          .where('userId', isEqualTo: userId)
          .get();

      final categories = snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
      categories.sort((a, b) => a.order.compareTo(b.order));
      return categories;
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error getting categories: $e');
      rethrow;
    }
  }

  /// Get category by ID
  Future<CategoryModel?> getCategory(String categoryId) async {
    try {
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

  /// Create a new category
  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      final docRef = await _categoriesCollection.add(category.toFirestore());
      debugPrint('✅ [CategoryRepository] Category created: ${docRef.id}');
      
      final doc = await docRef.get();
      return CategoryModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error creating category: $e');
      rethrow;
    }
  }

  /// Create default categories for a new user
  Future<List<CategoryModel>> createDefaultCategories(String userId) async {
    try {
      final defaults = CategoryModel.defaultCategories(userId);
      final createdCategories = <CategoryModel>[];

      for (final category in defaults) {
        final created = await createCategory(category);
        createdCategories.add(created);
      }

      debugPrint('✅ [CategoryRepository] Default categories created for user: $userId');
      return createdCategories;
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error creating default categories: $e');
      rethrow;
    }
  }

  /// Update a category
  Future<void> updateCategory(CategoryModel category) async {
    try {
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

  /// Delete a category
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _categoriesCollection.doc(categoryId).delete();
      debugPrint('✅ [CategoryRepository] Category deleted: $categoryId');
    } catch (e) {
      debugPrint('❌ [CategoryRepository] Error deleting category: $e');
      rethrow;
    }
  }

  /// Reorder categories
  Future<void> reorderCategories(List<CategoryModel> categories) async {
    try {
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

  /// Stream categories for a user
  Stream<List<CategoryModel>> streamCategories(String userId) {
    return _categoriesCollection
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final categories = snapshot.docs.map((doc) => CategoryModel.fromFirestore(doc)).toList();
          categories.sort((a, b) => a.order.compareTo(b.order));
          return categories;
        });
  }
}


