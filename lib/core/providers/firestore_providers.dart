import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Pagination

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


// ==================== Pagination Provider ====================

class PaginatedItemsState {
  final List<ItemModel> items;
  final bool isLoading;
  final bool hasMore;
  final DocumentSnapshot? lastDocument;

  PaginatedItemsState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDocument,
  });

  PaginatedItemsState copyWith({
    List<ItemModel>? items,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
  }) {
    return PaginatedItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
    );
  }
}

class PaginatedItemsNotifier extends StateNotifier<PaginatedItemsState> {
  final ItemRepository _repository;
  String? _userId;
  String? _categoryId;
  
  // Cache for client-side pagination
  List<ItemModel> _allCachedItems = [];

  PaginatedItemsNotifier(this._repository) : super(PaginatedItemsState());

  void setParams(String userId, String? categoryId) {
    bool changed = _userId != userId || _categoryId != categoryId;
    _userId = userId;
    _categoryId = categoryId;
    if (changed) {
      loadInitial();
    }
  }

  Future<void> loadInitial() async {
    if (_userId == null) return;
    
    // Reset state
    state = state.copyWith(isLoading: true, items: [], hasMore: true, lastDocument: null);
    _allCachedItems = [];
    
    try {
      // 1. Fetch ALL items (Simple Query, No Index needed)
      final allItems = await _repository.getItems(_userId!, categoryId: _categoryId);
      
      // 2. Sort in memory (just to be safe, repo does it too)
      allItems.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      _allCachedItems = allItems;
      
      // 3. Slice first page
      final initialBatch = _allCachedItems.take(8).toList();
      
      state = state.copyWith(
        items: initialBatch,
        isLoading: false,
        hasMore: initialBatch.length < _allCachedItems.length,
        lastDocument: null, 
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, hasMore: false);
    }
  }

  Future<void> loadMore() async {
    if (_userId == null || state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      // 4. Simulate Network Delay for UX
      await Future.delayed(const Duration(milliseconds: 300));
      
      // 5. Get next batch from cache
      final currentLength = state.items.length;
      final nextBatch = _allCachedItems.skip(currentLength).take(8).toList();
      
      state = state.copyWith(
        items: [...state.items, ...nextBatch],
        isLoading: false,
        hasMore: (state.items.length + nextBatch.length) < _allCachedItems.length,
      );
    } catch (e) {
       state = state.copyWith(isLoading: false);
    }
  }
}

final paginatedFeedProvider = StateNotifierProvider.autoDispose<PaginatedItemsNotifier, PaginatedItemsState>((ref) {
  final authState = ref.watch(authStateProvider);
  final repo = ref.watch(itemRepositoryProvider);
  final catId = ref.watch(selectedCategoryIdProvider);
  
  final notifier = PaginatedItemsNotifier(repo);
  
  if (authState.value != null) {
     notifier.setParams(authState.value!.uid, catId);
  }
  
  return notifier;
});
