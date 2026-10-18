import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/services/analytics_service.dart';
import 'package:somine_app/core/utils/failure_mapper.dart';
import 'package:somine_app/core/utils/public_link_url.dart';

/// Bottom sheet that lets the user pick how a collection is shared:
/// with a specific person (share request) or with a read-only public link.
class CollectionShareOptionsSheet extends ConsumerStatefulWidget {
  const CollectionShareOptionsSheet({
    super.key,
    required this.category,
    required this.onShareWithPeople,
  });

  final CategoryModel category;

  /// Invoked after this sheet is dismissed, to open the existing
  /// "share with a person" flow.
  final VoidCallback onShareWithPeople;

  static Future<void> show(
    BuildContext context, {
    required CategoryModel category,
    required VoidCallback onShareWithPeople,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => CollectionShareOptionsSheet(
            category: category,
            onShareWithPeople: onShareWithPeople,
          ),
    );
  }

  @override
  ConsumerState<CollectionShareOptionsSheet> createState() =>
      _CollectionShareOptionsSheetState();
}

class _CollectionShareOptionsSheetState
    extends ConsumerState<CollectionShareOptionsSheet> {
  String? _linkUrl;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final token = widget.category.publicLinkToken;
    if (token != null && token.isNotEmpty) {
      _linkUrl = publicLinkUrlFromToken(token);
    }
  }

  bool get _hasLink => _linkUrl?.isNotEmpty == true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.catalogShareCollection,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.headline,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.category.name,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: context.colors.body,
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionTile(
                icon: PhosphorIconsRegular.userPlus,
                title: l10n.catalogShareWithPeople,
                onTap: _isBusy ? null : _shareWithPeople,
              ),
              Divider(color: context.colors.divider),
              if (!_hasLink)
                _buildOptionTile(
                  icon: PhosphorIconsRegular.linkSimple,
                  title: l10n.catalogShareViaLink,
                  subtitle: l10n.catalogShareViaLinkDescription,
                  trailing: _isBusy ? const _TileSpinner() : null,
                  onTap: _isBusy ? null : _createAndShareLink,
                )
              else ...[
                _buildOptionTile(
                  icon: PhosphorIconsRegular.copySimple,
                  title: l10n.mySharesPublicLinkCopy,
                  subtitle: l10n.catalogShareViaLinkDescription,
                  onTap: _isBusy ? null : _copyLink,
                ),
                Divider(color: context.colors.divider),
                _buildOptionTile(
                  icon: PhosphorIconsRegular.shareNetwork,
                  title: l10n.catalogShareLinkReshare,
                  trailing: _isBusy ? const _TileSpinner() : null,
                  onTap: _isBusy ? null : _reshareLink,
                ),
                Divider(color: context.colors.divider),
                _buildOptionTile(
                  icon: PhosphorIconsRegular.linkBreak,
                  title: l10n.mySharesPublicLinkRevoke,
                  color: context.colors.danger,
                  onTap: _isBusy ? null : _revokeLink,
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? color,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? context.colors.primary).withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color ?? context.colors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: color ?? context.colors.headline,
        ),
      ),
      subtitle:
          subtitle == null
              ? null
              : Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: context.colors.hint,
                  ),
                ),
              ),
      trailing: trailing,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _shareWithPeople() {
    Navigator.pop(context);
    widget.onShareWithPeople();
  }

  Future<void> _createAndShareLink() => _shareLink(createIfMissing: true);

  Future<void> _reshareLink() => _shareLink(createIfMissing: false);

  Future<void> _shareLink({required bool createIfMissing}) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    setState(() => _isBusy = true);
    try {
      var url = _linkUrl;
      if (createIfMissing || url == null || url.isEmpty) {
        url = await ref
            .read(categoryRepositoryProvider)
            .createPublicLink(widget.category.id);
        ref.invalidate(categoriesProvider);
      }

      if (url.isEmpty) return;
      if (mounted) setState(() => _linkUrl = url);

      await SharePlus.instance.share(ShareParams(text: url));
      AnalyticsService.instance.logShareAction('public_link');
    } catch (e) {
      _closeSheet();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            FailureMapper.toUserMessage(e, l10n),
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _copyLink() async {
    final url = _linkUrl;
    if (url == null || url.isEmpty) return;

    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    await Clipboard.setData(ClipboardData(text: url));
    _closeSheet();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.mySharesPublicLinkCopied,
          style: GoogleFonts.poppins(),
        ),
      ),
    );
  }

  Future<void> _revokeLink() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Center(
              child: Text(
                l10n.mySharesPublicLinkRevokeDialogTitle,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: context.colors.headline,
                ),
              ),
            ),
            content: Text(
              l10n.mySharesPublicLinkRevokeDialogMessage,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: context.colors.body,
                fontSize: 14,
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            backgroundColor: context.colors.surfaceWhite,
            actions: [
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        l10n.commonCancel,
                        style: GoogleFonts.poppins(color: context.colors.hint),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.danger,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        l10n.mySharesPublicLinkRevoke,
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    if (mounted) setState(() => _isBusy = true);
    try {
      await ref
          .read(categoryRepositoryProvider)
          .revokePublicLink(widget.category.id);
      ref.invalidate(categoriesProvider);
      if (mounted) setState(() => _linkUrl = null);
      _closeSheet();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.mySharesPublicLinkRevoked,
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    } catch (e) {
      _closeSheet();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            FailureMapper.toUserMessage(e, l10n),
            style: GoogleFonts.poppins(),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _closeSheet() {
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}

class _TileSpinner extends StatelessWidget {
  const _TileSpinner();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: context.colors.primary,
      ),
    );
  }
}
