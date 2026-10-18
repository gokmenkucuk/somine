import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/models/share_model.dart';
import 'package:somine_app/core/providers/share_providers.dart';
import 'package:somine_app/core/utils/failure_mapper.dart';

/// Ne yapıldığını çağırana bildirir; ekran buna göre kapanır/yenilenir.
enum ShareModerationOutcome { reported, blocked, removed }

/// Paylaşım isteğini reddederken seçilen yol.
enum ShareDeclineChoice { decline, declineAndBlock }

/// App Store Guideline 1.2 (kullanıcı üretimi içerik) kontrolleri:
/// şikâyet, engelleme ve kütüphaneden kaldırma. Paylaşılan koleksiyon ekranı
/// ve "Benimle paylaşılanlar" listesi aynı akışı kullanır.
abstract final class ShareModerationSheets {
  /// Kişi adı yoksa yerelleştirilmiş yedek ad.
  static String displayName(String? name, AppLocalizations l10n) {
    final trimmed = name?.trim();
    return trimmed == null || trimmed.isEmpty ? l10n.ugcUnknownUser : trimmed;
  }

  /// Ana işlem menüsü: Şikâyet et / Engelle / Kütüphanemden kaldır / Vazgeç.
  /// Akış tamamlanınca sonucu döndürür; vazgeçilirse ya da hata olursa null.
  /// Hata ve başarı mesajları burada (çağıranın ScaffoldMessenger'ı ile)
  /// gösterilir.
  static Future<ShareModerationOutcome?> showForShare(
    BuildContext context,
    WidgetRef ref,
    ShareModel share,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final name = displayName(share.fromUserName, l10n);

    final action = await showCupertinoModalPopup<ShareModerationOutcome>(
      context: context,
      builder:
          (sheetContext) => CupertinoActionSheet(
            title: Text(share.categoryName),
            message: Text(l10n.sharedCollectionByUser(name)),
            actions: [
              CupertinoActionSheetAction(
                onPressed:
                    () => Navigator.pop(
                      sheetContext,
                      ShareModerationOutcome.reported,
                    ),
                child: Text(l10n.ugcReportCollection),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed:
                    () => Navigator.pop(
                      sheetContext,
                      ShareModerationOutcome.blocked,
                    ),
                child: Text(l10n.ugcBlockUser(name)),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed:
                    () => Navigator.pop(
                      sheetContext,
                      ShareModerationOutcome.removed,
                    ),
                child: Text(l10n.ugcRemoveFromLibrary),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(sheetContext),
              child: Text(l10n.ugcCancel),
            ),
          ),
    );

    if (action == null || !context.mounted) return null;

    return switch (action) {
      ShareModerationOutcome.reported => _report(context, ref, share, name),
      ShareModerationOutcome.blocked => _block(context, ref, share, name),
      ShareModerationOutcome.removed => _remove(context, ref, share, name),
    };
  }

  /// Reddetme seçenekleri: Reddet / Reddet ve engelle / Vazgeç.
  static Future<ShareDeclineChoice?> pickDeclineOption(
    BuildContext context, {
    required String? fromUserName,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final name = displayName(fromUserName, l10n);

    return showCupertinoModalPopup<ShareDeclineChoice>(
      context: context,
      builder:
          (sheetContext) => CupertinoActionSheet(
            title: Text(l10n.ugcDeclineSheetTitle(name)),
            message: Text(l10n.ugcDeclineSheetMessage(name)),
            actions: [
              CupertinoActionSheetAction(
                onPressed:
                    () =>
                        Navigator.pop(sheetContext, ShareDeclineChoice.decline),
                child: Text(l10n.ugcDecline),
              ),
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed:
                    () => Navigator.pop(
                      sheetContext,
                      ShareDeclineChoice.declineAndBlock,
                    ),
                child: Text(l10n.ugcDeclineAndBlock),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(sheetContext),
              child: Text(l10n.ugcCancel),
            ),
          ),
    );
  }

  /// Yıkıcı bir işlemi açıklayan onay penceresi. Onaylanırsa true.
  static Future<bool> confirmDestructive(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder:
          (dialogContext) => CupertinoAlertDialog(
            title: Text(title),
            content: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(message),
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(l10n.ugcCancel),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(confirmLabel),
              ),
            ],
          ),
    );
    return confirmed ?? false;
  }

  static void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  static void showError(BuildContext context, Object error) {
    final l10n = AppLocalizations.of(context)!;
    showMessage(context, FailureMapper.toUserMessage(error, l10n));
  }

  static Future<ShareModerationOutcome?> _report(
    BuildContext context,
    WidgetRef ref,
    ShareModel share,
    String name,
  ) async {
    final shareId = share.id;
    if (shareId == null) return null;
    final l10n = AppLocalizations.of(context)!;

    final reason = await showCupertinoModalPopup<ShareReportReason>(
      context: context,
      builder:
          (sheetContext) => CupertinoActionSheet(
            title: Text(l10n.ugcReportReasonTitle),
            message: Text(l10n.ugcReportReasonMessage(name)),
            actions: [
              for (final reason in ShareReportReason.values)
                CupertinoActionSheetAction(
                  onPressed: () => Navigator.pop(sheetContext, reason),
                  child: Text(_reasonLabel(reason, l10n)),
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(sheetContext),
              child: Text(l10n.ugcCancel),
            ),
          ),
    );

    if (reason == null || !context.mounted) return null;

    try {
      await ref.read(shareRepositoryProvider).reportShare(shareId, reason);
      if (context.mounted) showMessage(context, l10n.ugcReportThanks);
      return ShareModerationOutcome.reported;
    } catch (e) {
      if (context.mounted) showError(context, e);
      return null;
    }
  }

  static Future<ShareModerationOutcome?> _block(
    BuildContext context,
    WidgetRef ref,
    ShareModel share,
    String name,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await confirmDestructive(
      context,
      title: l10n.ugcBlockConfirmTitle(name),
      message: l10n.ugcBlockConfirmMessage(name),
      confirmLabel: l10n.ugcBlockConfirmAction,
    );
    if (!confirmed || !context.mounted) return null;

    try {
      final repository = ref.read(shareRepositoryProvider);
      if (share.fromUserId.isNotEmpty) {
        await repository.blockUser(share.fromUserId);
      } else if (share.id != null) {
        await repository.blockShareSender(share.id!);
      } else {
        return null;
      }
      if (!context.mounted) return null;
      _refreshShareLists(ref);
      showMessage(context, l10n.ugcBlockDone(name));
      return ShareModerationOutcome.blocked;
    } catch (e) {
      if (context.mounted) showError(context, e);
      return null;
    }
  }

  static Future<ShareModerationOutcome?> _remove(
    BuildContext context,
    WidgetRef ref,
    ShareModel share,
    String name,
  ) async {
    final shareId = share.id;
    if (shareId == null) return null;
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await confirmDestructive(
      context,
      title: l10n.ugcRemoveConfirmTitle,
      message: l10n.ugcRemoveConfirmMessage(share.categoryName, name),
      confirmLabel: l10n.ugcRemoveConfirmAction,
    );
    if (!confirmed || !context.mounted) return null;

    try {
      await ref.read(shareRepositoryProvider).leaveShare(shareId);
      if (!context.mounted) return null;
      _refreshShareLists(ref);
      showMessage(context, l10n.ugcRemoveDone);
      return ShareModerationOutcome.removed;
    } catch (e) {
      if (context.mounted) showError(context, e);
      return null;
    }
  }

  static void _refreshShareLists(WidgetRef ref) {
    ref.invalidate(sharedWithMeProvider);
    ref.invalidate(pendingShareRequestsProvider);
    ref.invalidate(blockedUsersProvider);
  }

  static String _reasonLabel(ShareReportReason reason, AppLocalizations l10n) {
    return switch (reason) {
      ShareReportReason.spam => l10n.ugcReasonSpam,
      ShareReportReason.inappropriate => l10n.ugcReasonInappropriate,
      ShareReportReason.harassment => l10n.ugcReasonHarassment,
      ShareReportReason.other => l10n.ugcReasonOther,
    };
  }
}
