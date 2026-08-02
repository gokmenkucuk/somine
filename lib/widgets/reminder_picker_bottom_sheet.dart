import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/reminder_model.dart';
import 'package:somine_app/core/services/analytics_service.dart';

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
  }) async {
    // Bottom-sheet'ler FirebaseAnalyticsObserver'da görünmez; manuel logla.
    AnalyticsService.instance.logScreenView('reminder_picker_sheet');
    final reminder = await showModalBottomSheet<ReminderModel>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ReminderPickerBottomSheet(
        existingReminder: existingReminder,
        onSave: (reminder) => Navigator.pop(context, reminder),
        onDelete: onDelete,
      ),
    );
    if (reminder != null) {
      AnalyticsService.instance.logReminderSet(
        source: 'picker',
        frequency: reminder.repeat.name,
      );
    }
    return reminder;
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
      // Çocuk içeriğin (scroll view, divider, InkWell ripple) yuvarlatılmış
      // üst köşelerin dışına boyanmasını engeller. Tüm bottom sheet'lerde ortak.
      clipBehavior: Clip.antiAlias,
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
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const SizedBox(height: 12),
        // Drag handle - 40x4, tüm sheet'lerde ortak
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: context.colors.divider,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 8, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.existingReminder != null
                      ? l10n.reminderPickerEditTitle
                      : l10n.reminderAddTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.colors.headline,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (widget.existingReminder != null && widget.onDelete != null)
                IconButton(
                  tooltip: l10n.reminderPickerDeleteTooltip,
                  onPressed: () {
                    widget.onDelete!();
                    Navigator.pop(context);
                  },
                  icon: Icon(
                    PhosphorIconsBold.trash,
                    color: context.colors.danger,
                  ),
                )
              else
                const SizedBox(width: 12),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Divider(height: 1, thickness: 1, color: context.colors.divider),
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
              AppLocalizations.of(context)!.reminderPickerFieldDate,
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
              border: Border.all(color: context.colors.divider),
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
              AppLocalizations.of(context)!.reminderPickerFieldDayOfMonth,
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
              border: Border.all(color: context.colors.divider),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!
                      .reminderPickerDayOfMonthValue(_selectedDayOfMonth),
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
              AppLocalizations.of(context)!.reminderPickerFieldDateYearly,
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
              border: Border.all(color: context.colors.divider),
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
              border: Border.all(color: context.colors.divider),
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
              AppLocalizations.of(context)!.reminderPickerFieldRepeat,
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
              border: Border.all(color: context.colors.divider),
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
          widget.existingReminder != null
              ? AppLocalizations.of(context)!.commonUpdate
              : AppLocalizations.of(context)!.commonSave,
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
              child: Text(AppLocalizations.of(context)!.commonOk),
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
              child: Text(AppLocalizations.of(context)!.commonOk),
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
              child: Text(AppLocalizations.of(context)!.commonOk),
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
    final months = _monthNames();

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 320,
        clipBehavior: Clip.antiAlias,
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
                color: context.colors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context)!.reminderPickerMonthDaySheetTitle,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.headline,
                letterSpacing: -0.5,
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
                    AppLocalizations.of(context)!.commonOk,
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
      isScrollControlled: true,
      builder: (builderContext) {
        final l10n = AppLocalizations.of(builderContext)!;
        final options = [
          (RepeatFrequency.none, l10n.addContentRepeatOnce),
          (RepeatFrequency.daily, l10n.addContentRepeatDaily),
          (RepeatFrequency.weekly, l10n.addContentRepeatWeekly),
          (RepeatFrequency.weekdays, l10n.addContentRepeatWeekdays),
          (RepeatFrequency.weekends, l10n.addContentRepeatWeekends),
          (RepeatFrequency.monthly, l10n.addContentRepeatMonthly),
          (RepeatFrequency.yearly, l10n.addContentRepeatYearly),
        ];

        return Container(
          clipBehavior: Clip.antiAlias,
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
                  color: context.colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  l10n.reminderPickerRepeatSheetTitle,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: context.colors.headline,
                    letterSpacing: -0.5,
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
                                : context.colors.hint.withValues(alpha: 0.08),
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
                                  color: context.colors.iconInactive,
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

  /// Tarih biçimlendirmesi için aktif dil kodu.
  /// `main.dart` yalnızca 'tr' verisini yüklüyor; 'en' intl'de gömülü olduğu
  /// için diğer tüm diller güvenli şekilde 'en'e düşer.
  String get _dateLocale {
    final code = Localizations.localeOf(context).languageCode;
    return code == 'tr' ? 'tr' : 'en';
  }

  List<String> _monthNames() {
    final format = DateFormat.MMMM(_dateLocale);
    return List.generate(12, (i) => format.format(DateTime(2024, i + 1)));
  }

  String _formatDate(DateTime date) {
    return DateFormat('d MMM y', _dateLocale).format(date);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatMonthDay(int month, int day) {
    return DateFormat('d MMMM', _dateLocale).format(DateTime(2024, month, day));
  }

  String _getRepeatLabel(RepeatFrequency frequency) {
    final l10n = AppLocalizations.of(context)!;
    switch (frequency) {
      case RepeatFrequency.none:
        return l10n.addContentRepeatOnce;
      case RepeatFrequency.daily:
        return l10n.addContentRepeatDaily;
      case RepeatFrequency.weekly:
        return l10n.addContentRepeatWeekly;
      case RepeatFrequency.monthly:
        return l10n.addContentRepeatMonthly;
      case RepeatFrequency.yearly:
        return l10n.addContentRepeatYearly;
      case RepeatFrequency.weekdays:
        return l10n.addContentRepeatWeekdays;
      case RepeatFrequency.weekends:
        return l10n.addContentRepeatWeekends;
      case RepeatFrequency.customMinutes:
        if (_customMinutes != null) {
          if (_customMinutes! < 60) {
            return l10n.reminderPickerRepeatEveryNMinutes(_customMinutes!);
          }
          return l10n.reminderPickerRepeatEveryNHours(_customMinutes! ~/ 60);
        }
        return l10n.addContentRepeatCustomMinutes;
      case RepeatFrequency.customDays:
        return l10n.addContentRepeatCustomDays;
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
