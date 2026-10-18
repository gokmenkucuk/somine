import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/data/onboarding_demo_content.dart';
import 'package:somine_app/core/services/api_client.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';

/// Kayıtta eklenecek örnek içeriği API'den alır (GET /api/onboarding/demo-content);
/// böylece liste uygulama sürümü yayınlamadan güncellenebilir. Sunucuya
/// ulaşılamazsa, cevap geç gelirse ya da liste boşsa uygulamadaki sabit listeye
/// ([onboardingDemoItems]) düşer: yeni kullanıcı hiçbir zaman boş kalmaz.
class OnboardingRepository {
  static const _timeout = Duration(seconds: 4);

  final BackendAuthService _backendAuthService = BackendAuthService();
  final ApiClient _apiClient = ApiClient();

  Future<List<OnboardingDemoItem>> loadDemoItems() async {
    try {
      final accessToken = await _backendAuthService
          .getValidAccessToken(firebaseUser: FirebaseAuth.instance.currentUser)
          .timeout(_timeout);
      if (accessToken == null || accessToken.isEmpty) {
        return onboardingDemoItems;
      }

      final base = ApiConfig.baseUrl.endsWith('/')
          ? ApiConfig.baseUrl.substring(0, ApiConfig.baseUrl.length - 1)
          : ApiConfig.baseUrl;
      final response = await _apiClient
          .get(
            Uri.parse('$base/api/onboarding/demo-content'),
            headers: {
              'Accept': 'application/json',
              if (ApiConfig.apiKey.isNotEmpty)
                'X-SoMine-Api-Key': ApiConfig.apiKey,
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return onboardingDemoItems;
      }

      final items = parseDemoItems(response.body);
      return items.isEmpty ? onboardingDemoItems : items;
    } catch (e) {
      debugPrint('⚠️ [Onboarding] Demo content from API unavailable, using bundled list: $e');
      return onboardingDemoItems;
    }
  }

  /// Yalnızca bilinen koleksiyon anahtarları ve http(s) bağlantıları kabul edilir.
  @visibleForTesting
  static List<OnboardingDemoItem> parseDemoItems(String body) {
    final json = jsonDecode(body);
    if (json is! Map<String, dynamic>) return const [];
    final raw = json['items'];
    if (raw is! List) return const [];

    const known = {
      DemoCollection.music,
      DemoCollection.places,
      DemoCollection.restaurants,
      DemoCollection.recipes,
      DemoCollection.inspiration,
    };
    final items = <OnboardingDemoItem>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final collection = entry['collection'];
      final url = entry['url'];
      if (collection is! String || !known.contains(collection)) continue;
      if (url is! String) continue;
      final uri = Uri.tryParse(url);
      if (uri == null || !(uri.isScheme('https') || uri.isScheme('http'))) {
        continue;
      }
      items.add(OnboardingDemoItem(collection: collection, url: url));
    }
    return items;
  }
}
