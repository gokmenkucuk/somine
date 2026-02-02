import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/reminder_model.dart';

class ReminderIndicator extends StatelessWidget {
  final ReminderModel reminder;
  final VoidCallback? onTap;

  const ReminderIndicator({
    super.key,
    required this.reminder,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final nextOccurrence = reminder.calculateNextOccurrence();
    final isOverdue = nextOccurrence.isBefore(DateTime.now());
    final isToday = _isSameDay(nextOccurrence, DateTime.now());
    final isTomorrow = _isSameDay(
      nextOccurrence,
      DateTime.now().add(const Duration(days: 1)),
    );
    final isThisYear = nextOccurrence.year == DateTime.now().year;

    String timeLabel;
    if (isToday) {
      timeLabel = 'Bugün, ${_formatTime(reminder.reminderTime)}';
    } else if (isTomorrow) {
      timeLabel = 'Yarın, ${_formatTime(reminder.reminderTime)}';
    } else {
      timeLabel =
          '${_formatDate(nextOccurrence, isThisYear)}, ${_formatTime(reminder.reminderTime)}';
    }

    // Tekrarlama durumu ekleyin
    String repeatLabel = '';
    if (reminder.repeat != RepeatFrequency.none) {
      repeatLabel = _getRepeatLabel(reminder);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isOverdue
              ? Colors.red.withOpacity(0.1)
              : context.colors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverdue
                ? Colors.red.withOpacity(0.3)
                : context.colors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getRepeatIcon(reminder.repeat),
              size: 12,
              color: isOverdue ? Colors.red : context.colors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              repeatLabel.isNotEmpty ? '$timeLabel ($repeatLabel)' : timeLabel,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isOverdue ? Colors.red : context.colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getRepeatLabel(ReminderModel reminder) {
    switch (reminder.repeat) {
      case RepeatFrequency.daily:
        return 'Günlük';
      case RepeatFrequency.weekly:
        return 'Haftalık';
      case RepeatFrequency.monthly:
        return 'Aylık';
      case RepeatFrequency.yearly:
        return 'Yıllık';
      case RepeatFrequency.weekdays:
        return 'Hafta içi';
      case RepeatFrequency.weekends:
        return 'Hafta sonu';
      case RepeatFrequency.customMinutes:
        if (reminder.customRepeatMinutes != null) {
          if (reminder.customRepeatMinutes! < 60) {
            return '${reminder.customRepeatMinutes}dk';
          } else {
            final hours = reminder.customRepeatMinutes! ~/ 60;
            return '$hours saat';
          }
        }
        return 'Tekrar';
      case RepeatFrequency.customDays:
        return 'Gün bazlı';
      case RepeatFrequency.none:
        return '';
    }
  }

  IconData _getRepeatIcon(RepeatFrequency repeat) {
    switch (repeat) {
      case RepeatFrequency.daily:
      case RepeatFrequency.weekly:
      case RepeatFrequency.monthly:
      case RepeatFrequency.yearly:
      case RepeatFrequency.weekdays:
      case RepeatFrequency.weekends:
      case RepeatFrequency.customMinutes:
      case RepeatFrequency.customDays:
        return PhosphorIconsBold.arrowsClockwise;
      case RepeatFrequency.none:
        return PhosphorIconsBold.bell;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDate(DateTime date, bool isThisYear) {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara'
    ];
    return '${date.day} ${months[date.month - 1]}${isThisYear ? '' : ', ${date.year}'}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
