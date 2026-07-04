import 'dart:async' hide TimeoutException;
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/exceptions/network_exceptions.dart';
import 'package:somine_app/core/models/notification_model.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';
import 'package:somine_app/core/services/backend_realtime_service.dart';

class NotificationRepository {
  final BackendAuthService _backendAuthService = BackendAuthService();
  final BackendRealtimeService _backendRealtimeService =
      BackendRealtimeService();
  final http.Client _httpClient = http.Client();
  static const Duration _requestTimeout = Duration(seconds: 15);

  Stream<List<NotificationModel>> getNotifications(String userId) async* {
    var notifications = await _getNotificationsFromApi(userId);
    var lastSignature = _notificationsSignature(notifications);
    yield notifications;

    await for (final _ in _backendRealtimeService.notificationsChanges) {
      notifications = await _getNotificationsFromApi(userId);
      final signature = _notificationsSignature(notifications);

      if (signature == lastSignature) {
        continue;
      }

      lastSignature = signature;
      yield notifications;
    }
  }

  Stream<int> getUnreadCount(String userId) {
    return getNotifications(
      userId,
    ).map((notifications) => notifications.where((n) => !n.isRead).length);
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.put(
          _buildUri('/api/notifications/$notificationId/read'),
          headers: _jsonHeaders(accessToken),
        ),
        'mark notification as read',
      );

      _throwIfNotSuccessful(response, action: 'mark notification as read');
    } catch (e) {
      debugPrint(
        '❌ [NotificationRepository] Error marking notification as read: $e',
      );
      rethrow;
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.put(
          _buildUri('/api/notifications/read-all'),
          headers: _jsonHeaders(accessToken),
        ),
        'mark all notifications as read',
      );

      _throwIfNotSuccessful(
        response,
        action: 'mark all notifications as read',
      );
    } catch (e) {
      debugPrint(
        '❌ [NotificationRepository] Error marking all notifications as read: $e',
      );
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _withTimeout(
        _httpClient.delete(
          _buildUri('/api/notifications/$notificationId'),
          headers: _jsonHeaders(accessToken),
        ),
        'delete notification',
      );

      _throwIfNotSuccessful(response, action: 'delete notification');
    } catch (e) {
      debugPrint('❌ [NotificationRepository] Error deleting notification: $e');
      rethrow;
    }
  }

  Future<void> deleteNotificationsByShareId(
    String userId,
    String shareId,
  ) async {
    try {
      final notifications = await _getNotificationsFromApi(userId);
      final relatedNotifications =
          notifications
              .where(
                (notification) => notification.data['shareId'] == shareId,
              )
              .toList();

      for (final notification in relatedNotifications) {
        if (notification.id != null) {
          await deleteNotification(notification.id!);
        }
      }
    } catch (e) {
      debugPrint(
        '❌ [NotificationRepository] Error deleting notifications for shareId: $e',
      );
    }
  }

  Future<void> deleteAllUserNotifications(String userId) async {
    try {
      final notifications = await _getNotificationsFromApi(userId);
      for (final n in notifications) {
        if (n.id != null) {
          try {
            await deleteNotification(n.id!);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('❌ [NotificationRepository] Error deleting all notifications: $e');
    }
  }

  Future<List<NotificationModel>> _getNotificationsFromApi(
    String userId,
  ) async {
    final accessToken = await _requireAccessToken();
    final response = await _withTimeout(
      _httpClient.get(
        _buildUri('/api/notifications'),
        headers: _jsonHeaders(accessToken),
      ),
      'fetch notifications',
    );

    _throwIfNotSuccessful(response, action: 'fetch notifications');

    final payload = jsonDecode(response.body) as List<dynamic>;
    final notifications =
        payload
            .whereType<Map<String, dynamic>>()
            .map((json) => NotificationModel.fromApi(json, userId: userId))
            .toList();
    notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return notifications;
  }

  Future<NotificationModel?> getNotificationById(
    String userId,
    String notificationId,
  ) async {
    final accessToken = await _requireAccessToken();
    final response = await _withTimeout(
      _httpClient.get(
        _buildUri('/api/notifications/$notificationId'),
        headers: _jsonHeaders(accessToken),
      ),
      'fetch notification',
    );

    if (response.statusCode == 404) {
      return null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return NotificationModel.fromApi(
        jsonDecode(response.body) as Map<String, dynamic>,
        userId: userId,
      );
    }

    final notifications = await _getNotificationsFromApi(userId);
    for (final notification in notifications) {
      if (notification.id == notificationId) {
        return notification;
      }
    }

    _throwIfNotSuccessful(response, action: 'fetch notification');
    return NotificationModel.fromApi(
      jsonDecode(response.body) as Map<String, dynamic>,
      userId: userId,
    );
  }

  Future<String> _requireAccessToken() async {
    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      throw const UnauthorizedException(
        'backend access token missing',
        userMessage: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      );
    }

    return accessToken;
  }

  Uri _buildUri(String path) {
    final baseUrl = ApiConfig.baseUrl;
    final normalizedBase =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    return Uri.parse('$normalizedBase$path');
  }

  Map<String, String> _jsonHeaders(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (ApiConfig.apiKey.isNotEmpty) 'X-SoMine-Api-Key': ApiConfig.apiKey,
      'Authorization': 'Bearer $accessToken',
    };
  }

  Future<T> _withTimeout<T>(Future<T> future, String action) {
    return future.timeout(
      _requestTimeout,
      onTimeout:
          () =>
              throw TimeoutException(
                '$action timed out after ${_requestTimeout.inSeconds} seconds',
                userMessage:
                    'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.',
              ),
    );
  }

  void _throwIfNotSuccessful(http.Response response, {required String action}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    debugPrint(
      'API Error [$action]: ${response.statusCode} - ${response.body}',
    );

    throw switch (response.statusCode) {
      401 => const UnauthorizedException(
        'notification request unauthorized',
        userMessage: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      ),
      409 => const ConflictException(
        'notification request conflict',
        userMessage: 'Bu işlem zaten yapıldı.',
      ),
      >= 400 && < 500 => ValidationException(
        'notification request failed',
        userMessage: _parseApiError(response.body),
      ),
      >= 500 => const ServerException(
        'notification server error',
        userMessage: 'Sunucu hatası oluştu. Lütfen biraz sonra tekrar deneyin.',
      ),
      _ => const ServerException(
        'notification request failed',
        userMessage: 'İşlem başarısız oldu. Lütfen tekrar deneyin.',
      ),
    };
  }

  String _parseApiError(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>?;
      return json?['message'] as String? ??
          json?['error'] as String? ??
          'İşlem başarısız oldu. Lütfen tekrar deneyin.';
    } catch (_) {
      return 'İşlem başarısız oldu. Lütfen tekrar deneyin.';
    }
  }

  String _notificationsSignature(List<NotificationModel> notifications) {
    return notifications
        .map(
          (notification) =>
              '${notification.id}|${notification.type.name}|${notification.isRead}|${notification.createdAt.toUtc().millisecondsSinceEpoch}',
        )
        .join('||');
  }
}
