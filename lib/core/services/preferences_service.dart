import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';

class PreferencesService {
  static const String _keySearchHistory = 'search_history';
  static const String _keyThemeMode = 'theme_mode';
  static const int _searchHistoryLimit = 10;

  static final PreferencesService _instance = PreferencesService._internal();

  factory PreferencesService() => _instance;

  PreferencesService._internal();

  final BackendAuthService _backendAuthService = BackendAuthService();
  final http.Client _httpClient = http.Client();

  Future<List<String>> getSearchHistoryFirebase(String userId) async {
    if (_shouldUseBackend(userId)) {
      try {
        final history = await _fetchBackendSearchHistory();
        await _persistLocalHistory(history);
        return history;
      } catch (e) {
        debugPrint(
          '⚠️ [PreferencesService] Backend search history fetch failed: $e',
        );
      }
    }

    return getSearchHistory();
  }

  Future<void> addSearchTermFirebase(String userId, String term) async {
    final normalizedTerm = term.trim();
    if (normalizedTerm.isEmpty) return;

    try {
      final history = await getSearchHistoryFirebase(userId);
      history.removeWhere(
        (existing) => existing.toLowerCase() == normalizedTerm.toLowerCase(),
      );
      history.insert(0, normalizedTerm);

      if (history.length > _searchHistoryLimit) {
        history.removeRange(_searchHistoryLimit, history.length);
      }

      await _saveSearchHistory(userId, history);
    } catch (e) {
      debugPrint('⚠️ [PreferencesService] Search history add failed: $e');
      await addSearchTerm(normalizedTerm);
    }
  }

  Future<void> removeSearchTermFirebase(String userId, String term) async {
    try {
      final history = await getSearchHistoryFirebase(userId);
      history.removeWhere(
        (existing) => existing.toLowerCase() == term.trim().toLowerCase(),
      );

      await _saveSearchHistory(userId, history);
    } catch (e) {
      debugPrint('⚠️ [PreferencesService] Search history remove failed: $e');
      await removeSearchTerm(term);
    }
  }

  Future<void> clearSearchHistoryFirebase(String userId) async {
    try {
      await _saveSearchHistory(userId, const []);
    } catch (e) {
      debugPrint('⚠️ [PreferencesService] Search history clear failed: $e');
      await clearSearchHistory();
    }
  }

  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySearchHistory) ?? [];
  }

  Future<void> addSearchTerm(String term) async {
    final normalizedTerm = term.trim();
    if (normalizedTerm.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_keySearchHistory) ?? [];

    history.removeWhere(
      (existing) => existing.toLowerCase() == normalizedTerm.toLowerCase(),
    );
    history.insert(0, normalizedTerm);

    if (history.length > _searchHistoryLimit) {
      history.removeRange(_searchHistoryLimit, history.length);
    }

    await prefs.setStringList(_keySearchHistory, history);
  }

  Future<void> removeSearchTerm(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_keySearchHistory) ?? [];

    history.removeWhere(
      (existing) => existing.toLowerCase() == term.trim().toLowerCase(),
    );
    await prefs.setStringList(_keySearchHistory, history);
  }

  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySearchHistory);
  }

  Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'air';
  }

  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, theme);
  }

  bool _shouldUseBackend(String userId) {
    return _backendAuthService.isEnabled &&
        FirebaseAuth.instance.currentUser?.uid == userId;
  }

  Future<void> _saveSearchHistory(String userId, List<String> history) async {
    final normalizedHistory = _normalizeHistory(history);

    if (_shouldUseBackend(userId)) {
      try {
        await _updateBackendSearchHistory(normalizedHistory);
      } catch (e) {
        debugPrint(
          '⚠️ [PreferencesService] Backend search history save failed: $e',
        );
      }
    }

    await _persistLocalHistory(normalizedHistory);
  }

  Future<List<String>> _fetchBackendSearchHistory() async {
    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No backend access token available.');
    }

    final response = await _httpClient.get(
      _buildUri('/api/users/me/search-history'),
      headers: _jsonHeaders(accessToken),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch search history. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final terms = (json['terms'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();

    return _normalizeHistory(terms);
  }

  Future<void> _updateBackendSearchHistory(List<String> history) async {
    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No backend access token available.');
    }

    final response = await _httpClient.put(
      _buildUri('/api/users/me/search-history'),
      headers: _jsonHeaders(accessToken),
      body: jsonEncode({'terms': history}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to update search history. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }
  }

  Future<void> _persistLocalHistory(List<String> history) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySearchHistory, history);
  }

  List<String> _normalizeHistory(List<String> history) {
    final normalized = <String>[];

    for (final term in history) {
      final trimmed = term.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      normalized.removeWhere(
        (existing) => existing.toLowerCase() == trimmed.toLowerCase(),
      );
      normalized.add(trimmed);

      if (normalized.length == _searchHistoryLimit) {
        break;
      }
    }

    return normalized;
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
}
