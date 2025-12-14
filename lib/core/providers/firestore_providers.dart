import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/user_model.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:somine_app/core/repositories/user_repository.dart';

// ==================== Repository Providers ====================

/// User repository provider
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

/// Category repository provider
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

/// Item repository provider
final itemRepositoryProvider = Provider<ItemRepository>((ref) {
  return ItemRepository();
});

// ==================== User Providers ====================

/// Current user model provider (from Firestore)
final currentUserModelProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRepository = ref.watch(userRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        return userRepository.streamUser(user.uid);
      }
      return Stream.value(null);
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ==================== Category Providers ====================

/// Categories for current user
final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final categoryRepository = ref.watch(categoryRepositoryProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        return categoryRepository.streamCategories(user.uid);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Selected category ID (for filtering)
final selectedCategoryIdProvider = StateProvider<String?>((ref) => null);

/// Selected category model
final selectedCategoryProvider = Provider<CategoryModel?>((ref) {
  final categoryId = ref.watch(selectedCategoryIdProvider);
  final categories = ref.watch(categoriesProvider);

  if (categoryId == null) return null;

  return categories.when(
    data: (cats) => cats.where((c) => c.id == categoryId).firstOrNull,
    loading: () => null,
    error: (_, __) => null,
  );
});

// ==================== Item Providers ====================

/// Items for current user (optionally filtered by category)
final itemsProvider = StreamProvider<List<ItemModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final itemRepository = ref.watch(itemRepositoryProvider);
  final selectedCategoryId = ref.watch(selectedCategoryIdProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        return itemRepository.streamItems(user.uid, categoryId: selectedCategoryId);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Favorite items for current user
final favoriteItemsProvider = FutureProvider<List<ItemModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final itemRepository = ref.watch(itemRepositoryProvider);

  return authState.when(
    data: (user) async {
      if (user != null) {
        return itemRepository.getFavoriteItems(user.uid);
      }
      return [];
    },
    loading: () async => [],
    error: (_, __) async => [],
  );
});

/// Item count for current user
final itemCountProvider = FutureProvider<int>((ref) async {
  final authState = ref.watch(authStateProvider);
  final itemRepository = ref.watch(itemRepositoryProvider);

  return authState.when(
    data: (user) async {
      if (user != null) {
        return itemRepository.getItemCount(user.uid);
      }
      return 0;
    },
    loading: () async => 0,
    error: (_, __) async => 0,
  );
});

// ==================== Search Provider ====================

/// Search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Search results
final searchResultsProvider = FutureProvider<List<ItemModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final authState = ref.watch(authStateProvider);
  final itemRepository = ref.watch(itemRepositoryProvider);

  if (query.isEmpty) return [];

  return authState.when(
    data: (user) async {
      if (user != null) {
        return itemRepository.searchItems(user.uid, query);
      }
      return [];
    },
    loading: () async => [],
    error: (_, __) async => [],
  );
});


