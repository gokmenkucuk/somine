import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/screens/catalog_screen.dart'
    show isSelectionModeProvider, selectedItemsProvider;
import 'package:somine_app/core/utils/failure_mapper.dart';
import 'package:somine_app/widgets/success_notification_sheet.dart';

/// Akıştan içerik silmenin tek yolu: iyimser kaldırma → soft delete →
/// "Geri Al" seçenekli bildirim. Hem FAB'a sürükle-bırak (HomeScreen) hem
/// detay sayfasındaki Sil butonu / VoiceOver "Sil" aksiyonu buradan geçer;
/// böylece geri alma davranışı her yerde aynıdır.
///
/// [item] seçim modundaki seçili öğelerden biriyse seçili tüm öğeler
/// toplu silinir (sürükle-bırak davranışıyla aynı).
Future<void> deleteFeedItemsWithUndo(
  BuildContext context,
  WidgetRef ref,
  ItemModel item,
) async {
  final repo = ref.read(itemRepositoryProvider);
  final selectedItems = ref.read(selectedItemsProvider);
  final isSelectionMode = ref.read(isSelectionModeProvider);
  final isBatchDelete = isSelectionMode && selectedItems.contains(item.id);

  final currentFeedItems = ref.read(paginatedFeedProvider).items;
  final removedItems =
      isBatchDelete
          ? currentFeedItems
              .where((feedItem) => selectedItems.contains(feedItem.id))
              .toList()
          : currentFeedItems
              .where((feedItem) => feedItem.id == item.id)
              .toList();
  final removedIds =
      removedItems.map((feedItem) => feedItem.id).toSet()..add(item.id);

  ref
      .read(paginatedFeedProvider.notifier)
      .removeItemsOptimistically(removedIds);

  if (isBatchDelete) {
    ref.read(isSelectionModeProvider.notifier).state = false;
    ref.read(selectedItemsProvider.notifier).state = {};
  }

  try {
    if (isBatchDelete) {
      await repo.softDeleteItems(removedIds.toList());
    } else {
      await repo.deleteItem(item.id);
    }

    ref.invalidate(itemCountProvider);
    if (!context.mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final fallbackName = l10n.homeItemWord;
    await SuccessNotificationSheet.show(
      context,
      title: l10n.commonDeleted,
      message:
          isBatchDelete
              ? l10n.homeBatchDeletedMessage(removedItems.length)
              : l10n.homeItemDeletedMessage(
                item.displayTitle.isEmpty ? fallbackName : item.displayTitle,
              ),
      onUndo: () async {
        ref
            .read(paginatedFeedProvider.notifier)
            .restoreItemsOptimistically(removedItems);
        try {
          await repo.restoreItems(removedIds.toList());
          ref.invalidate(itemCountProvider);
          ref.invalidate(paginatedFeedProvider);
        } catch (error) {
          ref
              .read(paginatedFeedProvider.notifier)
              .removeItemsOptimistically(removedIds);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  FailureMapper.toUserMessage(
                    error,
                    AppLocalizations.of(context),
                  ),
                ),
              ),
            );
          }
        }
      },
    );
  } catch (error) {
    ref
        .read(paginatedFeedProvider.notifier)
        .restoreItemsOptimistically(removedItems);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          FailureMapper.toUserMessage(error, AppLocalizations.of(context)),
        ),
      ),
    );
  } finally {
    ref.invalidate(paginatedFeedProvider);
    ref.invalidate(itemCountProvider);
  }
}
