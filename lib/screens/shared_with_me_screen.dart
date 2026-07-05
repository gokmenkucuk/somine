import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/share_model.dart';
import 'package:somine_app/core/providers/share_providers.dart';
import 'package:somine_app/screens/shared_collection_view_screen.dart';
import 'package:somine_app/widgets/error_state_widget.dart';
import 'package:timeago/timeago.dart' as timeago;

class SharedWithMeScreen extends ConsumerWidget {
  const SharedWithMeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sharedWithMeAsync = ref.watch(sharedWithMeProvider);
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
          l10n.sharedWithMeTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: context.colors.headline,
          ),
        ),
        centerTitle: true,
      ),
      body: sharedWithMeAsync.when(
        data: (shares) {
          if (shares.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: shares.length,
            itemBuilder: (context, index) {
              return _SharedCollectionCard(share: shares[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateWidget(
          message: l10n.sharedWithMeLoadError,
          onRetry: () => ref.invalidate(sharedWithMeProvider),
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
            PhosphorIconsRegular.usersThree,
            size: 64,
            color: context.colors.iconInactive,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.sharedWithMeEmptyTitle,
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
              l10n.sharedWithMeEmptySubtitle,
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

class _SharedCollectionCard extends StatelessWidget {
  final ShareModel share;

  const _SharedCollectionCard({required this.share});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SharedCollectionViewScreen(share: share),
          ),
        );
      },
      child: Container(
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
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [context.colors.primary, context.colors.secondary],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
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
                  const SizedBox(height: 2),
                  Text(
                    l10n.sharedWithMeFromUser(share.fromUserName),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: context.colors.hint,
                    ),
                  ),
                  Text(
                    timeago.format(share.acceptedAt ?? share.createdAt, locale: 'tr'),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: context.colors.hint.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            
            // Arrow
            Icon(
              CupertinoIcons.chevron_right,
              color: context.colors.hint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
