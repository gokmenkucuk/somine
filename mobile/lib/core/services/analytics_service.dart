import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tipli Firebase Analytics sarmalayıcısı.
///
/// Serbest string event gönderilmez; yalnızca buradaki metotlar kullanılır.
/// Tüm çağrılar fire-and-forget'tir — analitik hatası uygulama akışını
/// asla bozmaz (try/catch ile yutulur, yalnızca debugPrint edilir).
class AnalyticsService {
  AnalyticsService._();

  /// Riverpod erişimi olmayan yerler (statik `show()` metotları vb.) için
  /// singleton erişim noktası.
  static final AnalyticsService instance = AnalyticsService._();

  static const String _activationFlagKey = 'analytics_activation_logged';

  FirebaseAnalytics get _analytics => FirebaseAnalytics.instance;

  /// Başarılı oturum açma (method: google/apple).
  void logLogin(String method) {
    _run(() => _analytics.logLogin(loginMethod: method));
  }

  /// Başarılı yeni kayıt (method: google/apple).
  void logSignUp(String method) {
    _run(() => _analytics.logSignUp(signUpMethod: method));
  }

  /// Kullanıcının İLK içerik kaydında bir kez gönderilir.
  /// Tekrar bastırma SharedPreferences bayrağı ile servis içinde yapılır.
  void logActivation() {
    _run(() async {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_activationFlagKey) ?? false) return;
      await _analytics.logEvent(name: 'activation');
      await prefs.setBool(_activationFlagKey, true);
    });
  }

  /// İçerik kaydı (type: link/note/image; source: app/share_ext).
  void logContentAdd({required String type, required String source}) {
    _run(
      () => _analytics.logEvent(
        name: 'content_add',
        parameters: {'type': type, 'source': source},
      ),
    );
  }

  /// Hatırlatıcı kuruldu (source: picker vb.; frequency: none/daily/...).
  void logReminderSet({required String source, required String frequency}) {
    _run(
      () => _analytics.logEvent(
        name: 'reminder_set',
        parameters: {'source': source, 'frequency': frequency},
      ),
    );
  }

  /// Paywall görüntülendi (source: paywall'ı açan yüzey).
  void logPaywallView(String source) {
    _run(
      () => _analytics.logEvent(
        name: 'paywall_view',
        parameters: {'source': source},
      ),
    );
  }

  /// Paywall'dan satın alma tamamlandı.
  void logPaywallConvert(String productId) {
    _run(
      () => _analytics.logEvent(
        name: 'paywall_convert',
        parameters: {'product_id': productId},
      ),
    );
  }

  /// İçerik paylaşıldı (standart `share` eventi).
  void logShareAction(String contentType) {
    _run(
      () => _analytics.logShare(
        contentType: contentType,
        itemId: 'n/a',
        method: 'share_plus',
      ),
    );
  }

  /// Ana ekran widget'ına tıklandı (custom `widget_tap` eventi).
  void logWidgetTap() {
    _run(() => _analytics.logEvent(name: 'widget_tap'));
  }

  /// Veri dışa aktarma tamamlandı (format: json/csv).
  void logExport(String format) {
    _run(
      () =>
          _analytics.logEvent(name: 'export', parameters: {'format': format}),
    );
  }

  /// Manuel ekran görüntüleme (observer'ın göremediği bottom-sheet'ler için).
  void logScreenView(String screenName) {
    _run(() => _analytics.logScreenView(screenName: screenName));
  }

  void _run(Future<void> Function() body) {
    try {
      body().catchError((Object e) {
        debugPrint('AnalyticsService error: $e');
      });
    } catch (e) {
      debugPrint('AnalyticsService error: $e');
    }
  }
}

/// AnalyticsService provider (projedeki Provider kalıbıyla).
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});
