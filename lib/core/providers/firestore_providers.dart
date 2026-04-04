import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Pagination
import 'package:cached_network_image/cached_network_image.dart'; // Image Precaching
import 'package:flutter/painting.dart'; // ImageConfiguration

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

/// Items for current user (UNFILTERED - for Catalog Screen)
final catalogItemsProvider = StreamProvider<List<ItemModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final itemRepository = ref.watch(itemRepositoryProvider);
  
  // Explicitly NOT watching selectedCategoryIdProvider
  
  return authState.when(
    data: (user) {
      if (user != null) {
        return itemRepository.streamItems(user.uid); // No categoryId filter
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

/// Deleted items for current user (Recently Deleted)
final deletedItemsProvider = FutureProvider.autoDispose<List<ItemModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final itemRepository = ref.watch(itemRepositoryProvider);

  return authState.when(
    data: (user) async {
      if (user != null) {
        return itemRepository.getDeletedItems(user.uid);
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

/// Toggle for Vault Search mode
final isVaultSearchProvider = StateProvider<bool>((ref) => false);

/// Global Vault Unlock State (App-wide unlock for session)
final isVaultUnlockedProvider = StateProvider<bool>((ref) => false);

/// Search results
final searchResultsProvider = FutureProvider<List<ItemModel>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final isVaultSearch = ref.watch(isVaultSearchProvider);
  final authState = ref.watch(authStateProvider);
  final itemRepository = ref.watch(itemRepositoryProvider);
  
  // Need categories to identify Vaults
  final categoriesAsync = ref.watch(categoriesProvider);
  final categories = categoriesAsync.value ?? [];

  if (query.isEmpty) return [];

  return authState.when(
    data: (user) async {
      if (user != null) {
        var items = await itemRepository.searchItems(user.uid, query);
        
        // Identify Vault Categories
        final vaultIds = categories.where((c) => c.isVault).map((c) => c.id).toSet();
        
        if (isVaultSearch) {
           // SHOW ONLY VAULT ITEMS
           if (vaultIds.isNotEmpty) {
             items = items.where((i) => vaultIds.contains(i.categoryId)).toList();
           } else {
             items = []; // No vault categories -> No vault items
           }
        } else {
           // HIDE VAULT ITEMS (Standard Mode)
           if (vaultIds.isNotEmpty) {
             items = items.where((i) => !vaultIds.contains(i.categoryId)).toList();
           }
        }
        return items;
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
  final int nextPage;

  PaginatedItemsState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.lastDocument,
    this.nextPage = 1,
  });

  PaginatedItemsState copyWith({
    List<ItemModel>? items,
    bool? isLoading,
    bool? hasMore,
    DocumentSnapshot? lastDocument,
    int? nextPage,
  }) {
    return PaginatedItemsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      lastDocument: lastDocument ?? this.lastDocument,
      nextPage: nextPage ?? this.nextPage,
    );
  }
}

class PaginatedItemsNotifier extends StateNotifier<PaginatedItemsState> {
  final ItemRepository _repository;
  String? _userId;
  String? _categoryId;
  String _categoriesSignature = '';
  List<CategoryModel> _categories = [];

  PaginatedItemsNotifier(this._repository) : super(PaginatedItemsState());

  void setParams(String userId, String? categoryId, List<CategoryModel> categories) {
    final nextCategoriesSignature = _buildCategoriesSignature(categories);
    final changed =
        _userId != userId ||
        _categoryId != categoryId ||
        _categoriesSignature != nextCategoriesSignature;

    _userId = userId;
    _categoryId = categoryId;
    _categories = categories;
    _categoriesSignature = nextCategoriesSignature;
    
    if (changed) {
      loadInitial();
    }
  }

  Future<void> loadInitial() async {
    if (_userId == null) return;
    
    // Reset state
    state = PaginatedItemsState(isLoading: true);
    
    try {
      final initialBatch = await _loadBatch(
        page: 1,
        lastDocument: null,
      );
      if (!mounted) return;

      await _precacheImages(initialBatch);
      if (!mounted) return;
      
      state = state.copyWith(
        items: initialBatch,
        isLoading: false,
        hasMore: _lastBatchHasMore,
        lastDocument: _lastBatchLastDocument,
        nextPage: _lastBatchNextPage,
      );
    } catch (e) {
      if (mounted) state = state.copyWith(isLoading: false, hasMore: false);
    }
  }
  
  /// Precache images for items (waits for all images to download)
  Future<void> _precacheImages(List<ItemModel> items) async {
    final imageUrls = items
        .where((item) => item.displayImage != null && item.displayImage!.startsWith('http'))
        .map((item) => item.displayImage!)
        .toList();
    
    if (imageUrls.isEmpty) return;
    
    // Use CachedNetworkImageProvider to precache all images in parallel
    await Future.wait(
      imageUrls.map((url) async {
        try {
          // Download and cache the image
          CachedNetworkImageProvider(url).resolve(ImageConfiguration.empty);
        } catch (e) {
          // Ignore errors for individual images
        }
      }),
    );
    
    // Small delay to allow Flutter to calculate layout after images are cached
    await Future.delayed(const Duration(milliseconds: 100));
  }

  String _buildCategoriesSignature(List<CategoryModel> categories) {
    return categories
        .map(
          (category) =>
              '${category.id}|${category.order}|${category.isVault}|${category.updatedAt.toUtc().millisecondsSinceEpoch}',
        )
        .join('||');
  }

  Future<void> loadMore() async {
    if (_userId == null || state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);

    try {
      final nextBatch = await _loadBatch(
        page: state.nextPage,
        lastDocument: state.lastDocument,
      );
      if (!mounted) return;
      
      state = state.copyWith(
        items: [...state.items, ...nextBatch],
        isLoading: false,
        hasMore: _lastBatchHasMore,
        lastDocument: _lastBatchLastDocument,
        nextPage: _lastBatchNextPage,
      );

      // Warm image cache in the background so scroll append is immediate.
      unawaited(_precacheImages(nextBatch));
    } catch (e) {
       if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  bool _lastBatchHasMore = true;
  DocumentSnapshot? _lastBatchLastDocument;
  int _lastBatchNextPage = 1;

  Future<List<ItemModel>> _loadBatch({
    required int page,
    required DocumentSnapshot? lastDocument,
  }) async {
    const visibleBatchSize = 5;
    final items = <ItemModel>[];
    var currentPage = page;
    var currentLastDocument = lastDocument;
    var sourceHasMore = true;
    final vaultIds =
        _categoryId == null
            ? _categories.where((c) => c.isVault).map((c) => c.id).toSet()
            : const <String?>{};

    while (items.length < visibleBatchSize && sourceHasMore) {
      final result = await _repository.getItemsPaginated(
        _userId!,
        categoryId: _categoryId,
        limit: visibleBatchSize,
        page: currentPage,
        startAfter: currentLastDocument,
      );

      var batchItems = result.items;
      if (vaultIds.isNotEmpty) {
        batchItems =
            batchItems
                .where((item) => !vaultIds.contains(item.categoryId))
                .toList();
      }

      items.addAll(batchItems);
      sourceHasMore = result.hasMore;
      currentLastDocument = result.lastDocument;
      currentPage = result.nextPage ?? currentPage;

      if (result.items.isEmpty) {
        break;
      }
    }

    _lastBatchHasMore = sourceHasMore;
    _lastBatchLastDocument = currentLastDocument;
    _lastBatchNextPage = currentPage;

    return items.take(visibleBatchSize).toList();
  }
}

final paginatedFeedProvider = StateNotifierProvider.autoDispose<PaginatedItemsNotifier, PaginatedItemsState>((ref) {
  final authState = ref.watch(authStateProvider);
  final repo = ref.watch(itemRepositoryProvider);
  final catId = ref.watch(selectedCategoryIdProvider);
  final categories = ref.watch(categoriesProvider).value ?? [];
  final notifier = PaginatedItemsNotifier(repo);
  
  if (authState.value != null) {
     notifier.setParams(authState.value!.uid, catId, categories);
  }
  
  return notifier;
});
