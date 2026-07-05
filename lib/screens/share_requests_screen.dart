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
import 'package:somine_app/screens/shared_collection_view_screen.dart';
import 'package:somine_app/widgets/error_state_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class ShareRequestsScreen extends ConsumerWidget {
  const ShareRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingRequestsAsync = ref.watch(pendingShareRequestsProvider);
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
          l10n.shareRequestsTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: context.colors.headline,
          ),
        ),
        centerTitle: true,
      ),
      body: pendingRequestsAsync.when(
        data: (requests) {
          if (requests.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              return _ShareRequestCard(share: requests[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: l10n.shareRequestsLoadError,
          onRetry: () => ref.invalidate(pendingShareRequestsProvider),
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
            PhosphorIconsRegular.envelopeOpen,
            size: 64,
            color: context.colors.iconInactive,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.shareRequestsEmptyTitle,
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
              l10n.shareRequestsEmptySubtitle,
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

class _ShareRequestCard extends ConsumerWidget {
  final ShareModel share;

  const _ShareRequestCard({required this.share});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
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
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.colors.primary, context.colors.secondary],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    share.fromUserName.isNotEmpty ? share.fromUserName[0].toUpperCase() : '?',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      share.fromUserName,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.colors.headline,
                      ),
                    ),
                    Text(
                      timeago.format(share.createdAt, locale: 'tr'),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: context.colors.hint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Collection Name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: context.colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  PhosphorIconsRegular.cards,
                  size: 16,
                  color: context.colors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  share.categoryName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.colors.headline,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _rejectShare(context, ref),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey,
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    l10n.shareRequestsReject,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptShare(context, ref),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.colors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    l10n.shareRequestsAccept,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _acceptShare(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(shareRepositoryProvider).acceptShare(share.id!);

      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        SuccessNotificationSheet.show(
          context,
          title: l10n.shareRequestsAcceptedTitle,
          message: l10n.shareRequestsAcceptedMessage(share.categoryName),
        );

        // Update share status for immediate view
        final acceptedShare = share.copyWith(
          status: ShareStatus.accepted,
          acceptedAt: DateTime.now(),
        );

        // Navigate to the shared collection view
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SharedCollectionViewScreen(share: acceptedShare),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonErrorWithDetail(e.toString()))),
        );
      }
    }
  }

  Future<void> _rejectShare(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(shareRepositoryProvider).rejectShare(share.id!);
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        SuccessNotificationSheet.show(
          context,
          title: l10n.shareRequestsRejectedTitle,
          message: l10n.shareRequestsRejectedMessage,
        );
      }
    } catch (e) {
      if (context.mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.commonErrorWithDetail(e.toString()))),
        );
      }
    }
  }
}
