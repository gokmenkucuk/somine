import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';

/// Provider for uncategorized item count (AutoDispose ensures refresh on revisit)
final uncategorizedCountProvider = FutureProvider.autoDispose.family<int, String>((ref, userId) async {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.getUncategorizedItemCount(userId);
});

/// Provider for recent items (Activity Feed) - STREAM for live updates
final recentItemsProvider = StreamProvider.autoDispose.family<List<ItemModel>, String>((ref, userId) {
  final repository = ref.watch(itemRepositoryProvider);
  return repository.streamRecentItems(userId);
});
