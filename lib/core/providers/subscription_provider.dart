import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:somine_app/core/services/subscription_service.dart';

/// Subscription state
class SubscriptionState {
  final SubscriptionTier tier;
  final bool isLoading;
  final List<Package> availablePackages;
  final String? error;

  const SubscriptionState({
    this.tier = SubscriptionTier.starter,
    this.isLoading = false,
    this.availablePackages = const [],
    this.error,
  });

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    bool? isLoading,
    List<Package>? availablePackages,
    String? error,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      isLoading: isLoading ?? this.isLoading,
      availablePackages: availablePackages ?? this.availablePackages,
      error: error,
    );
  }

  bool get isPremium => tier == SubscriptionTier.curator;
}

/// Subscription notifier
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionService _service;

  SubscriptionNotifier(this._service) : super(const SubscriptionState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);
    
    await _service.initialize();
    final packages = await _service.getOfferings();
    
    state = state.copyWith(
      tier: _service.currentTier,
      isLoading: false,
      availablePackages: packages,
    );
  }

  /// Reload subscription status
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    
    final packages = await _service.getOfferings();
    
    state = state.copyWith(
      tier: _service.currentTier,
      isLoading: false,
      availablePackages: packages,
    );
  }

  /// Purchase a package
  Future<bool> purchase(Package package) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await _service.purchasePackage(package);
      
      if (success) {
        state = state.copyWith(
          tier: SubscriptionTier.curator,
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
      
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restore() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final success = await _service.restorePurchases();
      
      state = state.copyWith(
        tier: _service.currentTier,
        isLoading: false,
      );
      
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Check if can create collection
  bool canCreateCollection(int currentCount) {
    return true; // TESTING: Bypass limits
    // return _service.canCreateCollection(currentCount);
  }

  /// Check if can add item
  bool canAddItem(int currentItemCount) {
    return true; // TESTING: Bypass limits
    // return _service.canAddItem(currentItemCount);
  }
}

/// Providers
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

final subscriptionProvider = StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
  final service = ref.watch(subscriptionServiceProvider);
  return SubscriptionNotifier(service);
});

/// Convenience providers
final isPremiumProvider = Provider<bool>((ref) {
  return true; // TESTING: Force Premium
  // return ref.watch(subscriptionProvider).isPremium;
});

final subscriptionTierProvider = Provider<SubscriptionTier>((ref) {
  return ref.watch(subscriptionProvider).tier;
});
