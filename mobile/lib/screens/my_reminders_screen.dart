import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/reminder_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/providers/navigation_providers.dart';
import 'package:somine_app/core/providers/reminder_providers.dart';
import 'package:somine_app/core/services/reminder_scheduler_service.dart';
import 'package:somine_app/widgets/error_state_widget.dart';
import 'package:somine_app/widgets/item_detail_bottom_sheet.dart';
import 'package:somine_app/widgets/reminder_picker_bottom_sheet.dart';

enum _ReminderFilter { upcoming, past, all }

class MyRemindersScreen extends ConsumerStatefulWidget {
  const MyRemindersScreen({super.key});

  @override
  ConsumerState<MyRemindersScreen> createState() => _MyRemindersScreenState();
}

class _MyRemindersScreenState extends ConsumerState<MyRemindersScreen> {
  _ReminderFilter _filter = _ReminderFilter.upcoming;

  /// Kaydırarak silinen satırlar, provider yenilenene kadar listeden hemen
  /// düşürülür (Dismissible ağaçta kalamaz).
  final Set<String> _hiddenKeys = <String>{};

  String _keyOf(ReminderModel reminder) =>
      reminder.id ?? '${reminder.itemId}-${reminder.createdAt}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final remindersAsync = ref.watch(remindersWithItemsProvider);

