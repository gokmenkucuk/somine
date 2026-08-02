import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/reminder_model.dart';
import 'package:somine_app/core/providers/subscription_provider.dart';
import 'package:somine_app/core/repositories/reminder_repository.dart';
import 'package:somine_app/core/services/analytics_service.dart';
import 'package:somine_app/core/services/reminder_scheduler_service.dart';
import 'package:somine_app/core/utils/resurfacing_dates.dart';
import 'package:somine_app/widgets/limit_reached_dialog.dart';

class SuccessNotificationSheet extends ConsumerStatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onUndo;

  /// Hızlı hatırlatıcı aksiyonları ("Yarın" / "Hafta sonu") YALNIZ bu iki
  /// parametre verildiğinde görünür. Mevcut çağıranlar etkilenmez.
  final String? quickReminderItemId;
  final String? quickReminderItemTitle;

  const SuccessNotificationSheet({
    super.key,
    required this.title,
    required this.message,
    this.onUndo,
    this.quickReminderItemId,
    this.quickReminderItemTitle,
  });

  static Future<void> show(BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onUndo,
    String? quickReminderItemId,
    String? quickReminderItemTitle,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => SuccessNotificationSheet(
        title: title,
        message: message,
        onUndo: onUndo,
        quickReminderItemId: quickReminderItemId,
        quickReminderItemTitle: quickReminderItemTitle,
      ),
    );
  }

  @override
  ConsumerState<SuccessNotificationSheet> createState() =>
      _SuccessNotificationSheetState();
}

class _SuccessNotificationSheetState
    extends ConsumerState<SuccessNotificationSheet> {
  Timer? _dismissTimer;
  bool _isSchedulingReminder = false;

  /// Aksiyon sonucu güncellenen başlık/mesaj (null iken widget değerleri).
  String? _overrideTitle;
  String? _overrideMessage;

  bool get _hasQuickReminder =>
      widget.quickReminderItemId != null &&
      widget.quickReminderItemId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    // Auto-dismiss: undo veya hızlı aksiyon varsa 4sn, yoksa 2sn.
    _startDismissTimer(
      Duration(
        seconds: (widget.onUndo != null || _hasQuickReminder) ? 4 : 2,
      ),
    );
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  void _startDismissTimer(Duration duration) {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(duration, () {
      if (mounted) {
        _safePop();
      }
    });
  }

  /// Safely pops the bottom sheet only if it's the current route
  void _safePop() {
    final route = ModalRoute.of(context);
    if (route?.isCurrent == true) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _onQuickReminderTap({required bool weekend}) async {
    if (_isSchedulingReminder) return;
    // Aksiyona basılınca auto-dismiss iptal.
    _dismissTimer?.cancel();
    setState(() => _isSchedulingReminder = true);

    final l10n = AppLocalizations.of(context)!;

    try {
      // Limit kontrolü (add_content_screen'deki kalıpla).
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final subState = ref.read(subscriptionProvider);
      if (uid != null && !subState.isPremium) {
        try {
          final reminders = await ReminderRepository().getUserReminders(uid);
          final activeCount = reminders.where((r) => r.isActive).length;
          final canCreate = ref
              .read(subscriptionProvider.notifier)
              .canCreateReminder(activeCount);
          if (!canCreate) {
            if (mounted) {
              await LimitReachedDialog.show(
                context: context,
                ref: ref,
                title: l10n.limitReminderTitle,
                message: l10n.limitReminderDescription,
                type: LimitType.item,
              );
            }
            if (mounted) _safePop();
            return;
          }
        } catch (e) {
          debugPrint('SuccessSheet reminder limit check error: $e');
        }
      }

      final now = DateTime.now();
      final reminderDate =
          weekend
              ? ResurfacingDates.nextSaturday(now)
              : ResurfacingDates.tomorrow(now);
      final reminder = ReminderModel(
        itemId: widget.quickReminderItemId!,
        reminderDate: reminderDate,
        reminderTime: TimeOfDay.fromDateTime(now),
        repeat: RepeatFrequency.none,
        createdAt: now,
      );

      final scheduled = await ReminderSchedulerService().scheduleReminder(
        reminder,
        widget.quickReminderItemTitle ?? '',
      );

      if (scheduled) {
        AnalyticsService.instance.logReminderSet(
          source: 'success_sheet',
          frequency: RepeatFrequency.none.name,
        );
      }

      if (!mounted) return;
      setState(() {
        if (scheduled) {
          _overrideTitle = l10n.successSheetReminderSetTitle;
          _overrideMessage =
              weekend
                  ? l10n.successSheetReminderSetWeekend
                  : l10n.successSheetReminderSetTomorrow;
        } else {
          _overrideMessage = l10n.successSheetReminderFailed;
        }
      });
      _startDismissTimer(const Duration(seconds: 2));
    } catch (e) {
      debugPrint('SuccessSheet quick reminder error: $e');
      if (mounted) {
        setState(() => _overrideMessage = l10n.successSheetReminderFailed);
        _startDismissTimer(const Duration(seconds: 2));
      }
    } finally {
      if (mounted) setState(() => _isSchedulingReminder = false);
    }
  }

  Widget _buildQuickReminderActions(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    Widget buildAction(String label, {required bool weekend}) {
      return Expanded(
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed:
                _isSchedulingReminder
                    ? null
                    : () => _onQuickReminderTap(weekend: weekend),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: context.colors.primary,
              disabledBackgroundColor: Colors.white.withValues(alpha: 0.6),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        buildAction(l10n.successSheetQuickReminderTomorrow, weekend: false),
        const SizedBox(width: 12),
        buildAction(l10n.successSheetQuickReminderWeekend, weekend: true),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showQuickActions =
        _hasQuickReminder && _overrideTitle == null && _overrideMessage == null;

    return Container(
      clipBehavior: Clip.antiAlias,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            context.colors.primary,
            context.colors.secondary,
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 56),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Drag Handle
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 32),

                // Icon Circle
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      PhosphorIconsBold.check,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  _overrideTitle ?? widget.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Message
                Text(
                  _overrideMessage ?? widget.message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
                if (showQuickActions) ...[
                  const SizedBox(height: 24),
                  _buildQuickReminderActions(context),
                ],
                if (widget.onUndo != null) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onUndo!();
                        _safePop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: context.colors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        "Geri Al",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Close Button
          Positioned(
            top: 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _safePop,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    PhosphorIconsLight.x,
                    size: 20,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
