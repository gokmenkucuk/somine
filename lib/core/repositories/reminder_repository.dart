import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/models/reminder_model.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';

class ReminderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BackendAuthService _backendAuthService = BackendAuthService();
  final http.Client _httpClient = http.Client();

  CollectionReference get _remindersCollection =>
      _firestore.collection('reminders');

  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    try {
      if (_shouldUseBackendForCurrentUser()) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.post(
          _buildUri('/api/reminders'),
          headers: _jsonHeaders(accessToken),
          body: jsonEncode(reminder.toApiCreateRequest()),
        );

        _throwIfNotSuccessful(response, action: 'create reminder');
        return ReminderModel.fromApi(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      final docRef = await _remindersCollection.add(reminder.toFirestore());
      final doc = await docRef.get();
      return ReminderModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error creating reminder: $e');
      rethrow;
    }
  }

  Future<ReminderModel?> getReminder(String reminderId) async {
    try {
      if (_shouldUseBackendForCurrentUser()) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.get(
          _buildUri('/api/reminders/$reminderId'),
          headers: _jsonHeaders(accessToken),
        );

        if (response.statusCode == 404) {
          return null;
        }

        _throwIfNotSuccessful(response, action: 'fetch reminder');
        return ReminderModel.fromApi(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      final doc = await _remindersCollection.doc(reminderId).get();
      if (doc.exists) {
        return ReminderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error getting reminder: $e');
      rethrow;
    }
  }

  Future<List<ReminderModel>> getUserReminders(String userId) async {
    try {
      if (_useBackendForCurrentUser(userId)) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.get(
          _buildUri('/api/reminders'),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'fetch reminders');
        return _parseReminderList(response.body);
      }

      final itemsSnapshot =
          await _firestore
              .collection('items')
              .where('userId', isEqualTo: userId)
              .where('hasReminder', isEqualTo: true)
              .get();

      if (itemsSnapshot.docs.isEmpty) return [];

      final itemIds = itemsSnapshot.docs.map((d) => d.id).toList();
      final remindersSnapshot =
          await _remindersCollection
              .where('itemId', whereIn: itemIds)
              .where('isActive', isEqualTo: true)
              .get();

      return remindersSnapshot.docs
          .map((doc) => ReminderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error getting user reminders: $e');
      rethrow;
    }
  }

  Future<ReminderModel?> getItemReminder(String itemId) async {
    try {
      if (_shouldUseBackendForCurrentUser()) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.get(
          _buildUri('/api/reminders', queryParameters: {'itemId': itemId}),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'fetch item reminder');
        final reminders = await _parseReminderList(response.body);
        return reminders.isEmpty ? null : reminders.first;
      }

      final snapshot =
          await _remindersCollection
              .where('itemId', isEqualTo: itemId)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;
      return ReminderModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error getting item reminder: $e');
      rethrow;
    }
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      if (_shouldUseBackendForCurrentUser()) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.put(
          _buildUri('/api/reminders/${reminder.id}'),
          headers: _jsonHeaders(accessToken),
          body: jsonEncode(reminder.toApiUpdateRequest()),
        );

        _throwIfNotSuccessful(response, action: 'update reminder');
        return;
      }

      await _remindersCollection.doc(reminder.id).update({
        'reminderDate': Timestamp.fromDate(reminder.reminderDate),
        'reminderTime': {
          'hour': reminder.reminderTime.hour,
          'minute': reminder.reminderTime.minute,
        },
        'repeat': reminder.repeat.name,
        'isActive': reminder.isActive,
        'customRepeatDays': reminder.customRepeatDays,
        'customRepeatMinutes': reminder.customRepeatMinutes,
      });
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error updating reminder: $e');
      rethrow;
    }
  }

  Future<void> toggleReminder(String reminderId, bool isActive) async {
    try {
      if (_shouldUseBackendForCurrentUser()) {
        final reminder = await getReminder(reminderId);
        if (reminder == null) {
          throw Exception('Reminder not found');
        }

        await updateReminder(reminder.copyWith(isActive: isActive));
        return;
      }

      await _remindersCollection.doc(reminderId).update({'isActive': isActive});
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error toggling reminder: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      if (_shouldUseBackendForCurrentUser()) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.delete(
          _buildUri('/api/reminders/$reminderId'),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'delete reminder');
        return;
      }

      await _remindersCollection.doc(reminderId).delete();
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error deleting reminder: $e');
      rethrow;
    }
  }

  Future<void> deleteItemReminders(String itemId) async {
    try {
      if (_shouldUseBackendForCurrentUser()) {
        final reminder = await getItemReminder(itemId);
        if (reminder?.id == null) return;
        await deleteReminder(reminder!.id!);
        return;
      }

      final snapshot =
          await _remindersCollection.where('itemId', isEqualTo: itemId).get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error deleting item reminders: $e');
      rethrow;
    }
  }

  Future<List<ReminderModel>> getUpcomingReminders(String userId) async {
    try {
      final now = DateTime.now();
      final userReminders = await getUserReminders(userId);

      return userReminders.where((r) {
          final nextOccurrence = r.calculateNextOccurrence();
          return nextOccurrence.isAfter(now) &&
              nextOccurrence.isBefore(now.add(const Duration(days: 30)));
        }).toList()
        ..sort(
          (a, b) => a.calculateNextOccurrence().compareTo(
            b.calculateNextOccurrence(),
          ),
        );
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error getting upcoming reminders: $e');
      return [];
    }
  }

  Stream<List<ReminderModel>> streamUserReminders(String userId) async* {
    if (!_useBackendForCurrentUser(userId)) {
      yield* _firestore
          .collection('items')
          .where('userId', isEqualTo: userId)
          .where('hasReminder', isEqualTo: true)
          .snapshots()
          .asyncMap((itemsSnapshot) async {
            if (itemsSnapshot.docs.isEmpty) return <ReminderModel>[];

            final itemIds = itemsSnapshot.docs.map((d) => d.id).toList();
            final remindersSnapshot =
                await _remindersCollection
                    .where('itemId', whereIn: itemIds)
                    .where('isActive', isEqualTo: true)
                    .get();

            return remindersSnapshot.docs
                .map((doc) => ReminderModel.fromFirestore(doc))
                .toList();
          });
      return;
    }

    while (true) {
      yield await getUserReminders(userId);
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  bool _shouldUseBackendForCurrentUser() {
    return _backendAuthService.isEnabled &&
        FirebaseAuth.instance.currentUser != null;
  }

  bool _useBackendForCurrentUser(String userId) {
    return _backendAuthService.isEnabled &&
        FirebaseAuth.instance.currentUser?.uid == userId;
  }

  Future<List<ReminderModel>> _parseReminderList(String responseBody) async {
    final payload = jsonDecode(responseBody) as List<dynamic>;
    return payload
        .whereType<Map<String, dynamic>>()
        .map(ReminderModel.fromApi)
        .toList();
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

  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final baseUrl = ApiConfig.baseUrl;
    final normalizedBase =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    return Uri.parse('$normalizedBase$path').replace(
      queryParameters:
          queryParameters?.isEmpty == true ? null : queryParameters,
    );
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
}
