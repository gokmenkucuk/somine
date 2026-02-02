import 'package:flutter/foundation.dart';
import 'package:somine_app/core/models/reminder_model.dart';
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

      final notificationId = await _notificationService.scheduleReminder(
        savedReminder,
        noteTitle,
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

      final notificationId = await _notificationService.scheduleReminder(
        reminder,
        noteTitle,
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
      if (notification.payload == itemId) {
        await _notificationService.cancelReminder(notification.id);
      }
    }
  }

  Future<void> rescheduleUserReminders(String userId) async {
    try {
      final reminders = await _reminderRepo.getUserReminders(userId);

      for (final reminder in reminders) {
        final item = await _itemRepo.getItem(reminder.itemId);
        // Skip if item is deleted or doesn't exist
        if (item != null && !item.isDeleted && reminder.isActive) {
          await _notificationService.scheduleReminder(
            reminder,
            item.displayTitle,
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
      final reminders = await _reminderRepo.getUserReminders(userId);
      final now = DateTime.now();

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
              item.displayTitle,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [ReminderScheduler] Error processing repeating reminders: $e');
    }
  }
}
