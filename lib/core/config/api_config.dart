import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _baseUrlOverride = String.fromEnvironment(
    'SOMINE_API_BASE_URL',
    defaultValue: 'https://api.somineapp.com',
  );
  static const String _publicWebBaseUrlOverride = String.fromEnvironment(
    'SOMINE_PUBLIC_WEB_BASE_URL',
    defaultValue: 'https://somineapp.com',
  );

  // Key koda gömülmez; build'e --dart-define=SOMINE_API_KEY=... ile verilir
  // (bkz. PLAN.md Ek A). Boş bırakılırsa X-SoMine-Api-Key header'ı gönderilmez.
  static const String apiKey = String.fromEnvironment('SOMINE_API_KEY');

  static String get baseUrl => _baseUrlOverride.trim();

  static String get publicWebBaseUrl => _publicWebBaseUrlOverride.trim();

  static bool get isBackendAuthEnabled => baseUrl.isNotEmpty;

  static String get authClientId {
    if (kIsWeb) return 'somine-web';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'somine-mobile-android';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return 'somine-mobile-ios';
    }
    return 'somine-web';
  }
}
