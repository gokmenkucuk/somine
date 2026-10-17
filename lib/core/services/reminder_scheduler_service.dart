import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/reminder_model.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/repositories/reminder_repository.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:somine_app/core/services/notification_service.dart';

class ReminderSchedulerService {
  static final ReminderSchedulerService _instance =
      ReminderSchedulerService._internal();
  factory ReminderSchedulerService() => _instance;
  ReminderSchedulerService._internal();

  final ReminderRepository _reminderRepo = ReminderRepository();
  final ItemRepository _itemRepo = ItemRepository();
  final NotificationService _notificationService = NotificationService();

  /// Bildirim Ayarları'ndaki "Hatırlatıcılar" anahtarı. Kapalıyken hatırlatıcı
  /// kayıtları saklanır ama cihazda bildirim planlanmaz.
  static const String remindersEnabledPrefKey = 'notification_reminder';

  static Future<bool> remindersEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(remindersEnabledPrefKey) ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Hatırlatıcı bildirimlerini aç/kapat: kapatınca bekleyen hatırlatıcı
  /// bildirimleri iptal edilir (haftalık özet korunur), açınca yeniden kurulur.
  Future<void> setRemindersEnabled(bool enabled, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(remindersEnabledPrefKey, enabled);
    if (enabled) {
      if (userId != null) await rescheduleUserReminders(userId);
    } else {
      await _cancelAllReminderNotifications();
    }
  }

  Future<void> _cancelAllReminderNotifications() async {
    try {
      final pending = await _notificationService.getPendingNotifications();
      for (final notification in pending) {
        final type = NotificationService.typeFromPayload(notification.payload);
        if (type == NotificationService.payloadTypeReminder) {
          await _notificationService.cancelReminder(notification.id);
        }
      }
    } catch (e) {
      debugPrint('❌ [ReminderScheduler] Error cancelling reminder notifications: $e');
    }
  }
  final CategoryRepository _categoryRepo = CategoryRepository();

  /// Kullanıcının gizli kasa (vault) kategori id'leri. Alınamazsa `null`
  /// döner — çağıran taraf bunu "bilinmiyor" sayıp fail-closed davranır.
  Future<Set<String>?> _vaultCategoryIds(String userId) async {
    try {
      final categories = await _categoryRepo.getCategories(userId);
      return categories
          .where((c) => c.isVault)
          .map((c) => c.id)
          .toSet();
    } catch (e) {
      debugPrint('⚠️ [ReminderScheduler] Vault categories unavailable: $e');
      return null;
    }
  }

  /// Kilit ekranı gizliliği: kasadaki (veya kasa durumu doğrulanamayan)
  /// içeriklerin başlığı bildirimde gösterilmez. Boş string döndüğünde
  /// NotificationService genel `notificationLocalReminderBody` metnini kullanır.
  String _lockScreenSafeTitle(
    ItemModel? item,
    String title,
    Set<String>? vaultCategoryIds,
  ) {
    if (item == null) return '';
    final categoryId = item.categoryId;
    if (categoryId == null || categoryId.isEmpty) return title;
    if (vaultCategoryIds == null) return '';
    return vaultCategoryIds.contains(categoryId) ? '' : title;
  }

  Future<String> _resolveSafeTitle(ItemModel? item, String title) async {
    if (item == null) return '';
    final categoryId = item.categoryId;
    if (categoryId == null || categoryId.isEmpty) return title;
    return _lockScreenSafeTitle(
      item,
      title,
      await _vaultCategoryIds(item.userId),
    );
  }

  Future<bool> scheduleReminder(
    ReminderModel reminder,
    String noteTitle,
  ) async {
    try {
      // Safety check for very short intervals
      if (reminder.repeat == RepeatFrequency.customMinutes &&
          reminder.customRepeatMinutes != null &&
          reminder.customRepeatMinutes! < 5) {
        debugPrint('⚠️ [ReminderScheduler] Warning: Very short interval (${reminder.customRepeatMinutes}min). This may create many notifications.');
      }

      final savedReminder = await _reminderRepo.createReminder(reminder);

      final item = await _itemRepo.getItem(reminder.itemId);
      if (item != null) {
        final updatedItem = item.copyWith(
          reminderId: savedReminder.id,
          hasReminder: true,
        );
        await _itemRepo.updateItem(updatedItem);
      }

      if (!await remindersEnabled()) {
        debugPrint('ℹ️ [ReminderScheduler] Reminders disabled in settings; saved without scheduling');
        return true;
      }

      // Hatırlatıcı kurmak bildirim izni istemenin doğal anı; karar verilmişse
      // iOS tekrar sormaz, mevcut durumu döner.
      await _notificationService.requestPermissions();
      final notificationId = await _notificationService.scheduleReminder(
        savedReminder,
        await _resolveSafeTitle(item, noteTitle),
      );

      debugPrint('✅ [ReminderScheduler] Reminder scheduled: ${savedReminder.id}');
      return notificationId != null;
    } catch (e) {
      debugPrint('❌ [ReminderScheduler] Error scheduling reminder: $e');
      return false;
    }
  }

