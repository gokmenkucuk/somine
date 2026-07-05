import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/share_model.dart';
import 'package:somine_app/core/providers/share_providers.dart';
import 'package:somine_app/widgets/success_notification_sheet.dart';
import 'package:somine_app/widgets/error_state_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class MySharesScreen extends ConsumerWidget {
  const MySharesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mySharesAsync = ref.watch(mySharesProvider);
    final l10n = AppLocalizations.of(context)!;

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
          l10n.mySharesTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: context.colors.headline,
          ),
        ),
        centerTitle: true,
      ),
      body: mySharesAsync.when(
        data: (shares) {
          if (shares.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shares.length,
            itemBuilder: (context, index) {
              return _MyShareCard(share: shares[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: l10n.sharedWithMeLoadError,
          onRetry: () => ref.invalidate(mySharesProvider),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIconsRegular.shareNetwork,
            size: 64,
            color: context.colors.iconInactive,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.mySharesEmptyTitle,
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
              l10n.mySharesEmptySubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: context.colors.body.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MyShareCard extends ConsumerWidget {
  final ShareModel share;

  const _MyShareCard({required this.share});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (share.status) {
      case ShareStatus.pending:
        statusColor = Colors.orange;
        statusText = l10n.mySharesStatusPending;
        statusIcon = PhosphorIconsRegular.clock;
        break;
      case ShareStatus.accepted:
        statusColor = Colors.green;
        statusText = l10n.shareRequestsAcceptedTitle;
        statusIcon = PhosphorIconsRegular.checkCircle;
        break;
      case ShareStatus.rejected:
        statusColor = Colors.red;
        statusText = l10n.shareRequestsRejectedTitle;
        statusIcon = PhosphorIconsRegular.xCircle;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              // Collection Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.colors.primary, context.colors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(
                    PhosphorIconsRegular.cards,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      share.categoryName,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colors.headline,
                      ),
                    ),
                    Text(
                      share.toUserEmail,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: context.colors.hint,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 14, color: statusColor),
                    const SizedBox(width: 4),
                    Text(
                      statusText,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Footer
          Row(
            children: [
              Text(
                timeago.format(share.createdAt, locale: 'tr'),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: context.colors.hint,
                ),
              ),
              const Spacer(),
              
              // Revoke Button
              TextButton.icon(
                onPressed: () => _revokeShare(context, ref),
                icon: Icon(
                  PhosphorIconsRegular.trash,
                  size: 16,
                  color: Colors.red.shade400,
                ),
                label: Text(
                  l10n.mySharesRevoke,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.red.shade400,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _revokeShare(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Center(
          child: Text(
            l10n.mySharesRevokeDialogTitle,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: context.colors.headline,
            ),
          ),
        ),
        content: Text(
          l10n.mySharesRevokeDialogMessage,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            color: context.colors.body,
            fontSize: 14,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: context.colors.surfaceWhite,
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    l10n.commonCancel,
                    style: GoogleFonts.poppins(color: context.colors.hint),
                  ),
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.mySharesRevoke,
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(shareRepositoryProvider).revokeShare(share.id!);
        if (context.mounted) {
          SuccessNotificationSheet.show(
            context,
            title: l10n.mySharesRevokedTitle,
            message: l10n.mySharesRevokedMessage,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.commonErrorWithDetail(e.toString()))),
          );
        }
      }
    }
  }
}
