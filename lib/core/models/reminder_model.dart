import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum RepeatFrequency {
  none,
  daily,
  weekly,
  monthly,
  yearly,
  weekdays,
  weekends,
  customMinutes, // Dakika bazlı tekrar (5dk, 15dk, vb.)
  customDays,    // Gün bazlı tekrar
}

class ReminderModel {
  final String? id;
  final String itemId;
  final DateTime reminderDate;
  final TimeOfDay reminderTime;
  final RepeatFrequency repeat;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastTriggered;
  final int? customRepeatDays;
  final int? customRepeatMinutes; // Dakika bazlı tekrar için

  const ReminderModel({
    this.id,
    required this.itemId,
    required this.reminderDate,
    required this.reminderTime,
    this.repeat = RepeatFrequency.none,
    this.isActive = true,
    required this.createdAt,
    this.lastTriggered,
    this.customRepeatDays,
    this.customRepeatMinutes,
  });

  factory ReminderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final timeData = data['reminderTime'] as Map<String, dynamic>;

    return ReminderModel(
      id: doc.id,
      itemId: data['itemId'] as String,
      reminderDate: (data['reminderDate'] as Timestamp).toDate(),
      reminderTime: TimeOfDay(
        hour: timeData['hour'] as int,
        minute: timeData['minute'] as int,
      ),
      repeat: RepeatFrequency.values.firstWhere(
        (e) => e.name == data['repeat'],
        orElse: () => RepeatFrequency.none,
      ),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastTriggered: data['lastTriggered'] != null
          ? (data['lastTriggered'] as Timestamp).toDate()
          : null,
      customRepeatDays: data['customRepeatDays'] as int?,
      customRepeatMinutes: data['customRepeatMinutes'] as int?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'itemId': itemId,
      'reminderDate': Timestamp.fromDate(reminderDate),
      'reminderTime': {
        'hour': reminderTime.hour,
        'minute': reminderTime.minute,
      },
      'repeat': repeat.name,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastTriggered': lastTriggered != null
          ? Timestamp.fromDate(lastTriggered!)
          : null,
      'customRepeatDays': customRepeatDays,
      'customRepeatMinutes': customRepeatMinutes,
    };
  }

  ReminderModel copyWith({
    String? id,
    String? itemId,
    DateTime? reminderDate,
    TimeOfDay? reminderTime,
    RepeatFrequency? repeat,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastTriggered,
    int? customRepeatDays,
    int? customRepeatMinutes,
  }) {
    return ReminderModel(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      reminderDate: reminderDate ?? this.reminderDate,
      reminderTime: reminderTime ?? this.reminderTime,
      repeat: repeat ?? this.repeat,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      customRepeatDays: customRepeatDays ?? this.customRepeatDays,
      customRepeatMinutes: customRepeatMinutes ?? this.customRepeatMinutes,
    );
  }

  DateTime calculateNextOccurrence() {
    if (!isActive) return reminderDate;

    DateTime now = DateTime.now();

    // Create candidate date from reminder date + time
    DateTime candidate = DateTime(
      reminderDate.year,
      reminderDate.month,
      reminderDate.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    // If candidate is in the past, calculate next occurrence
    if (candidate.isBefore(now)) {
      candidate = _calculateNextInstance(candidate, now, repeat);
    }

    return candidate;
  }

  DateTime _calculateNextInstance(
    DateTime candidate,
    DateTime now,
    RepeatFrequency type,
  ) {
    switch (type) {
      case RepeatFrequency.daily:
        return _nextDaily(candidate, now);

      case RepeatFrequency.weekly:
        return _nextWeekly(candidate, now);

      case RepeatFrequency.monthly:
        return _nextMonthly(candidate, now);

      case RepeatFrequency.yearly:
        return _nextYearly(candidate, now);

      case RepeatFrequency.weekdays:
        return _nextWeekdaysOnly(candidate, now);

      case RepeatFrequency.weekends:
        return _nextWeekendsOnly(candidate, now);

      case RepeatFrequency.customDays:
        return _nextCustomDays(candidate, now);

      case RepeatFrequency.customMinutes:
        return _nextCustomMinutes(candidate, now);

      case RepeatFrequency.none:
        return candidate;
    }
  }

  /// Daily: Add 1 day until in the future
  DateTime _nextDaily(DateTime candidate, DateTime now) {
    do {
      candidate = candidate.add(const Duration(days: 1));
    } while (candidate.isBefore(now));
    return candidate;
  }

  /// Weekly: Add 7 days until in the future
  DateTime _nextWeekly(DateTime candidate, DateTime now) {
    do {
      candidate = candidate.add(const Duration(days: 7));
    } while (candidate.isBefore(now));
    return candidate;
  }

  /// Monthly: Add 1 month, preserving day when possible
  DateTime _nextMonthly(DateTime candidate, DateTime now) {
    int originalDay = candidate.day;

    while (candidate.isBefore(now)) {
      int nextMonth = candidate.month + 1;
      int nextYear = candidate.year;

      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }

      // Get the last day of the target month
      int lastDayOfTargetMonth = _getLastDayOfMonth(nextYear, nextMonth);

      // Use the original day, or clamp to last day of month
      int targetDay = originalDay > lastDayOfTargetMonth ? lastDayOfTargetMonth : originalDay;

      candidate = DateTime(
        nextYear,
        nextMonth,
        targetDay,
        reminderTime.hour,
        reminderTime.minute,
      );
    }

    return candidate;
  }

  /// Yearly: Add 1 year, handling leap years
  DateTime _nextYearly(DateTime candidate, DateTime now) {
    while (candidate.isBefore(now)) {
      int nextYear = candidate.year + 1;

      // Handle Feb 29th (leap day)
      if (candidate.month == 2 && candidate.day == 29) {
        // Check if next year is a leap year
        bool isLeapYear = _isLeapYear(nextYear);
        if (isLeapYear) {
          candidate = DateTime(nextYear, 2, 29, reminderTime.hour, reminderTime.minute);
        } else {
          // Move to Feb 28th on non-leap years
          candidate = DateTime(nextYear, 2, 28, reminderTime.hour, reminderTime.minute);
        }
      } else {
        candidate = DateTime(
          nextYear,
          candidate.month,
          candidate.day,
          reminderTime.hour,
          reminderTime.minute,
        );
      }
    }

    return candidate;
  }

  /// Weekdays Only: Mon-Fri only, skip weekends
  DateTime _nextWeekdaysOnly(DateTime candidate, DateTime now) {
    // First, ensure we're on a weekday
    while (candidate.weekday == 6 || candidate.weekday == 7) {
      candidate = candidate.add(const Duration(days: 1));
    }

    // Then move forward until we're in the future AND on a weekday
    while (candidate.isBefore(now) || candidate.weekday == 6 || candidate.weekday == 7) {
      candidate = candidate.add(const Duration(days: 1));
    }

    return candidate;
  }

  /// Weekends Only: Sat-Sun only
  DateTime _nextWeekendsOnly(DateTime candidate, DateTime now) {
    // First, ensure we're on a weekend day
    while (candidate.weekday >= 1 && candidate.weekday <= 5) {
      candidate = candidate.add(const Duration(days: 1));
    }

    // Then move forward until we're in the future AND on a weekend
    while (candidate.isBefore(now) || (candidate.weekday >= 1 && candidate.weekday <= 5)) {
      candidate = candidate.add(const Duration(days: 1));
    }

    return candidate;
  }

  /// Custom days interval
  DateTime _nextCustomDays(DateTime candidate, DateTime now) {
    if (customRepeatDays == null) return candidate;

    do {
      candidate = candidate.add(Duration(days: customRepeatDays!));
    } while (candidate.isBefore(now));

    return candidate;
  }

  /// Custom minutes interval
  DateTime _nextCustomMinutes(DateTime candidate, DateTime now) {
    if (customRepeatMinutes == null) return candidate;

    do {
      candidate = candidate.add(Duration(minutes: customRepeatMinutes!));
    } while (candidate.isBefore(now));

    return candidate;
  }

  /// Helper: Get the last day of a given month
  int _getLastDayOfMonth(int year, int month) {
    // Month has 31 days
    if ([1, 3, 5, 7, 8, 10, 12].contains(month)) {
      return 31;
    }
    // Month has 30 days
    if ([4, 6, 9, 11].contains(month)) {
      return 30;
    }
    // February - check for leap year
    if (month == 2) {
      return _isLeapYear(year) ? 29 : 28;
    }
    return 28; // Fallback
  }

  /// Helper: Check if a year is a leap year
  bool _isLeapYear(int year) {
    if (year % 4 != 0) return false;
    if (year % 100 != 0) return true;
    return year % 400 == 0;
  }
}
