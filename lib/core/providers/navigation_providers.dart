import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the active tab index of the Main/Home Screen
/// 0: Feed, 1: Search, 2: Catalog, 3: Profile
final homeTabIndexProvider = StateProvider<int>((ref) => 0);

/// Increments when the active Home tab is tapped again and the feed should scroll to top.
final homeReselectTriggerProvider = StateProvider<int>((ref) => 0);

/// Controls whether an item is currently being dragged (Global state)
/// Used to transform the FAB into a Trash Bin
final isDraggingProvider = StateProvider<bool>((ref) => false);
