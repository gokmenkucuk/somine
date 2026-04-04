import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/models/notification_model.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';
import 'package:somine_app/core/services/backend_realtime_service.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BackendAuthService _backendAuthService = BackendAuthService();
  final BackendRealtimeService _backendRealtimeService =
      BackendRealtimeService();
  final http.Client _httpClient = http.Client();

  CollectionReference get _notificationsCollection =>
      _firestore.collection('notifications');

  Future<NotificationModel> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final notification = NotificationModel(
        userId: userId,
        type: type,
        title: title,
        message: message,
        data: data,
        isRead: false,
        createdAt: DateTime.now(),
      );

      final docRef = await _notificationsCollection.add(
        notification.toFirestore(),
      );
      return notification.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('❌ [NotificationRepository] Error creating notification: $e');
      rethrow;
    }
  }

  Stream<List<NotificationModel>> getNotifications(String userId) async* {
    if (!_useBackendForCurrentUser(userId)) {
      yield* _notificationsCollection
          .where('userId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final docs =
                snapshot.docs
                    .map((doc) => NotificationModel.fromFirestore(doc))
                    .toList();
            docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return docs;
          });
      return;
    }

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
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.put(
          _buildUri('/api/notifications/$notificationId/read'),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'mark notification as read');
        return;
      }

      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint(
        '❌ [NotificationRepository] Error marking notification as read: $e',
      );
      rethrow;
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.put(
          _buildUri('/api/notifications/read-all'),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(
          response,
          action: 'mark all notifications as read',
        );
        return;
      }

      final batch = _firestore.batch();
      final snapshot =
          await _notificationsCollection
              .where('userId', isEqualTo: userId)
              .where('isRead', isEqualTo: false)
              .get();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      debugPrint(
        '❌ [NotificationRepository] Error marking all notifications as read: $e',
      );
      rethrow;
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.delete(
          _buildUri('/api/notifications/$notificationId'),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'delete notification');
        return;
      }

      await _notificationsCollection.doc(notificationId).delete();
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
      if (_useBackendForCurrentUser(userId)) {
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
        return;
      }

      final snapshot =
          await _notificationsCollection
              .where('userId', isEqualTo: userId)
              .where('data.shareId', isEqualTo: shareId)
              .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint(
        '❌ [NotificationRepository] Error deleting notifications for shareId: $e',
      );
    }
  }

  bool _useBackendForCurrentUser(String userId) {
    return _backendAuthService.isEnabled &&
        FirebaseAuth.instance.currentUser?.uid == userId;
  }

  Future<List<NotificationModel>> _getNotificationsFromApi(
    String userId,
  ) async {
    final accessToken = await _requireAccessToken();
    final response = await _httpClient.get(
      _buildUri('/api/notifications'),
      headers: _jsonHeaders(accessToken),
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
    final response = await _httpClient.get(
      _buildUri('/api/notifications/$notificationId'),
      headers: _jsonHeaders(accessToken),
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
      throw Exception('Backend access token could not be obtained.');
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
      'Authorization': 'Bearer $accessToken',
    };
  }

  void _throwIfNotSuccessful(http.Response response, {required String action}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'Failed to $action. Status: ${response.statusCode}. Body: ${response.body}',
    );
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
