import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/models/notification_model.dart';
import 'package:somine_app/core/repositories/notification_repository.dart';
import 'package:somine_app/core/providers/auth_providers.dart';

/// NotificationRepository provider
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

/// Tüm bildirimler - Stream provider
final notificationsProvider = StreamProvider.autoDispose<List<NotificationModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  
  return authState.when(
    data: (user) {
      if (user != null) {
        return notificationRepo.getNotifications(user.uid);
      }
      return Stream.value([]);
    },
    loading: () => Stream.value([]),
    error: (_, __) => Stream.value([]),
  );
});

/// Okunmamış bildirim sayısı - Stream provider
final unreadNotificationCountProvider = StreamProvider.autoDispose<int>((ref) {
  final authState = ref.watch(authStateProvider);
  final notificationRepo = ref.watch(notificationRepositoryProvider);
  
  return authState.when(
    data: (user) {
      if (user != null) {
        return notificationRepo.getUnreadCount(user.uid);
      }
      return Stream.value(0);
    },
    loading: () => Stream.value(0),
    error: (_, __) => Stream.value(0),
  );
});
