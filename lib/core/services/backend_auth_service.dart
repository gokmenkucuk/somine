import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/models/backend_auth_session.dart';

enum BackendIdentityProvider { google, apple }

class BackendAuthService {
  final http.Client _httpClient;

  BackendAuthService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  bool get isEnabled => ApiConfig.isBackendAuthEnabled;

  String get _sessionStorageKey {
    final rawBaseUrl = ApiConfig.baseUrl.trim();
    if (rawBaseUrl.isEmpty) {
      return 'backend_auth_session';
    }

    final normalizedBaseUrl =
        rawBaseUrl
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'_+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '');

    return 'backend_auth_session_$normalizedBaseUrl';
  }

  Future<BackendAuthSession?> getStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    return BackendAuthSession.tryDecode(prefs.getString(_sessionStorageKey));
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionStorageKey);
  }

  Future<void> saveSession(BackendAuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionStorageKey, session.encode());
  }

  Future<BackendAuthSession?> ensureSession(
    User firebaseUser, {
    BackendIdentityProvider? provider,
    bool forceRefresh = false,
  }) async {
    if (!isEnabled) {
      debugPrint('⚪ [BackendAuthService] Backend auth disabled. Skipping.');
      return null;
    }

    final existingSession = await getStoredSession();
    if (!forceRefresh &&
        existingSession != null &&
        !existingSession.isExpired) {
      return existingSession;
    }

    if (!forceRefresh &&
        existingSession != null &&
        existingSession.refreshToken.isNotEmpty) {
      try {
        final refreshedSession = await _refresh(existingSession.refreshToken);
        await saveSession(refreshedSession);
        return refreshedSession;
      } catch (e) {
        debugPrint(
          '⚠️ [BackendAuthService] Refresh failed, retrying with Firebase token: $e',
        );
      }
    }

    final resolvedProvider = provider ?? _resolveProvider(firebaseUser);
    if (resolvedProvider == null) {
      debugPrint(
        '⚠️ [BackendAuthService] No supported provider found for backend token exchange.',
      );
      return existingSession;
    }

    final firebaseIdToken = await firebaseUser.getIdToken(true);
    if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
      throw Exception('Firebase ID token could not be obtained.');
    }
    final exchangedSession = await _exchangeFirebaseToken(
      provider: resolvedProvider,
      firebaseIdToken: firebaseIdToken,
    );

    await saveSession(exchangedSession);
    return exchangedSession;
  }

  Future<String?> getValidAccessToken({User? firebaseUser}) async {
    if (!isEnabled) return null;

    final session = await getStoredSession();
    if (session != null && !session.isExpired) {
      return session.accessToken;
    }

    final user = firebaseUser ?? FirebaseAuth.instance.currentUser;
    if (user == null) {
      await clearSession();
      return null;
    }

    final ensuredSession = await ensureSession(user);
    return ensuredSession?.accessToken;
  }

  Future<void> logout() async {
    final session = await getStoredSession();

    if (!isEnabled || session == null) {
      await clearSession();
      return;
    }

    try {
      final response = await _httpClient.post(
        _buildUri('/api/auth/logout'),
        headers: _jsonHeaders(bearerToken: session.accessToken),
        body: jsonEncode({'refreshToken': session.refreshToken}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '⚠️ [BackendAuthService] Logout request failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [BackendAuthService] Logout request error: $e');
    } finally {
      await clearSession();
    }
  }

  Future<BackendAuthSession> _exchangeFirebaseToken({
    required BackendIdentityProvider provider,
    required String firebaseIdToken,
  }) async {
    final endpoint = switch (provider) {
      BackendIdentityProvider.google => '/api/auth/google',
      BackendIdentityProvider.apple => '/api/auth/apple',
    };

    final response = await _httpClient.post(
      _buildUri(endpoint),
      headers: _jsonHeaders(),
      body: jsonEncode({'idToken': firebaseIdToken}),
    );

    _throwIfNotSuccessful(response, action: 'exchange Firebase token');
    return BackendAuthSession.fromAuthResponse(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<BackendAuthSession> _refresh(String refreshToken) async {
    final response = await _httpClient.post(
      _buildUri('/api/auth/refresh'),
      headers: _jsonHeaders(),
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    _throwIfNotSuccessful(response, action: 'refresh backend token');
    return BackendAuthSession.fromAuthResponse(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  BackendIdentityProvider? _resolveProvider(User firebaseUser) {
    for (final providerInfo in firebaseUser.providerData) {
      switch (providerInfo.providerId) {
        case 'google.com':
          return BackendIdentityProvider.google;
        case 'apple.com':
          return BackendIdentityProvider.apple;
      }
    }

    return null;
  }

  Uri _buildUri(String path) {
    final baseUrl = ApiConfig.baseUrl;
    final normalizedBase =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    return Uri.parse('$normalizedBase$path');
  }

  Map<String, String> _jsonHeaders({String? bearerToken}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (bearerToken != null && bearerToken.isNotEmpty)
        'Authorization': 'Bearer $bearerToken',
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