  Future<bool> updateReminder(
    ReminderModel reminder,
    String noteTitle,
  ) async {
    try {
      await cancelReminderNotifications(reminder.itemId);

      await _reminderRepo.updateReminder(reminder);
      if (!await remindersEnabled()) return true;
      await _notificationService.requestPermissions();

      final item = await _itemRepo.getItem(reminder.itemId);
      final notificationId = await _notificationService.scheduleReminder(
        reminder,
        await _resolveSafeTitle(item, noteTitle),
      );

      debugPrint('✅ [ReminderScheduler] Reminder updated: ${reminder.id}');
      return notificationId != null;
    } catch (e) {
      debugPrint('❌ [ReminderScheduler] Error updating reminder: $e');
      return false;
    }
  }

  Future<void> cancelReminder(String itemId) async {
    try {
      await cancelReminderNotifications(itemId);

      await _reminderRepo.deleteItemReminders(itemId);

      final item = await _itemRepo.getItem(itemId);
      if (item != null) {
        final updatedItem = item.copyWith(
          reminderId: null,
          hasReminder: false,
        );
        await _itemRepo.updateItem(updatedItem);
      }

      debugPrint('✅ [ReminderScheduler] Reminder cancelled for item: $itemId');
    } catch (e) {
      debugPrint('❌ [ReminderScheduler] Error cancelling reminder: $e');
    }
  }

  Future<void> cancelReminderNotifications(String itemId) async {
    final pending = await _notificationService.getPendingNotifications();

    for (final notification in pending) {
      // Payload JSON ({"type":...,"itemId":...}) veya eski düz-string itemId
      // olabilir. Yalnız reminder tipli bildirimler iptal edilir — aynı
      // item'a bağlı weekly_digest bildirimi korunur.
      final payloadType = NotificationService.typeFromPayload(
        notification.payload,
      );
      final payloadItemId = NotificationService.itemIdFromPayload(
        notification.payload,
      );
      if (payloadType == NotificationService.payloadTypeReminder &&
          payloadItemId == itemId) {
        await _notificationService.cancelReminder(notification.id);
      }
    }
  }

  Future<void> rescheduleUserReminders(String userId) async {
    try {
      if (!await remindersEnabled()) {
        await _cancelAllReminderNotifications();
        return;
      }

      final reminders = await _reminderRepo.getUserReminders(userId);
      final vaultIds = await _vaultCategoryIds(userId);

      for (final reminder in reminders) {
        final item = await _itemRepo.getItem(reminder.itemId);
        // Skip if item is deleted or doesn't exist
        if (item != null && !item.isDeleted && reminder.isActive) {
          await _notificationService.scheduleReminder(
            reminder,
            _lockScreenSafeTitle(item, item.displayTitle, vaultIds),
          );
        } else if (item?.isDeleted == true) {
          // Clean up reminder if item is deleted
          await _reminderRepo.deleteItemReminders(reminder.itemId);
        }
      }

      debugPrint('✅ [ReminderScheduler] Rescheduled ${reminders.length} reminders');
    } catch (e) {
      debugPrint('❌ [ReminderScheduler] Error rescheduling reminders: $e');
    }
  }

  Future<void> processRepeatingReminders(String userId) async {
    try {
      if (!await remindersEnabled()) return;

      final reminders = await _reminderRepo.getUserReminders(userId);
      final now = DateTime.now();
      final vaultIds = await _vaultCategoryIds(userId);

      for (final reminder in reminders) {
        if (!reminder.isActive || reminder.repeat == RepeatFrequency.none) {
          continue;
        }

        final nextOccurrence = reminder.calculateNextOccurrence();

        // Fix: Remove the 5-minute window limit to properly handle catch-up
        // for reminders that were missed while app was offline
        if (nextOccurrence.isAfter(now)) {
          final item = await _itemRepo.getItem(reminder.itemId);
          if (item != null) {
            await _notificationService.scheduleReminder(
              reminder,
              _lockScreenSafeTitle(item, item.displayTitle, vaultIds),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [ReminderScheduler] Error processing repeating reminders: $e');
    }
  }
}
