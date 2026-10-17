import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:somine_app/core/services/notification_service.dart';
import 'package:somine_app/core/utils/resurfacing_dates.dart';

/// Haftalık "Sana geri geldi" lokal bildirimi (Resurfacing v1).
///
/// App açılışında çağrılır; `notification_weekly` toggle'ına
/// (notification_settings_screen) bağlıdır; varsayılan KAPALI (opt-in).
/// Açıksa hiç açılmamış (`lastOpenedAt == null`) ve gizli kasada olmayan
/// kayıtları sayıp sıradaki Pazar 19:00'a sabit id ile idempotent schedule
/// eder; kapalıysa bildirimi iptal eder. Metin yalnızca bilgi verir (sayı),
/// içerik başlığı göstermez.
class WeeklyDigestService {
  static final WeeklyDigestService _instance = WeeklyDigestService._internal();
  factory WeeklyDigestService() => _instance;
  WeeklyDigestService._internal();

  /// Sabit notification id (plan: 900001).
  static const int digestNotificationId = 900001;

  /// notification_settings_screen.dart'taki mevcut anahtar.
  static const String _weeklyToggleKey = 'notification_weekly';

  static const int _digestHour = 19;

  final ItemRepository _itemRepository = ItemRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final NotificationService _notificationService = NotificationService();

  /// App açılışında çağrılır (main.dart, rescheduleUserReminders yanı).
  /// Hata asla dışarı sızmaz — açılış akışını bozamaz.
  Future<void> syncOnAppStart(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Varsayılan KAPALI: pazarlama-benzeri hatırlatma kullanıcı açıkça
      // istemedikçe gönderilmez.
      // (notification_settings_screen.dart'taki varsayılanla aynı olmalı.)
      final enabled = prefs.getBool(_weeklyToggleKey) ?? false;

      if (!enabled) {
        await _notificationService.cancelReminder(digestNotificationId);
        debugPrint('ℹ️ [WeeklyDigest] Toggle off — digest cancelled');
        return;
      }

      final items = await _itemRepository.getItems(userId);

      // Gizli kasa içerikleri asla aday olmaz. Kategoriler alınamazsa
      // fail-closed: yalnızca kategorisiz içerikler aday kalır.
      Set<String>? vaultIds;
      try {
        final categories = await _categoryRepository.getCategories(userId);
        vaultIds =
            categories.where((c) => c.isVault).map((c) => c.id).toSet();
      } catch (e) {
        debugPrint('⚠️ [WeeklyDigest] Categories unavailable: $e');
      }
      bool isHidden(String? categoryId) {
        if (categoryId == null || categoryId.isEmpty) return false;
        return vaultIds == null || vaultIds.contains(categoryId);
      }

      final candidates =
          items
              .where(
                (item) =>
                    !item.isDeleted &&
                    item.lastOpenedAt == null &&
                    !isHidden(item.categoryId),
              )
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (candidates.isEmpty) {
        await _notificationService.cancelReminder(digestNotificationId);
        debugPrint('ℹ️ [WeeklyDigest] No candidates — digest cancelled');
        return;
      }

      final first = candidates.first;
      final l10n = _resolveLocalizations();
      final body = l10n.weeklyDigestNotificationBody(candidates.length);

      final scheduledAt = ResurfacingDates.nextSundayAt(
        DateTime.now(),
        hour: _digestHour,
      );

      await _notificationService.scheduleWeeklyDigest(
        notificationId: digestNotificationId,
        title: l10n.weeklyDigestNotificationTitle,
        body: body,
        scheduledAt: scheduledAt,
        itemId: first.id,
      );
    } catch (e) {
      debugPrint('❌ [WeeklyDigest] syncOnAppStart error (ignored): $e');
    }
  }

  /// Bildirim metinleri için context'siz l10n çözümü: cihaz diline göre
  /// desteklenen locale'e düşer; bulunamazsa şablon dil (tr) kullanılır.
  AppLocalizations _resolveLocalizations() {
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    try {
      return lookupAppLocalizations(Locale(deviceLocale.languageCode));
    } catch (_) {
      return lookupAppLocalizations(const Locale('tr'));
    }
  }
}
