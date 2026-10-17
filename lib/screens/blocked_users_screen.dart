import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/blocked_user_model.dart';
import 'package:somine_app/core/providers/share_providers.dart';
import 'package:somine_app/core/utils/relative_time.dart';
import 'package:somine_app/widgets/error_state_widget.dart';
import 'package:somine_app/widgets/share_moderation_sheets.dart';

/// Engellenen kullanıcılar ve engel kaldırma (App Store 1.2).
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final blockedAsync = ref.watch(blockedUsersProvider);

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
          l10n.ugcBlockedUsersTitle,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: context.colors.headline,
          ),
        ),
        centerTitle: true,
      ),
      body: blockedAsync.when(
        data: (users) {
          if (users.isEmpty) return _buildEmptyState(context);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(blockedUsersProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder:
                  (context, index) => _BlockedUserRow(user: users[index]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, _) => ErrorStateWidget(
              message: l10n.ugcBlockedUsersLoadError,
              onRetry: () => ref.invalidate(blockedUsersProvider),
            ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              PhosphorIconsRegular.prohibit,
              size: 64,
              color: context.colors.iconInactive,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.ugcBlockedUsersEmptyTitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.colors.headline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.ugcBlockedUsersEmptySubtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: context.colors.body.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedUserRow extends ConsumerStatefulWidget {
  const _BlockedUserRow({required this.user});

  final BlockedUserModel user;

  @override
  ConsumerState<_BlockedUserRow> createState() => _BlockedUserRowState();
}

class _BlockedUserRowState extends ConsumerState<_BlockedUserRow> {
  bool _busy = false;

  Future<void> _unblock(String name) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await ShareModerationSheets.confirmDestructive(
      context,
      title: l10n.ugcUnblockConfirmTitle(name),
      message: l10n.ugcUnblockConfirmMessage(name),
      confirmLabel: l10n.ugcUnblock,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    try {
      await ref.read(shareRepositoryProvider).unblockUser(widget.user.userId);
      if (!mounted) return;
      ShareModerationSheets.showMessage(context, l10n.ugcUnblockDone(name));
      ref.invalidate(blockedUsersProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ShareModerationSheets.showError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.colors;
    final name = widget.user.label ?? l10n.ugcUnknownUser;
    final initial =
        name.trim().isEmpty
            ? '?'
            : String.fromCharCode(name.trim().runes.first).toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: colors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.hint.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              initial,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.body,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colors.headline,
                  ),
                ),
                Text(
                  formatRelativeTime(context, widget.user.blockedAt),
                  style: GoogleFonts.poppins(fontSize: 12, color: colors.hint),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _busy ? null : () => _unblock(name),
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              minimumSize: const Size(44, 44),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            child:
                _busy
                    ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors.primary,
                      ),
                    )
                    : Text(
                      l10n.ugcUnblock,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                    ),
          ),
        ],
      ),
    );
  }
}
