import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/exceptions/network_exceptions.dart';
import 'package:somine_app/core/models/backend_auth_session.dart';
import 'package:somine_app/core/services/api_client.dart';
import 'package:somine_app/core/utils/exponential_backoff.dart';

enum BackendIdentityProvider { google, apple }

class BackendAuthService {
  // Circuit breaker tuning (single place to adjust).
  static const int _circuitFailureThreshold = 5;
  static const Duration _circuitInitialCooldown = Duration(seconds: 60);
  static const Duration _circuitMaxCooldown = Duration(minutes: 10);

  static final BackendAuthService _instance = BackendAuthService._internal();
  factory BackendAuthService() => _instance;
  BackendAuthService._internal() : _apiClient = ApiClient();

  final ApiClient _apiClient;

  /// Backend session tokens live in the iOS Keychain (device-bound, not synced
  /// to iCloud backups) instead of plaintext SharedPreferences.
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Dedups concurrent [ensureSession] calls into a single in-flight future.
  Future<BackendAuthSession?>? _inFlightEnsureSession;

  int _consecutiveFailures = 0;
  DateTime? _circuitOpenedAt;
  Duration _currentCooldown = _circuitInitialCooldown;
  final ExponentialBackoff _circuitCooldownBackoff = ExponentialBackoff(
    baseDelay: _circuitInitialCooldown,
    jitterFactor: 0,
    maxDelay: _circuitMaxCooldown,
  );

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
    final key = _sessionStorageKey;

    String? raw;
    try {
      raw = await _secureStorage.read(key: key);
    } catch (e) {
      debugPrint('⚠️ [BackendAuthService] Secure storage read failed: $e');
    }

    if (raw != null && raw.isNotEmpty) {
      return BackendAuthSession.tryDecode(raw);
    }