    return Scaffold(
      backgroundColor: context.colors.backgroundBottom,
      appBar: AppBar(
        backgroundColor: context.colors.backgroundTop,
        elevation: 0,
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: context.colors.headline),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.myRemindersTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: context.colors.headline,
          ),
        ),
        centerTitle: true,
      ),
      body: remindersAsync.when(
        data: (all) {
          final visible = _apply(_filter, all)
              .where((e) => !_hiddenKeys.contains(_keyOf(e.reminder)))
              .toList();
          return Column(
            children: [
              _buildFilterRow(),
              Expanded(
                child: visible.isEmpty
                    ? _buildEmptyState(all.isEmpty)
                    : RefreshIndicator(
                        color: context.colors.primary,
                        onRefresh: () async =>
                            ref.invalidate(remindersWithItemsProvider),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: visible.length,
                          itemBuilder: (context, index) =>
                              _buildCard(visible[index]),
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: l10n.myRemindersLoadError,
          onRetry: () => ref.invalidate(remindersWithItemsProvider),
        ),
      ),
    );
  }

  List<ReminderWithItem> _apply(
    _ReminderFilter filter,
    List<ReminderWithItem> all,
  ) {
    switch (filter) {
      case _ReminderFilter.upcoming:
        return all.where((r) => !r.isPast).toList();
      case _ReminderFilter.past:
        return all.where((r) => r.isPast).toList().reversed.toList();
      case _ReminderFilter.all:
        return all;
    }
  }

  Widget _buildFilterRow() {
    final l10n = AppLocalizations.of(context)!;
    // Sabit yükseklik yok: büyük yazı boyutlarında satır büyüyebilir.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip(
            l10n.myRemindersFilterUpcoming,
            PhosphorIconsBold.clock,
            _ReminderFilter.upcoming,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            l10n.myRemindersFilterPast,
            PhosphorIconsBold.clockCounterClockwise,
            _ReminderFilter.past,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            l10n.myRemindersFilterAll,
            PhosphorIconsBold.listBullets,
            _ReminderFilter.all,
          ),
        ],
      ),
    );
  }

  /// search_screen'deki vault/akıllı chip stiliyle aynı — tek seçimli hâli.
  Widget _buildFilterChip(String label, IconData icon, _ReminderFilter value) {
    final isSelected = _filter == value;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    return Semantics(
      button: true,
      selected: isSelected,
      excludeSemantics: true,
      label: label,
      child: GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? context.colors.primary : context.colors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : context.colors.primary.withValues(alpha: 0.2),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: context.colors.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? onPrimary : context.colors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? onPrimary : context.colors.headline,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildEmptyState(bool noneAtAll) {
    final l10n = AppLocalizations.of(context)!;
    final String title;
    if (noneAtAll) {
      title = l10n.myRemindersEmptyTitle;
    } else if (_filter == _ReminderFilter.past) {
      title = l10n.myRemindersEmptyPast;
    } else {
      title = l10n.myRemindersEmptyUpcoming;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.alarm,
            size: 64,
            color: context.colors.iconInactive,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: context.colors.headline,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              l10n.myRemindersEmptySubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: context.colors.body,
              ),
            ),
          ),
          if (_filter != _ReminderFilter.past) ...[
            const SizedBox(height: 20),
            TextButton.icon(
              onPressed: _goToSaves,
              icon: const Icon(PhosphorIconsRegular.bookmarkSimple, size: 18),
              label: Text(l10n.myRemindersEmptyAction),
            ),
          ],
        ],
      ),
    );
  }

  /// Boş durumdan sonraki adım: hatırlatıcı kurulacak içeriklerin olduğu
  /// akış sekmesine dön.
  void _goToSaves() {
    final tabNotifier = ref.read(homeTabIndexProvider.notifier);
    Navigator.of(context).popUntil((route) => route.isFirst);
    tabNotifier.state = 0;
  }

  Widget _buildCard(ReminderWithItem entry) {
    final l10n = AppLocalizations.of(context)!;
    final reminder = entry.reminder;
    final item = entry.item;
    final isPast = entry.isPast;

    return Dismissible(
      key: Key(_keyOf(reminder)),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: context.colors.danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          PhosphorIconsRegular.trash,
          color: Theme.of(context).colorScheme.onError,
        ),
      ),
      onDismissed: (_) => _delete(entry),
      child: GestureDetector(
        onTap: item == null ? null : () => _openItem(item),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.colors.surfaceWhite,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.colors.premiumShadow.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (isPast
                          ? context.colors.iconInactive
                          : context.colors.primary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _iconFor(item),
                  size: 20,
                  color: isPast
                      ? context.colors.iconInactive
                      : context.colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item?.displayTitle ?? l10n.myRemindersItemMissing,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: item == null
                            ? context.colors.hint
                            : context.colors.headline,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _formatWhen(entry.nextOccurrence),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: context.colors.body,
                            ),
                          ),
                        ),
                        if (reminder.repeat != RepeatFrequency.none) ...[
                          const SizedBox(width: 8),
                          _buildRepeatBadge(reminder.repeat),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.myRemindersMoreActions,
                icon: Icon(
                  PhosphorIconsRegular.dotsThreeVertical,
                  color: context.colors.iconInactive,
                ),
                onPressed: () => _showActions(entry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRepeatBadge(RepeatFrequency repeat) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.colors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _repeatLabel(repeat),
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.colors.primary,
        ),
      ),
    );
  }

  IconData _iconFor(ItemModel? item) {
    switch (item?.type) {
      case ItemType.note:
        return PhosphorIconsRegular.note;
      case ItemType.image:
        return PhosphorIconsRegular.image;
      case ItemType.link:
        return PhosphorIconsRegular.link;
      case null:
        return PhosphorIconsRegular.alarm;
    }
  }

  String _repeatLabel(RepeatFrequency repeat) {
    final l10n = AppLocalizations.of(context)!;
    switch (repeat) {
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
        return l10n.addContentRepeatCustomMinutes;
      case RepeatFrequency.customDays:
        return l10n.addContentRepeatCustomDays;
    }
  }

  /// Tarih dile göre; saat dile ve cihazın 12/24 saat ayarına göre.
  String _formatWhen(DateTime when) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat('d MMMM y', locale).format(when);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(when),
      alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
    );
    return '$date • $time';
  }

  Future<void> _openItem(ItemModel item) async {
    final categories = ref.read(categoriesProvider).value ?? const [];
    final match = categories.where((c) => c.id == item.categoryId);
    final categoryName = match.isEmpty ? '' : match.first.name;
    await ItemDetailBottomSheet.show(context, item, categoryName, categories);
    if (mounted) ref.invalidate(remindersWithItemsProvider);
  }

  void _showActions(ReminderWithItem entry) {
    final l10n = AppLocalizations.of(context)!;
    showCupertinoModalPopup<void>(
      context: context,
      builder: (sheetContext) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _edit(entry);
            },
            child: Text(l10n.myRemindersEdit),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(sheetContext);
              _delete(entry);
            },
            child: Text(l10n.myRemindersDelete),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: Text(l10n.commonCancel),
        ),
      ),
    );
  }

  Future<void> _edit(ReminderWithItem entry) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await ReminderPickerBottomSheet.show(
      context,
      existingReminder: entry.reminder,
      onDelete: () => _delete(entry),
    );
    if (result == null || !mounted) return;

    // Picker itemId'yi boş döndürebiliyor; mevcut bağlantıyı korumak şart.
    final ok = await ReminderSchedulerService().updateReminder(
      result.copyWith(itemId: entry.reminder.itemId),
      entry.item?.displayTitle ?? '',
    );
    if (!mounted) return;
    if (!ok) {
      _toast(l10n.successSheetReminderFailed);
    }
    ref.invalidate(remindersWithItemsProvider);
  }

  /// Doğrudan repository.deleteReminder ÇAĞIRMA — bildirimi iptal etmez ve
  /// item.hasReminder bayrağını true bırakır. Scheduler ikisini de yapar.
  /// Silme hemen uygulanır; "Geri Al" hatırlatıcıyı yeniden oluşturup
  /// bildirimini yeniden kurar.
  Future<void> _delete(ReminderWithItem entry) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final key = _keyOf(entry.reminder);
    setState(() => _hiddenKeys.add(key));
    await ReminderSchedulerService().cancelReminder(entry.reminder.itemId);
    if (!mounted) return;
    ref.invalidate(remindersWithItemsProvider);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.myRemindersDeleted),
          action: SnackBarAction(
            label: l10n.commonUndo,
            onPressed: () => _restore(entry, key, messenger, l10n),
          ),
        ),
      );
  }

  Future<void> _restore(
    ReminderWithItem entry,
    String key,
    ScaffoldMessengerState messenger,
    AppLocalizations l10n,
  ) async {
    final ok = await ReminderSchedulerService().scheduleReminder(
      entry.reminder,
      entry.item?.displayTitle ?? '',
    );
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.successSheetReminderFailed)),
      );
    }
    if (!mounted) return;
    setState(() => _hiddenKeys.remove(key));
    ref.invalidate(remindersWithItemsProvider);
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
