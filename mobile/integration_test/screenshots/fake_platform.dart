// Ekran görüntüsü düzeneği için sahte platform katmanı.
//
// Gerçek Firebase'e, Keychain'e veya bildirim iznine dokunmadan uygulama
// ekranlarını "oturum açık" durumda çizebilmek için:
//  - Firebase Core: Pigeon mesajları test API'siyle karşılanır (yerel
//    FirebaseApp hiç yapılandırılmaz, analitik/crash verisi gönderilmez).
//  - Firebase Auth: platform arayüzü sahte bir oturum açık kullanıcı döndürür.
//  - Secure storage: geçerli, sahte bir backend oturumu döndürür.
//  - Bildirim / analitik / crashlytics kanalları: sessizce "tamam" der.
import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:somine_app/core/models/backend_auth_session.dart';

const fixtureUid = 'fixture-user-ayse';

class _FakeUserPlatform extends UserPlatform {
  _FakeUserPlatform(FirebaseAuthPlatform auth, PigeonUserDetails details)
    : super(auth, _FakeMultiFactor(auth), details);
}

class _FakeMultiFactor extends MultiFactorPlatform {
  _FakeMultiFactor(super.auth);
}

class FakeFirebaseAuthPlatform extends FirebaseAuthPlatform {
  FakeFirebaseAuthPlatform({required this.displayName, super.appInstance});

  final String displayName;
  UserPlatform? _user;

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    PigeonUserDetails? currentUser,
    String? languageCode,
  }) => this;

  @override
  UserPlatform? get currentUser {
    return _user ??= _FakeUserPlatform(
      this,
      PigeonUserDetails(
        userInfo: PigeonUserInfo(
          uid: fixtureUid,
          email: 'ayse@example.com',
          displayName: displayName,
          isAnonymous: false,
          isEmailVerified: true,
          providerId: 'apple.com',
        ),
        providerData: const [],
      ),
    );
  }

  @override
  set currentUser(UserPlatform? userPlatform) => _user = userPlatform;

  @override
  Stream<UserPlatform?> authStateChanges() => Stream.value(currentUser);

  @override
  Stream<UserPlatform?> idTokenChanges() => Stream.value(currentUser);

  @override
  Stream<UserPlatform?> userChanges() => Stream.value(currentUser);

  @override
  Future<void> setLanguageCode(String? languageCode) async {}
}

/// Tüm sahte platform kancalarını kurar. `Firebase.initializeApp()` çağrısından
/// ÖNCE çalıştırılmalı.
Future<void> installFakePlatform() async {
  setupFirebaseCoreMocks();
  FirebaseAuthPlatform.instance = FakeFirebaseAuthPlatform(displayName: 'Ayşe');
  await Firebase.initializeApp();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  final session = BackendAuthSession(
    accessToken: 'fixture-access-token',
    refreshToken: 'fixture-refresh-token',
    tokenType: 'Bearer',
    expiresInSeconds: 60 * 60 * 24 * 30,
    issuedAt: DateTime.now().toUtc(),
    user: const BackendAuthUser(
      id: fixtureUid,
      email: 'ayse@example.com',
      displayName: 'Ayşe',
      username: 'ayse',
    ),
  ).encode();

  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (call) async {
      switch (call.method) {
        case 'read':
          final key = (call.arguments as Map)['key'] as String? ?? '';
          return key.startsWith('backend_auth_session') ? session : null;
        case 'readAll':
          return <String, String>{};
        case 'containsKey':
          return false;
        default:
          return null;
      }
    },
  );

  // Bildirim izni: sistem diyaloğu açılmadan "verildi".
  messenger.setMockMethodCallHandler(
    const MethodChannel('dexterous.com/flutter/local_notifications'),
    (call) async {
      switch (call.method) {
        case 'requestPermissions':
        case 'initialize':
          return true;
        case 'checkPermissions':
          return {
            'isEnabled': true,
            'isAlertEnabled': true,
            'isBadgeEnabled': true,
            'isSoundEnabled': true,
          };
        case 'pendingNotificationRequests':
        case 'getActiveNotifications':
          return <Object?>[];
        default:
          return null;
      }
    },
  );

  for (final name in const [
    'plugins.flutter.io/firebase_analytics',
    'plugins.flutter.io/firebase_crashlytics',
    'plugins.flutter.io/firebase_messaging',
    'home_widget',
  ]) {
    messenger.setMockMethodCallHandler(
      MethodChannel(name),
      (call) async => null,
    );
  }
}
