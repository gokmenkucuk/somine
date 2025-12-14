import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/repositories/auth_repository.dart';

/// Guest user state - tracks if user is using app without auth
class GuestUserState {
  final bool isGuest;
  final bool hasPerformedAction; // If guest user added/deleted items

  const GuestUserState({
    this.isGuest = false,
    this.hasPerformedAction = false,
  });

  GuestUserState copyWith({
    bool? isGuest,
    bool? hasPerformedAction,
  }) {
    return GuestUserState(
      isGuest: isGuest ?? this.isGuest,
      hasPerformedAction: hasPerformedAction ?? this.hasPerformedAction,
    );
  }
}

/// Guest user state provider
final guestUserStateProvider = StateNotifierProvider<GuestUserStateNotifier, GuestUserState>((ref) {
  return GuestUserStateNotifier();
});

class GuestUserStateNotifier extends StateNotifier<GuestUserState> {
  GuestUserStateNotifier() : super(const GuestUserState());

  void setGuestMode(bool isGuest) {
    state = state.copyWith(isGuest: isGuest);
  }

  void markActionPerformed() {
    if (state.isGuest) {
      state = state.copyWith(hasPerformedAction: true);
    }
  }

  void reset() {
    state = const GuestUserState();
  }
}

/// Auth repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Current user stream provider
final authStateProvider = StreamProvider<User?>((ref) async* {
  try {
    final authRepository = ref.watch(authRepositoryProvider);
    await for (final user in authRepository.authStateChanges) {
      yield user;
    }
  } catch (e, stack) {
    debugPrint('Auth state stream error: $e');
    debugPrint('Stack trace: $stack');
    yield null; // Return null on error instead of crashing
  }
});

/// Current user provider (synchronous)
final currentUserProvider = Provider<User?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.currentUser;
});

/// Combined auth state - checks if user is authenticated OR is guest
final isAuthenticatedOrGuestProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  final guestState = ref.watch(guestUserStateProvider);
  
  return authState.when(
    data: (user) => user != null || guestState.isGuest,
    loading: () => false,
    error: (_, __) => false,
  );
});
