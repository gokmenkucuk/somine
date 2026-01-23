import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Controls the active tab index of the Main/Home Screen
/// 0: Feed, 1: Search, 2: Catalog, 3: Profile
final homeTabIndexProvider = StateProvider<int>((ref) => 0);
