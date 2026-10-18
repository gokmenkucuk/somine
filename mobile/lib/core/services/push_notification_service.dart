import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/services/api_client.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';
import 'package:somine_app/core/utils/app_l10n.dart';

/// Uzak bildirim (FCM → APNs) cihaz kaydı.
///
/// - Oturum açıkken cihazın FCM token'ını API'ye bildirir
///   (`PUT /api/users/me/device-token`) ve token yenilendikçe tekrarlar.
/// - Oturum kapatma / hesap silme öncesinde token'ı siler
///   (`DELETE /api/users/me/device-token`), çıkış yapılmış cihaza push gitmez.
///
/// Bildirim izni burada İSTENMEZ: iOS'ta izin uygulama genelinde tektir ve
/// mevcut bağlamsal akış (NotificationService.requestPermissions — onboarding,
/// bildirim ayarları, hatırlatıcı) aynı izni verir. İzin yoksa token yine
/// alınır, yalnızca bildirim gösterilmez.
///
/// Ön planda sistem bildirimi gösterilmez (firebase_messaging'in iOS
/// varsayılanı); uygulama açıkken SignalR uygulama içi banner'ı gösterir.
class PushNotificationService {
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final ApiClient _apiClient = ApiClient();
  final BackendAuthService _backendAuthService = BackendAuthService();

  StreamSubscription<String>? _tokenRefreshSubscription;
  Future<void>? _inFlightRegistration;

  /// API'ye en son başarıyla bildirilen token (çıkışta silmek için).
  String? _registeredToken;

  FirebaseMessaging get _messaging => FirebaseMessaging.instance;

  /// Oturum açık kullanıcı için token'ı kaydeder. Hatalar yutulur; push
  /// kaydı hiçbir akışı bloklamamalı.
  Future<void> registerForCurrentUser() {
    return _inFlightRegistration ??= _registerInternal().whenComplete(() {
      _inFlightRegistration = null;
    });
  }

  Future<void> _registerInternal() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) return;

      _tokenRefreshSubscription ??= _messaging.onTokenRefresh.listen(
        (token) => unawaited(_sendToken(token)),
        onError: (Object e) =>
            debugPrint('⚠️ [PushNotificationService] Token refresh error: $e'),
      );

      final token = await _getToken();
      if (token == null || token.isEmpty) {
        debugPrint('⚠️ [PushNotificationService] FCM token unavailable');
        return;
      }

      await _sendToken(token);
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Registration failed: $e');
    }
  }

  /// Oturum kapatmadan / hesap silmeden ÖNCE çağrılmalı (backend oturumu
  /// hâlâ geçerliyken). Hatalar yutulur; çıkışı asla engellemez.
  Future<void> unregisterCurrentDevice() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;

    try {
      final token =
          _registeredToken ??
          await _messaging.getToken().timeout(const Duration(seconds: 5));
      if (token == null || token.isEmpty) return;

      final accessToken = await _backendAuthService.getValidAccessToken(
        firebaseUser: FirebaseAuth.instance.currentUser,
      );
      if (accessToken == null || accessToken.isEmpty) return;

      final response = await _apiClient.delete(
        _buildUri('/api/users/me/device-token'),
        headers: _jsonHeaders(accessToken),
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ [PushNotificationService] Device token unregistered');
      } else {
        debugPrint(
          '⚠️ [PushNotificationService] Unregister failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Unregister error: $e');
    } finally {
      _registeredToken = null;
    }
  }

  Future<String?> _getToken() async {
    if (Platform.isIOS) {
      // iOS'ta APNs token'ı gelmeden FCM token'ı alınamaz; açılışta birkaç
      // saniye gecikebilir. Gelmezse (simülatör, push yetkisi olmayan
      // provisioning) sessizce vazgeç; onTokenRefresh sonra yakalar.
      var apnsToken = await _messaging.getAPNSToken();
      for (var attempt = 0; apnsToken == null && attempt < 10; attempt++) {
        await Future<void>.delayed(const Duration(seconds: 1));
        apnsToken = await _messaging.getAPNSToken();
      }
      if (apnsToken == null) return null;
    }

    return _messaging.getToken();
  }

  Future<void> _sendToken(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final accessToken = await _backendAuthService.getValidAccessToken(
        firebaseUser: user,
      );
      if (accessToken == null || accessToken.isEmpty) return;

      final response = await _apiClient.put(
        _buildUri('/api/users/me/device-token'),
        headers: _jsonHeaders(accessToken),
        body: jsonEncode({
          'token': token,
          'platform': Platform.isIOS ? 'ios' : 'android',
          // Sunucu push metnini bu dile göre kurar (tr / en).
          'locale': appL10n.localeName,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _registeredToken = token;
        debugPrint('✅ [PushNotificationService] Device token registered');
      } else {
        debugPrint(
          '⚠️ [PushNotificationService] Register failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Register error: $e');
    }
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
}
