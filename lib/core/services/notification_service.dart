import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:somine_app/core/models/reminder_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/services/vault_service.dart';
import 'package:somine_app/widgets/item_detail_bottom_sheet.dart';
import 'package:somine_app/core/repositories/item_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const String payloadTypeReminder = 'reminder';
  static const String payloadTypeWeeklyDigest = 'weekly_digest';

  /// JSON payload üretir: `{"type":"reminder|weekly_digest","itemId":...}`.
  static String encodePayload({required String type, required String itemId}) {
    return jsonEncode({'type': type, 'itemId': itemId});
  }

  /// Payload'dan itemId çıkarır. GERİYE DÖNÜK uyumluluk: eski schedule
  /// edilmiş bildirimlerde payload düz itemId string'idir — o da desteklenir.
  static String? itemIdFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded['itemId'] as String?;
      }
    } catch (_) {
      // JSON değil → eski düz-string payload.
    }
    return payload;
  }

  /// Payload tipini çıkarır; eski düz-string payload'lar reminder sayılır.
  static String typeFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return payloadTypeReminder;
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        return decoded['type'] as String? ?? payloadTypeReminder;
      }
    } catch (_) {
      // JSON değil → eski düz-string payload.
    }
    return payloadTypeReminder;
  }

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
    debugPrint('✅ [NotificationService] Navigator key set');
  }

  void setCurrentUser(String userId) {
    _currentUserId = userId;
    debugPrint('✅ [NotificationService] Current user set: $userId');
  }

  String? _currentUserId;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    tz_data.initializeTimeZones();

    _initialized = true;
    debugPrint('✅ [NotificationService] Initialized');
  }

  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final granted = await androidPlugin?.requestNotificationsPermission();
      return granted ?? false;
    } else if (Platform.isIOS) {
      final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();

      final granted = await iosPlugin?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return false;
  }

  Future<int?> scheduleReminder(ReminderModel reminder, String noteTitle) async {
    if (!reminder.isActive) return null;

    try {
      final scheduledTime = reminder.calculateNextOccurrence();

      const androidDetails = AndroidNotificationDetails(
        'note_reminders',
        'Note Reminders',
        channelDescription: 'Notifications for note reminders',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final notificationId = DateTime.now().millisecondsSinceEpoch % 100000;

      await _notifications.zonedSchedule(
        notificationId,
        'Hatırlatıcı 🔔',
        noteTitle.isNotEmpty ? noteTitle : 'Not hatırlatıcınız var',
        tz.TZDateTime.from(scheduledTime, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: _getDateTimeComponents(reminder.repeat),
        payload: encodePayload(
          type: payloadTypeReminder,
          itemId: reminder.itemId,
        ),
      );

      debugPrint('✅ [NotificationService] Scheduled reminder: $notificationId for $scheduledTime');
      return notificationId;
    } catch (e) {
      debugPrint('❌ [NotificationService] Error scheduling reminder: $e');
      return null;
    }
  }

  /// Haftalık "Sana geri geldi" bildirimini sabit id ile schedule eder.
  /// İdempotent: önce cancel, sonra schedule (tek seferlik, tekrar yok).
  Future<void> scheduleWeeklyDigest({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledAt,
    required String itemId,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'weekly_digest',
        'Weekly Digest',
        channelDescription: 'Weekly resurfacing digest notification',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
        styleInformation: BigTextStyleInformation(''),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.cancel(notificationId);
      await _notifications.zonedSchedule(
        notificationId,
        title,
        body,
        tz.TZDateTime.from(scheduledAt, tz.local),
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: encodePayload(
          type: payloadTypeWeeklyDigest,
          itemId: itemId,
        ),
      );

      debugPrint(
        '✅ [NotificationService] Weekly digest scheduled for $scheduledAt',
      );
    } catch (e) {
      debugPrint('❌ [NotificationService] Error scheduling weekly digest: $e');
    }
  }

  Future<void> cancelReminder(int notificationId) async {
    await _notifications.cancel(notificationId);
    debugPrint('🗑️ [NotificationService] Cancelled notification: $notificationId');
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('🗑️ [NotificationService] Cancelled all notifications');
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  DateTimeComponents? _getDateTimeComponents(RepeatFrequency repeat) {
    switch (repeat) {
      case RepeatFrequency.daily:
        return DateTimeComponents.time;
      case RepeatFrequency.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case RepeatFrequency.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case RepeatFrequency.yearly:
        return DateTimeComponents.dateAndTime;
      default:
        return null;
    }
  }

  void _onNotificationTap(NotificationResponse response) async {
    debugPrint('📱 [NotificationService] Notification tapped: ${response.payload}');

    // JSON payload ({"type":...,"itemId":...}) veya eski düz-string itemId.
    // Hem reminder hem weekly_digest tap'i ilgili item'ın detayına gider.
    final itemId = itemIdFromPayload(response.payload);
    if (itemId != null) {
      await openItemDetail(itemId);
    }
  }

  /// Güvenli item id kalıbı (backend GUID / URL-safe token). Path traversal,
  /// boşluk ve reserved karakterleri dışlar; uzunluk sınırlıdır.
  static final RegExp _itemIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  /// Deeplink/bildirim/widget'tan gelen itemId biçimsel olarak güvenli mi?
  static bool isValidItemId(String? itemId) {
    if (itemId == null) return false;
    return _itemIdPattern.hasMatch(itemId);
  }

  /// itemId ile item detay bottom-sheet'ini açar.
  /// Ortak kalıp: bildirim tap'i + ana ekran widget tap'i (main.dart) +
  /// `somine://item/<id>` deeplink. TÜM giriş noktaları buradan geçer, bu
  /// yüzden vault kilidi ve itemId doğrulaması TEK noktada burada uygulanır.
  Future<void> openItemDetail(String itemId) async {
    // (4) Untrusted itemId format doğrulaması — geçersizse sessizce yoksay.
    if (!isValidItemId(itemId)) {
      debugPrint('⚠️ [NotificationService] Ignoring malformed itemId');
      return;
    }

    final navState = _navigatorKey?.currentState;
    if (navState != null && navState.mounted) {
      try {
        // Item'ı fetch et
        final itemRepo = ItemRepository();
        final item = await itemRepo.getItem(itemId);

        if (item != null && navState.mounted && _navigatorKey?.currentContext != null) {
          final userId =
              _currentUserId ?? FirebaseAuth.instance.currentUser?.uid;

          List<CategoryModel> categories = [];
          String categoryName = 'Kategori';
          CategoryModel? itemCategory;

          // Item'ın vault'ta olup olmadığını KESİN olarak belirleyebildik mi?
          // Belirleyemezsek (ağ hatası, eksik kategori) kilit istemek şart —
          // aksi halde kategori isteğini düşüren biri vault kilidini atlar.
          bool vaultStatusResolved = false;

          if (item.categoryId == null || item.categoryId!.isEmpty) {
            // Kategorisiz item vault'ta olamaz.
            vaultStatusResolved = true;
          } else if (userId != null) {
            try {
              final categoryRepo = CategoryRepository();
              categories = await categoryRepo.getCategories(userId);
              final match =
                  categories.where((c) => c.id == item.categoryId).toList();
              if (match.isNotEmpty) {
                itemCategory = match.first;
                categoryName = itemCategory.name;
                vaultStatusResolved = true;
              }
              // match boşsa: item bilinmeyen bir kategoriye işaret ediyor →
              // vault olabilir, resolved BIRAKMA (fail-closed).
            } catch (e) {
              debugPrint('⚠️ [NotificationService] Could not fetch categories: $e');
            }
          }

          // (1) Vault bypass guard: item vault kategorisindeyse VEYA vault
          // durumu doğrulanamadıysa, detay sheet'i açılmadan önce mevcut
          // vault unlock akışından (FaceID/TouchID) geçmeli. Zaten açıksa
          // doğrudan devam eder.
          final requiresVaultUnlock =
              !vaultStatusResolved || itemCategory?.isVault == true;
          if (requiresVaultUnlock) {
            final unlocked = await _ensureVaultUnlocked();
            if (!unlocked) {
              debugPrint('🔒 [NotificationService] Vault locked/unverified — item detail blocked');
              return;
            }
          }

          // Re-check navigator is still valid after async category fetch
          if (!navState.mounted || _navigatorKey?.currentContext == null) return;
          final freshContext = _navigatorKey!.currentContext!;

          ItemDetailBottomSheet.show(
            freshContext, // ignore: use_build_context_synchronously
            item,
            categoryName,
            categories,
          );
          debugPrint('✅ [NotificationService] Navigated to item: $itemId via BottomSheet');
        } else {
          debugPrint('⚠️ [NotificationService] Item not found or navigator unmounted: $itemId');
        }
      } catch (e) {
        debugPrint('❌ [NotificationService] Error navigating to item: $e');
      }
    }
  }

  /// Vault kilidinin açık olmasını sağlar. Zaten açıksa hemen true döner;
  /// değilse uygulamanın canonical vault akışını (VaultService.authenticate)
  /// yeniden kullanır ve başarılıysa app-genelindeki [isVaultUnlockedProvider]
  /// durumunu — catalog/feed ekranlarıyla aynı şekilde — günceller.
  Future<bool> _ensureVaultUnlocked() async {
    final context = _navigatorKey?.currentContext;
    if (context == null) return false;

    ProviderContainer container;
    try {
      container = ProviderScope.containerOf(context, listen: false);
    } catch (e) {
      // ProviderScope bulunamazsa güvenli taraf: sheet'i açma.
      debugPrint('🔒 [NotificationService] Vault state unavailable: $e');
      return false;
    }

    if (container.read(isVaultUnlockedProvider)) return true;

    final result = await VaultService().authenticate();
    if (result == VaultAuthResult.success) {
      container.read(isVaultUnlockedProvider.notifier).state = true;
      return true;
    }
    return false;
  }

  Future<void> showTestNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'Test Notifications',
      channelDescription: 'Channel for test notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      0,
      'Test Bildirimi',
      'Bu bir test hatırlatıcısı!',
      notificationDetails,
    );
  }
}
