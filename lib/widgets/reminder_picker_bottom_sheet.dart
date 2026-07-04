import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/reminder_model.dart';

class ReminderPickerBottomSheet extends StatefulWidget {
  final ReminderModel? existingReminder;
  final Function(ReminderModel) onSave;
  final Function()? onDelete;

  const ReminderPickerBottomSheet({
    super.key,
    this.existingReminder,
    required this.onSave,
    this.onDelete,
  });

  static Future<ReminderModel?> show(
    BuildContext context, {
    ReminderModel? existingReminder,
    Function()? onDelete,
  }) {
    return showModalBottomSheet<ReminderModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReminderPickerBottomSheet(
        existingReminder: existingReminder,
        onSave: (reminder) => Navigator.pop(context, reminder),
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<ReminderPickerBottomSheet> createState() =>
      _ReminderPickerBottomSheetState();
}

class _ReminderPickerBottomSheetState extends State<ReminderPickerBottomSheet> {
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  RepeatFrequency _selectedRepeat = RepeatFrequency.none;
  int? _customMinutes; // Dakika bazlı tekrar için

  // Aylık ve Yıllık için ekstra state değişkenleri
  late int _selectedDayOfMonth; // Aylık için (1-31)
  late int _selectedMonthOfYear; // Yıllık için ay (1-12)
  late int _selectedDayOfYear; // Yıllık için gün (1-31)

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();

    if (widget.existingReminder != null) {
      _selectedDate = widget.existingReminder!.reminderDate;
      _selectedTime = widget.existingReminder!.reminderTime;
      _selectedRepeat = widget.existingReminder!.repeat;
      _customMinutes = widget.existingReminder!.customRepeatMinutes;

      // Mevcut hatırlatıcıdan değerleri al
      _selectedDayOfMonth = _selectedDate.day;
      _selectedMonthOfYear = _selectedDate.month;
      _selectedDayOfYear = _selectedDate.day;
    } else {
      _selectedDate = DateTime.now();
      _selectedTime = TimeOfDay.now();
      _selectedDate = _selectedDate.add(const Duration(days: 1));

      // Varsayılan değerler
      _selectedDayOfMonth = now.day;
      _selectedMonthOfYear = now.month;
      _selectedDayOfYear = now.day;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRepeatSelector(),
                  const SizedBox(height: 20),
                  if (_shouldShowDatePicker()) ...[
                    _buildDateSelector(),
                    const SizedBox(height: 20),
                  ],
                  _buildTimeSelector(),
                  const SizedBox(height: 30),
                  _buildSaveButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.existingReminder != null
                    ? 'Hatırlatıcıyı Düzenle'
                    : 'Hatırlatıcı Ekle',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: context.colors.headline,
                ),
              ),
              if (widget.existingReminder != null && widget.onDelete != null)
                IconButton(
                  onPressed: () {
                    widget.onDelete!();
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    PhosphorIconsBold.trash,
                    color: Colors.red,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildDateSelector() {
    // Aylık: Sadece gün seçici
    if (_selectedRepeat == RepeatFrequency.monthly) {
      return _buildDayOfMonthSelector();
    }
    // Yıllık: Ay + Gün seçici
    if (_selectedRepeat == RepeatFrequency.yearly) {
      return _buildMonthDaySelector();
    }
    // Tek seferlik: Tam tarih seçici
    return _buildFullDateSelector();
  }

  Widget _buildFullDateSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIconsBold.calendar,
              size: 20,
              color: context.colors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Tarih',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.hint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickDate(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDate(_selectedDate),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: context.colors.headline,
                  ),
                ),
                Icon(
                  PhosphorIconsBold.caretDown,
                  size: 16,
                  color: context.colors.hint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDayOfMonthSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIconsBold.calendar,
              size: 20,
              color: context.colors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Gün (ayda bir)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.hint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickDayOfMonth(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Her ayın $_selectedDayOfMonth. günü',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: context.colors.headline,
                  ),
                ),
                Icon(
                  PhosphorIconsBold.caretDown,
                  size: 16,
                  color: context.colors.hint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthDaySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIconsBold.calendar,
              size: 20,
              color: context.colors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Tarih (yılda bir)',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.hint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickMonthDay(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatMonthDay(_selectedMonthOfYear, _selectedDayOfYear),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: context.colors.headline,
                  ),
                ),
                Icon(
                  PhosphorIconsBold.caretDown,
                  size: 16,
                  color: context.colors.hint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIconsBold.clock,
              size: 20,
              color: context.colors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _getTimeLabel(),
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.hint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickTime(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(_selectedTime),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: context.colors.headline,
                  ),
                ),
                Icon(
                  PhosphorIconsBold.caretDown,
                  size: 16,
                  color: context.colors.hint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRepeatSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              PhosphorIconsBold.arrowsClockwise,
              size: 20,
              color: context.colors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Tekrarlama',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: context.colors.hint,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _pickRepeatFrequency(),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getRepeatLabel(_selectedRepeat),
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: context.colors.headline,
                  ),
                ),
                Icon(
                  PhosphorIconsBold.caretDown,
                  size: 16,
                  color: context.colors.hint,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveReminder,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.colors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Text(
          widget.existingReminder != null ? 'Güncelle' : 'Kaydet',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: context.colors.surfaceWhite,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.date,
                initialDateTime: _selectedDate,
                minimumDate: DateTime.now(),
                maximumDate: DateTime.now().add(const Duration(days: 365 * 10)),
                onDateTimeChanged: (date) {
                  _selectedDate = date;
                },
              ),
            ),
            CupertinoButton(
              child: const Text('Tamam'),
              onPressed: () => Navigator.pop(context, _selectedDate),
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: context.colors.surfaceWhite,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                use24hFormat: true, // 24 saatlik format
                initialDateTime: DateTime(
                  DateTime.now().year,
                  DateTime.now().month,
                  DateTime.now().day,
                  _selectedTime.hour,
                  _selectedTime.minute,
                ),
                onDateTimeChanged: (time) {
                  _selectedTime =
                      TimeOfDay(hour: time.hour, minute: time.minute);
                },
              ),
            ),
            CupertinoButton(
              child: const Text('Tamam'),
              onPressed: () => Navigator.pop(context, _selectedTime),
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _pickDayOfMonth() async {
    final picked = await showCupertinoModalPopup<int>(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: context.colors.surfaceWhite,
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: _selectedDayOfMonth - 1,
                ),
                children: List.generate(
                  31,
                  (index) => Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.poppins(fontSize: 18),
                    ),
                  ),
                ),
                onSelectedItemChanged: (index) {
                  _selectedDayOfMonth = index + 1;
                },
              ),
            ),
            CupertinoButton(
              child: const Text('Tamam'),
              onPressed: () => Navigator.pop(context, _selectedDayOfMonth),
            ),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() => _selectedDayOfMonth = picked);
    }
  }

  Future<void> _pickMonthDay() async {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 320,
        decoration: BoxDecoration(
          color: context.colors.surfaceWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Ay ve Gün Seç',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.colors.headline,
              ),
            ),
            const SizedBox(height: 16),
            // Two columns: Month and Day
            Expanded(
              child: Row(
                children: [
                  // Month picker
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 44,
                      scrollController: FixedExtentScrollController(
                        initialItem: _selectedMonthOfYear - 1,
                      ),
                      onSelectedItemChanged: (index) {
                        _selectedMonthOfYear = index + 1;
                      },
                      children: months.map((month) {
                        return Center(
                          child: Text(
                            month,
                            style: GoogleFonts.poppins(fontSize: 18),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  // Day picker
                  Expanded(
                    child: CupertinoPicker(
                      itemExtent: 44,
                      scrollController: FixedExtentScrollController(
                        initialItem: _selectedDayOfYear - 1,
                      ),
                      onSelectedItemChanged: (index) {
                        _selectedDayOfYear = index + 1;
                      },
                      children: List.generate(31, (index) {
                        return Center(
                          child: Text(
                            '${index + 1}',
                            style: GoogleFonts.poppins(fontSize: 18),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Tamam butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    DateTime(2026, _selectedMonthOfYear, _selectedDayOfYear),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Tamam',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedMonthOfYear = picked.month;
        _selectedDayOfYear = picked.day;
      });
    }
  }

  Future<void> _pickRepeatFrequency() async {
    final picked = await showModalBottomSheet<RepeatFrequency>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (builderContext) {
        final options = [
          (RepeatFrequency.none, 'Tek seferlik'),
          (RepeatFrequency.daily, 'Günlük'),
          (RepeatFrequency.weekly, 'Haftalık'),
          (RepeatFrequency.weekdays, 'Hafta içi'),
          (RepeatFrequency.weekends, 'Hafta sonu'),
          (RepeatFrequency.monthly, 'Aylık'),
          (RepeatFrequency.yearly, 'Yıllık'),
        ];

        return Container(
          decoration: BoxDecoration(
            color: context.colors.surfaceWhite,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Tekrarlama Seç',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.colors.headline,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Options - yumuşak tasarım
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: options.map((option) {
                    final value = option.$1;
                    final label = option.$2;
                    final isSelected = _selectedRepeat == value;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: InkWell(
                        onTap: () => Navigator.pop(builderContext, value),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.colors.primary.withValues(alpha: 0.1)
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? context.colors.primary.withValues(alpha: 0.3)
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                label,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? context.colors.primary
                                      : context.colors.headline,
                                ),
                              ),
                              const Spacer(),
                              if (isSelected)
                                Icon(
                                  PhosphorIconsBold.checkCircle,
                                  color: context.colors.primary,
                                  size: 22,
                                )
                              else
                                Icon(
                                  PhosphorIconsBold.circle,
                                  color: Colors.grey[300],
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedRepeat = picked;
        // Reset date to today when switching to recurrence types that don't need date
        if (!_shouldShowDatePickerForType(picked)) {
          _selectedDate = DateTime.now();
        }
      });
    }
  }

  void _saveReminder() {
    DateTime reminderDate;

    switch (_selectedRepeat) {
      case RepeatFrequency.none:
        // Tam tarih kullan
        reminderDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        );
        break;
      case RepeatFrequency.monthly:
        // Sadece gün kullan, ay/yıl bugünden al
        final now = DateTime.now();
        reminderDate = DateTime(
          now.year,
          now.month,
          _selectedDayOfMonth,
        );
        break;
      case RepeatFrequency.yearly:
        // Ay+gün kullan, yıl bugünden al
        final now = DateTime.now();
        reminderDate = DateTime(
          now.year,
          _selectedMonthOfYear,
          _selectedDayOfYear,
        );
        break;
      default:
        // Diğer durumlar için bugünü kullan
        reminderDate = DateTime.now();
    }

    final reminder = ReminderModel(
      id: widget.existingReminder?.id,
      itemId: widget.existingReminder?.itemId ?? '',
      reminderDate: reminderDate,
      reminderTime: _selectedTime,
      repeat: _selectedRepeat,
      customRepeatMinutes: _selectedRepeat == RepeatFrequency.customMinutes
          ? _customMinutes
          : null,
      isActive: true,
      createdAt: widget.existingReminder?.createdAt ?? DateTime.now(),
      lastTriggered: widget.existingReminder?.lastTriggered,
    );

    widget.onSave(reminder);
  }

  String _formatDate(DateTime date) {
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
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatMonthDay(int month, int day) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return '$day ${months[month - 1]}';
  }

  String _getRepeatLabel(RepeatFrequency frequency) {
    switch (frequency) {
      case RepeatFrequency.none:
        return 'Tek seferlik';
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
        if (_customMinutes != null) {
          if (_customMinutes! < 60) {
            return '$_customMinutes dakikada bir';
          } else {
            final hours = _customMinutes! ~/ 60;
            return '$hours saatte bir';
          }
        }
        return 'Dakikada bir';
      case RepeatFrequency.customDays:
        return 'Gün bazlı';
    }
  }

  /// Check if date picker should be shown for current recurrence type
  bool _shouldShowDatePicker() {
    return _shouldShowDatePickerForType(_selectedRepeat);
  }

  /// Check if date picker should be shown for a given recurrence type
  bool _shouldShowDatePickerForType(RepeatFrequency type) {
    return type == RepeatFrequency.none ||
        type == RepeatFrequency.yearly ||
        type == RepeatFrequency.monthly;
  }

  /// Get context-aware time label
  String _getTimeLabel() {
    switch (_selectedRepeat) {
      case RepeatFrequency.none:
        return 'Saat';
      case RepeatFrequency.yearly:
        return 'Saat';
      case RepeatFrequency.monthly:
        return 'Saat';
      case RepeatFrequency.daily:
        return 'Saat (günde bir)';
      case RepeatFrequency.weekly:
        return 'Saat (haftada bir)';
      case RepeatFrequency.weekdays:
        return 'Saat (hafta içi)';
      case RepeatFrequency.weekends:
        return 'Saat (hafta sonu)';
      default:
        return 'Saat';
    }
  }
}
