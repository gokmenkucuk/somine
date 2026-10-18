import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:somine_app/core/services/subscription_service.dart';

/// Subscription state
class SubscriptionState {
  final SubscriptionTier tier;
  final String activePackageName;
  final bool isLoading;
  final List<Package> availablePackages;
  final String? error;

  /// Son satın alma denemesinin kullanıcıya gösterilecek hatası
  /// (iptal edildiyse null). Arayüz bunu l10n metnine çevirir.
  final PurchaseFailureCode? purchaseError;

  const SubscriptionState({
    this.tier = SubscriptionTier.starter,
    this.activePackageName = "",
    this.isLoading = false,
    this.availablePackages = const [],
    this.error,
    this.purchaseError,
  });

  SubscriptionState copyWith({
    SubscriptionTier? tier,
    String? activePackageName,
    bool? isLoading,
    List<Package>? availablePackages,
    String? error,
    PurchaseFailureCode? purchaseError,
  }) {
    return SubscriptionState(
      tier: tier ?? this.tier,
      activePackageName: activePackageName ?? this.activePackageName,
      isLoading: isLoading ?? this.isLoading,
      availablePackages: availablePackages ?? this.availablePackages,
      error: error,
      purchaseError: purchaseError,
    );
  }

  bool get isPremium => tier == SubscriptionTier.curator;
}

/// Subscription notifier
class SubscriptionNotifier extends StateNotifier<SubscriptionState> {
  final SubscriptionService _service;

  SubscriptionNotifier(this._service) : super(const SubscriptionState()) {
    _initialize();
    // Giriş/çıkış sonrası servis yeniden hesaplar; ekran durumu eskide kalmasın.
    _changesSubscription = _service.changes.listen((_) {
      if (!mounted) return;
      state = state.copyWith(
        tier: _service.currentTier,
        activePackageName: _service.activePackageName,
        availablePackages: state.availablePackages,
        isLoading: state.isLoading,
      );
    });
  }

  StreamSubscription<void>? _changesSubscription;

  @override
  void dispose() {
    _changesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    state = state.copyWith(isLoading: true);

    await _service.initialize();
    final packages = await _service.getOfferings();

    state = state.copyWith(
      tier: _service.currentTier,
      activePackageName: _service.activePackageName,
      isLoading: false,
      availablePackages: packages,
    );
  }

  /// Reload subscription status
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);

    await _service.refreshStatus();
    final packages = await _service.getOfferings();

    state = state.copyWith(
      tier: _service.currentTier,
      activePackageName: _service.activePackageName,
      isLoading: false,
      availablePackages: packages,
    );
  }

  /// Purchase a package
  Future<bool> purchase(Package package) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.purchasePackage(package);
      await _service.refreshStatus();

      if (success) {
        state = state.copyWith(
          tier: _service.currentTier, 
          activePackageName: _service.activePackageName,
          isLoading: false
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      return success;
    } on PurchaseFailure catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        purchaseError: e.code,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        purchaseError: PurchaseFailureCode.failed,
      );
      return false;
    }
  }

  /// Restore purchases
  Future<bool> restore() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await _service.restorePurchases();
      await _service.refreshStatus();

      state = state.copyWith(
        tier: _service.currentTier, 
        activePackageName: _service.activePackageName,
        isLoading: false
      );

      return success;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  /// Check if can create collection
  bool canCreateCollection(int currentCount) {
    return _service.canCreateCollection(currentCount);
  }

  /// Check if can add item (toplam içerik sayısına göre)
  bool canAddItem(int totalItemCount) {
    return _service.canAddItem(totalItemCount);
  }

  /// Check if can create more active reminders
  bool canCreateReminder(int activeReminderCount) {
    return _service.canCreateReminder(activeReminderCount);
  }

  /// Check if can create more active shares
  bool canCreateShare(int activeShareCount) {
    return _service.canCreateShare(activeShareCount);
  }

  /// Whether to show a soft warning as the user approaches the total item limit
  bool shouldWarnItemLimit(int totalItemCount) {
    return _service.shouldWarnItemLimit(totalItemCount);
  }

  /// Get remaining items (toplam içerik sayısına göre)
  int remainingItems(int totalItemCount) {
    return _service.remainingItems(totalItemCount);
  }
}

/// Providers
final subscriptionServiceProvider = Provider<SubscriptionService>((ref) {
  return SubscriptionService();
});

final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionState>((ref) {
      final service = ref.watch(subscriptionServiceProvider);
      return SubscriptionNotifier(service);
    });

/// Geliştirme anahtarı: `--dart-define=SOMINE_DEBUG_PREMIUM=true`
///
/// Premium'a kilitli yüzeyleri (temalar, uygulama ikonları, Gizli Kasa,
/// koleksiyon paylaşımı) simülatörde satın alma yapmadan denemek için.
/// **Yalnız debug derlemede** çalışır: release'de [kDebugMode] false olduğu için
/// bayrak verilse bile etkisizdir. Sunucu tarafındaki premium sınırları
/// (içerik/koleksiyon kotaları) bundan etkilenmez — bu bayrak sadece arayüzü açar.
const bool _debugForcePremium = bool.fromEnvironment(
  'SOMINE_DEBUG_PREMIUM',
  defaultValue: false,
);

/// Convenience providers
final isPremiumProvider = Provider<bool>((ref) {
  if (kDebugMode && _debugForcePremium) return true;
  return ref.watch(subscriptionProvider).isPremium;
});

final subscriptionTierProvider = Provider<SubscriptionTier>((ref) {
  return ref.watch(subscriptionProvider).tier;
});

final activePackageNameProvider = Provider<String>((ref) {
  return ref.watch(subscriptionProvider).activePackageName;
});
