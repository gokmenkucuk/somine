import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:somine_app/core/models/reminder_model.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/widgets/item_detail_bottom_sheet.dart';
import 'package:somine_app/core/repositories/item_repository.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

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
        payload: reminder.itemId, // Item ID'si payload olarak eklendi
      );

      debugPrint('✅ [NotificationService] Scheduled reminder: $notificationId for $scheduledTime');
      return notificationId;
    } catch (e) {
      debugPrint('❌ [NotificationService] Error scheduling reminder: $e');
      return null;
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

    final itemId = response.payload;
    final navState = _navigatorKey?.currentState;
    if (itemId != null && navState != null && navState.mounted) {
      try {
        // Item'ı fetch et
        final itemRepo = ItemRepository();
        final item = await itemRepo.getItem(itemId);

        if (item != null && navState.mounted && _navigatorKey?.currentContext != null) {
          final context = _navigatorKey!.currentContext!;

          List<CategoryModel> categories = [];
          String categoryName = 'Kategori';

          if (_currentUserId != null) {
            try {
              final categoryRepo = CategoryRepository();
              categories = await categoryRepo.getCategories(_currentUserId!);
              final match = categories.where((c) => c.id == item.categoryId).toList();
              if (match.isNotEmpty) {
                categoryName = match.first.name;
              }
            } catch (e) {
              debugPrint('⚠️ [NotificationService] Could not fetch categories: $e');
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
