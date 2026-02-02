import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:somine_app/core/models/reminder_model.dart';

class ReminderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _remindersCollection =>
      _firestore.collection('reminders');

  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    try {
      debugPrint('🔔 [ReminderRepository] Creating reminder...');
      final docRef = await _remindersCollection.add(reminder.toFirestore());
      debugPrint('✅ [ReminderRepository] Reminder created: ${docRef.id}');

      final doc = await docRef.get();
      return ReminderModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error creating reminder: $e');
      rethrow;
    }
  }

  Future<ReminderModel?> getReminder(String reminderId) async {
    try {
      final doc = await _remindersCollection.doc(reminderId).get();
      if (doc.exists) {
        return ReminderModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error getting reminder: $e');
      rethrow;
    }
  }

  Future<List<ReminderModel>> getUserReminders(String userId) async {
    try {
      final itemsSnapshot = await _firestore
          .collection('items')
          .where('userId', isEqualTo: userId)
          .where('hasReminder', isEqualTo: true)
          .get();

      if (itemsSnapshot.docs.isEmpty) return [];

      final itemIds = itemsSnapshot.docs.map((d) => d.id).toList();
      final remindersSnapshot = await _remindersCollection
          .where('itemId', whereIn: itemIds)
          .where('isActive', isEqualTo: true)
          .get();

      return remindersSnapshot.docs
          .map((doc) => ReminderModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error getting user reminders: $e');
      rethrow;
    }
  }

  Future<ReminderModel?> getItemReminder(String itemId) async {
    try {
      final snapshot = await _remindersCollection
          .where('itemId', isEqualTo: itemId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return ReminderModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error getting item reminder: $e');
      rethrow;
    }
  }

  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      await _remindersCollection.doc(reminder.id).update({
        'reminderDate': Timestamp.fromDate(reminder.reminderDate),
        'reminderTime': {
          'hour': reminder.reminderTime.hour,
          'minute': reminder.reminderTime.minute,
        },
        'repeat': reminder.repeat.name,
        'isActive': reminder.isActive,
        'customRepeatDays': reminder.customRepeatDays,
        'customRepeatMinutes': reminder.customRepeatMinutes,
      });
      debugPrint('✅ [ReminderRepository] Reminder updated: ${reminder.id}');
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error updating reminder: $e');
      rethrow;
    }
  }

  Future<void> toggleReminder(String reminderId, bool isActive) async {
    try {
      await _remindersCollection.doc(reminderId).update({
        'isActive': isActive,
      });
      debugPrint('✅ [ReminderRepository] Reminder toggled: $reminderId -> $isActive');
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error toggling reminder: $e');
      rethrow;
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      await _remindersCollection.doc(reminderId).delete();
      debugPrint('✅ [ReminderRepository] Reminder deleted: $reminderId');
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error deleting reminder: $e');
      rethrow;
    }
  }

  Future<void> deleteItemReminders(String itemId) async {
    try {
      final snapshot = await _remindersCollection
          .where('itemId', isEqualTo: itemId)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      debugPrint('✅ [ReminderRepository] Deleted ${snapshot.docs.length} reminders for item: $itemId');
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error deleting item reminders: $e');
      rethrow;
    }
  }

  Future<List<ReminderModel>> getUpcomingReminders(String userId) async {
    try {
      final now = DateTime.now();
      final userReminders = await getUserReminders(userId);

      return userReminders
          .where((r) {
            final nextOccurrence = r.calculateNextOccurrence();
            return nextOccurrence.isAfter(now) &&
                   nextOccurrence.isBefore(now.add(const Duration(days: 30)));
          })
          .toList()
        ..sort((a, b) => a.calculateNextOccurrence()
            .compareTo(b.calculateNextOccurrence()));
    } catch (e) {
      debugPrint('❌ [ReminderRepository] Error getting upcoming reminders: $e');
      return [];
    }
  }

  Stream<List<ReminderModel>> streamUserReminders(String userId) {
    return _firestore
        .collection('items')
        .where('userId', isEqualTo: userId)
        .where('hasReminder', isEqualTo: true)
        .snapshots()
        .asyncMap((itemsSnapshot) async {
      if (itemsSnapshot.docs.isEmpty) return [];

      final itemIds = itemsSnapshot.docs.map((d) => d.id).toList();
      final remindersSnapshot = await _remindersCollection
          .where('itemId', whereIn: itemIds)
          .where('isActive', isEqualTo: true)
          .get();

      return remindersSnapshot.docs
          .map((doc) => ReminderModel.fromFirestore(doc))
          .toList();
    });
  }
}
