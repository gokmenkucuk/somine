import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/services/vault_service.dart';

/// Vault state
class VaultState {
  final bool isUnlocked;
  final bool isBiometricAvailable;
  final bool isLoading;

  const VaultState({
    this.isUnlocked = false,
    this.isBiometricAvailable = false,
    this.isLoading = false,
  });

  VaultState copyWith({
    bool? isUnlocked,
    bool? isBiometricAvailable,
    bool? isLoading,
  }) {
    return VaultState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Vault notifier
class VaultNotifier extends StateNotifier<VaultState> {
  final VaultService _service;

  VaultNotifier(this._service) : super(const VaultState()) {
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _service.isBiometricAvailable();
    state = state.copyWith(isBiometricAvailable: isAvailable);
  }

  /// Unlock vault with biometric authentication
  Future<bool> unlock() async {
    if (state.isUnlocked) return true;
    
    state = state.copyWith(isLoading: true);
    
    final success = await _service.authenticate(
      reason: 'Gizli kasaya erişmek için doğrulama yapın',
    );
    
    state = state.copyWith(
      isUnlocked: success,
      isLoading: false,
    );
    
    return success;
  }

  /// Lock vault
  void lock() {
    state = state.copyWith(isUnlocked: false);
  }

  /// Auto-lock after app goes to background
  void onAppPaused() {
    lock();
  }
}

/// Providers
final vaultServiceProvider = Provider<VaultService>((ref) {
  return VaultService();
});

final vaultProvider = StateNotifierProvider<VaultNotifier, VaultState>((ref) {
  final service = ref.watch(vaultServiceProvider);
  return VaultNotifier(service);
});

/// Convenience providers
final isVaultUnlockedProvider = Provider<bool>((ref) {
  return ref.watch(vaultProvider).isUnlocked;
});

final isBiometricAvailableProvider = Provider<bool>((ref) {
  return ref.watch(vaultProvider).isBiometricAvailable;
});
