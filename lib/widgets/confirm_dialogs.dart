import 'package:flutter/cupertino.dart';

/// Yıkıcı işlemler için uygulama genelindeki iOS-yerel onay diyaloğu.
///
/// Onaylanırsa `true`, iptal edilirse `false` döner.
Future<bool> showDestructiveConfirmDialog(
  BuildContext context, {
  required String title,
  String? message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final confirmed = await showCupertinoDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder:
        (ctx) => CupertinoAlertDialog(
          title: Text(title),
          content: message == null ? null : Text(message),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(cancelLabel),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(confirmLabel),
            ),
          ],
        ),
  );
  return confirmed ?? false;
}

/// Kaydedilmemiş değişiklikler varken ekranı kapatmadan önce sorulan
/// iOS action sheet'i. "Değişiklikleri at" seçilirse `true` döner.
Future<bool> showDiscardChangesSheet(
  BuildContext context, {
  String? title,
  required String discardLabel,
  required String keepEditingLabel,
}) async {
  final discard = await showCupertinoModalPopup<bool>(
    context: context,
    builder:
        (ctx) => CupertinoActionSheet(
          title: title == null ? null : Text(title),
          actions: [
            CupertinoActionSheetAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(discardLabel),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(keepEditingLabel),
          ),
        ),
  );
  return discard ?? false;
}
