import 'package:flutter/foundation.dart';

class ApiConfig {
  static const String _baseUrlOverride = String.fromEnvironment(
    'SOMINE_API_BASE_URL',
    defaultValue: 'https://api.somineapp.com',
  );

  static String get baseUrl => _baseUrlOverride.trim();

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