    // One-time migration: pull any legacy plaintext session out of
    // SharedPreferences into the Keychain, then wipe the plaintext copy.
    return _migrateLegacySession(key);
  }

  /// Moves a legacy SharedPreferences session into secure storage. Best-effort:
  /// on any failure we return whatever we could decode and leave [ensureSession]
  /// to re-exchange a fresh session from the Firebase token.
  Future<BackendAuthSession?> _migrateLegacySession(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final legacyRaw = prefs.getString(key);
      if (legacyRaw == null || legacyRaw.isEmpty) return null;

      final session = BackendAuthSession.tryDecode(legacyRaw);
      if (session != null) {
        try {
          await _secureStorage.write(key: key, value: legacyRaw);
        } catch (e) {
          debugPrint(
            '⚠️ [BackendAuthService] Session migration write failed: $e',
          );
        }
      }
      // Always drop the plaintext copy once handled (or if undecodable).
      await prefs.remove(key);
      return session;
    } catch (e) {
      debugPrint('⚠️ [BackendAuthService] Session migration failed: $e');
      return null;
    }
  }

  Future<void> clearSession() async {
    resetFailureState();
    final key = _sessionStorageKey;
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      debugPrint('⚠️ [BackendAuthService] Secure storage delete failed: $e');
    }
    // Also clear any lingering plaintext copy from before the migration.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }

  /// Keychain yazması (SharedPreferences'ın aksine) başarısız olabilir.
  /// Kalıcılık kaybı oturum akışını KIRMAMALI: bu koşuda session bellekte
  /// geçerli kalır, sonraki açılışta Firebase token'ıyla yeniden exchange edilir.
  Future<void> saveSession(BackendAuthSession session) async {
    try {
      await _secureStorage.write(
        key: _sessionStorageKey,
        value: session.encode(),
      );
    } catch (e) {
      debugPrint('⚠️ [BackendAuthService] Secure storage write failed: $e');
    }
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

    // Concurrent callers share the same in-flight attempt instead of each
    // firing their own refresh/exchange request.
    final inFlight = _inFlightEnsureSession;
    if (inFlight != null) return inFlight;

    final future = _ensureSessionInternal(
      firebaseUser,
      provider: provider,
      forceRefresh: forceRefresh,
    );
    _inFlightEnsureSession = future;
    try {
      return await future;
    } finally {
      _inFlightEnsureSession = null;
    }
  }

  Future<BackendAuthSession?> _ensureSessionInternal(
    User firebaseUser, {
    BackendIdentityProvider? provider,
    bool forceRefresh = false,
  }) async {
    final existingSession = await getStoredSession();
    if (!forceRefresh &&
        existingSession != null &&
        !existingSession.isExpired) {
      return existingSession;
    }

    _throwIfCircuitOpen();

    try {
      if (!forceRefresh &&
          existingSession != null &&
          existingSession.refreshToken.isNotEmpty) {
        try {
          final refreshedSession = await _refresh(existingSession.refreshToken);
          await saveSession(refreshedSession);
          _recordSuccess();
          return refreshedSession;
        } catch (e) {
          final tokenRejected = e is AppException && !e.retryable;
          if (!tokenRejected) {
            // Transient failure (network/timeout/server): do not burn the
            // refresh token with a Firebase exchange; surface a retryable
            // error instead.
            debugPrint(
              '⚠️ [BackendAuthService] Refresh failed with retryable error: $e',
            );
            if (e is AppException) rethrow;
            throw NetworkFailure(
              'refresh backend token failed: $e',
              userMessage: 'İnternet bağlantınızı kontrol edin.',
            );
          }
          debugPrint(
            '⚠️ [BackendAuthService] Refresh token rejected, retrying with Firebase token: $e',
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
      _recordSuccess();
      return exchangedSession;
    } catch (e) {
      _recordFailure();
      rethrow;
    }
  }

  /// Throws a retryable error without hitting the network while the circuit
  /// is open. After the cooldown elapses a single trial call is let through.
  void _throwIfCircuitOpen() {
    final openedAt = _circuitOpenedAt;
    if (openedAt == null) return;

    final elapsed = DateTime.now().difference(openedAt);
    if (elapsed < _currentCooldown) {
      throw NetworkFailure(
        'auth circuit open, retry in '
        '${(_currentCooldown - elapsed).inSeconds}s',
        userMessage: 'İnternet bağlantınızı kontrol edin.',
      );
    }

    // Half-open: allow one attempt; failure re-opens with a longer cooldown.
    _circuitOpenedAt = null;
  }

  void _recordSuccess() => resetFailureState();

  /// Devre kesiciyi kapatır ve hata sayacını sıfırlar. Oturum temizlenince ve
  /// yeni girişte çağrılır: önceki hesabın (ör. silinirken) biriktirdiği
  /// hatalar yeni hesabın ilk isteklerini engellemesin.
  void resetFailureState() {
    _consecutiveFailures = 0;
    _circuitOpenedAt = null;
    _currentCooldown = _circuitInitialCooldown;
    _circuitCooldownBackoff.reset();
  }

  void _recordFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures < _circuitFailureThreshold) return;
    if (_circuitOpenedAt != null) return;

    _currentCooldown = _circuitCooldownBackoff.nextDelay();
    _circuitOpenedAt = DateTime.now();
    debugPrint(
      '⛔ [BackendAuthService] Circuit opened for '
      '${_currentCooldown.inSeconds}s after $_consecutiveFailures consecutive '
      'failures.',
    );
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
      final response = await _apiClient.post(
        _buildUri('/api/auth/logout'),
        headers: _jsonHeaders(bearerToken: session.accessToken),
        body: jsonEncode({'refreshToken': session.refreshToken}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint(
          '⚠️ [BackendAuthService] Logout request failed: ${response.statusCode}',
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

    final response = await _apiClient.post(
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
    final response = await _apiClient.post(
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
      if (ApiConfig.apiKey.isNotEmpty) 'X-SoMine-Api-Key': ApiConfig.apiKey,
      if (bearerToken != null && bearerToken.isNotEmpty)
        'Authorization': 'Bearer $bearerToken',
    };
  }

  void _throwIfNotSuccessful(http.Response response, {required String action}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    debugPrint('API Error [$action]: ${response.statusCode}');

    throw switch (response.statusCode) {
      401 => UnauthorizedException(
        '$action: unauthorized',
        userMessage: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      ),
      409 => ConflictException(
        '$action: conflict',
        userMessage: 'Bu işlem zaten yapıldı.',
      ),
      >= 400 && < 500 => ValidationException(
        '$action failed',
        userMessage: _parseApiError(response.body),
      ),
      >= 500 => ServerException(
        '$action: server error',
        userMessage: 'Sunucu hatası oluştu. Lütfen biraz sonra tekrar deneyin.',
      ),
      _ => ServerException(
        '$action failed',
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
