import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/models/share_model.dart';
import 'package:somine_app/core/repositories/share_repository.dart';
import 'package:somine_app/core/providers/auth_providers.dart';

/// ShareRepository provider
final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  return ShareRepository();
});

/// Paylaştıklarım - Stream provider
final mySharesProvider = StreamProvider.autoDispose<List<ShareModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final shareRepo = ref.watch(shareRepositoryProvider);
  
  return authState.when(
    data: (user) {
      if (user != null) {
        return shareRepo.getMyShares(user.uid);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Benimle paylaşılanlar (kabul edilenler) - Stream provider
final sharedWithMeProvider = StreamProvider.autoDispose<List<ShareModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final shareRepo = ref.watch(shareRepositoryProvider);
  
  return authState.when(
    data: (user) {
      if (user != null) {
        return shareRepo.getSharedWithMe(user.uid);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Bekleyen paylaşım istekleri - Stream provider
final pendingShareRequestsProvider = StreamProvider.autoDispose<List<ShareModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final shareRepo = ref.watch(shareRepositoryProvider);
  
  return authState.when(
    data: (user) {
      if (user != null) {
        return shareRepo.getPendingShareRequests(user.uid);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Bekleyen paylaşım isteği sayısı
final pendingShareRequestCountProvider = Provider.autoDispose<int>((ref) {
  final pendingRequests = ref.watch(pendingShareRequestsProvider);
  return pendingRequests.valueOrNull?.length ?? 0;
});
