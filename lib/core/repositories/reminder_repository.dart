import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/exceptions/network_exceptions.dart';
import 'package:somine_app/core/models/reminder_model.dart';
import 'package:somine_app/core/services/api_client.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';

class ReminderRepository {
  final BackendAuthService _backendAuthService = BackendAuthService();
  final ApiClient _apiClient = ApiClient();

  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.post(
        _buildUri('/api/reminders'),
        headers: _jsonHeaders(accessToken),
        body: jsonEncode(reminder.toApiCreateRequest()),
      );

      _throwIfNotSuccessful(response, action: 'create reminder');
      return ReminderModel.fromApi(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error creating reminder: $e');
      rethrow;
    }
  }

  Future<ReminderModel?> getReminder(String reminderId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.get(
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
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error getting reminder: $e');
      rethrow;
    }
  }

  Future<List<ReminderModel>> getUserReminders(String userId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.get(
        _buildUri('/api/reminders'),
        headers: _jsonHeaders(accessToken),
      );

      _throwIfNotSuccessful(response, action: 'fetch reminders');
      return _parseReminderList(response.body);
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error getting user reminders: $e');
      rethrow;
    }
  }

  Future<ReminderModel?> getItemReminder(String itemId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.get(
        _buildUri('/api/reminders', queryParameters: {'itemId': itemId}),
        headers: _jsonHeaders(accessToken),
      );

      _throwIfNotSuccessful(response, action: 'fetch item reminder');
      final reminders = await _parseReminderList(response.body);
      return reminders.isEmpty ? null : reminders.first;
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error getting item reminder: $e');
      rethrow;
    }
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.put(
        _buildUri('/api/reminders/${reminder.id}'),
        headers: _jsonHeaders(accessToken),
        body: jsonEncode(reminder.toApiUpdateRequest()),
      );

      _throwIfNotSuccessful(response, action: 'update reminder');
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error updating reminder: $e');
      rethrow;
    }
  }

  Future<void> toggleReminder(String reminderId, bool isActive) async {
    try {
      final reminder = await getReminder(reminderId);
      if (reminder == null) {
        throw Exception('Reminder not found');
      }

      await updateReminder(reminder.copyWith(isActive: isActive));
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error toggling reminder: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.delete(
        _buildUri('/api/reminders/$reminderId'),
        headers: _jsonHeaders(accessToken),
      );

      _throwIfNotSuccessful(response, action: 'delete reminder');
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error deleting reminder: $e');
      rethrow;
    }
  }

  Future<void> deleteItemReminders(String itemId) async {
    try {
      final reminder = await getItemReminder(itemId);
      if (reminder?.id == null) return;
      await deleteReminder(reminder!.id!);
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
    while (true) {
      yield await getUserReminders(userId);
      await Future<void>.delayed(const Duration(seconds: 2));
    }
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
      throw const UnauthorizedException(
        'backend access token missing',
        userMessage: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      );
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
      if (ApiConfig.apiKey.isNotEmpty) 'X-SoMine-Api-Key': ApiConfig.apiKey,
      'Authorization': 'Bearer $accessToken',
    };
  }

  void _throwIfNotSuccessful(http.Response response, {required String action}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    debugPrint('API Error [$action]: ${response.statusCode}');

    throw switch (response.statusCode) {
      401 => const UnauthorizedException(
        'reminder request unauthorized',
        userMessage: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      ),
      409 => const ConflictException(
        'reminder request conflict',
        userMessage: 'Bu işlem zaten yapıldı.',
      ),
      >= 400 && < 500 => ValidationException(
        'reminder request failed',
        userMessage: _parseApiError(response.body),
      ),
      >= 500 => const ServerException(
        'reminder server error',
        userMessage: 'Sunucu hatası oluştu. Lütfen biraz sonra tekrar deneyin.',
      ),
      _ => const ServerException(
        'reminder request failed',
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
}
