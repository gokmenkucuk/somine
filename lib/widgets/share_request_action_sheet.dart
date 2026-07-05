import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/notification_model.dart';
import 'package:somine_app/core/providers/share_providers.dart';
import 'package:somine_app/widgets/success_notification_sheet.dart';

enum _ShareRequestAction { none, accept, reject }

class ShareRequestActionSheet extends ConsumerStatefulWidget {
  const ShareRequestActionSheet({super.key, required this.notification});

  final NotificationModel notification;

  static Future<void> show(
    BuildContext context, {
    required NotificationModel notification,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => FractionallySizedBox(
            heightFactor: 0.46,
            alignment: Alignment.bottomCenter,
            child: ShareRequestActionSheet(notification: notification),
          ),
    );
  }

  @override
  ConsumerState<ShareRequestActionSheet> createState() =>
      _ShareRequestActionSheetState();
}

class _ShareRequestActionSheetState
    extends ConsumerState<ShareRequestActionSheet> {
  _ShareRequestAction _activeAction = _ShareRequestAction.none;

  bool get _isBusy => _activeAction != _ShareRequestAction.none;

  String get _shareId =>
      widget.notification.data['shareId']?.toString().trim() ?? '';

  String get _categoryName {
    final value = widget.notification.data['categoryName']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
    return AppLocalizations.of(context)!.shareRequestActionSheetDefaultCategory;
  }

  String get _fromUserName {
    final value = widget.notification.data['fromUserName']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
    return AppLocalizations.of(context)!.shareRequestActionSheetDefaultUser;
  }

  String get _userInitial {
    final normalized = _fromUserName.trim();
    if (normalized.isEmpty) {
      return AppLocalizations.of(context)!.shareRequestActionSheetDefaultInitial;
    }
    return String.fromCharCode(normalized.runes.first).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context)!;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceWhite,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: colors.hint.withValues(alpha: 0.24),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [colors.primary, colors.secondary],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _userInitial,
                              style: GoogleFonts.outfit(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.shareRequestActionSheetTitle,
                                style: GoogleFonts.outfit(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                  color: colors.headline,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.shareRequestActionSheetSubtitle(_fromUserName),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: colors.body,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.backgroundTop,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              PhosphorIconsRegular.cards,
                              color: colors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.shareRequestActionSheetSharedCollection,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: colors.hint,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _categoryName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: colors.headline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed:
                                _isBusy || _shareId.isEmpty
                                    ? null
                                    : () => _submit(_ShareRequestAction.reject),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.body,
                              side: BorderSide(
                                color: colors.hint.withValues(alpha: 0.22),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child:
                                _activeAction == _ShareRequestAction.reject
                                    ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: colors.body,
                                      ),
                                    )
                                    : Text(
                                      l10n.shareRequestsReject,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _isBusy || _shareId.isEmpty
                                    ? null
                                    : () => _submit(_ShareRequestAction.accept),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child:
                                _activeAction == _ShareRequestAction.accept
                                    ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text(
                                      l10n.shareRequestsAccept,
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed:
                          _isBusy ? null : () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: colors.hint,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: Text(
                        l10n.shareRequestActionSheetLater,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (_shareId.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          l10n.shareRequestActionSheetMissingInfo,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: colors.hint,
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit(_ShareRequestAction action) async {
    setState(() => _activeAction = action);

    try {
      final repository = ref.read(shareRepositoryProvider);
      if (action == _ShareRequestAction.accept) {
        await repository.acceptShare(_shareId);
      } else {
        await repository.rejectShare(_shareId);
      }

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      Navigator.of(context).pop(true);
      SuccessNotificationSheet.show(
        context,
        title:
            action == _ShareRequestAction.accept
                ? l10n.shareRequestsAcceptedTitle
                : l10n.shareRequestsRejectedTitle,
        message:
            action == _ShareRequestAction.accept
                ? l10n.shareRequestActionSheetAcceptedMessage(_categoryName)
                : l10n.shareRequestsRejectedMessage,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _activeAction = _ShareRequestAction.none);
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.commonErrorWithDetail(error.toString()))));
    }
  }
}
