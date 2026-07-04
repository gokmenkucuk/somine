import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/navigation_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(SoMineTokens.spacingL),
                child: Text(
                  l10n.settingsHeaderProfile,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),

            // Profil kartı
            SliverToBoxAdapter(
              child: _ProfileCard(user: user, l10n: l10n),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: SoMineTokens.spacingSection),
            ),

            // Ayarlar listesi
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SoMineTokens.spacingL,
                ),
                child: Text(
                  l10n.settingsSectionSettings,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SoMineTokens.textSecondary,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: SoMineTokens.spacingM),
            ),

            SliverToBoxAdapter(
              child: _SettingsSection(
                items: [
                  _SettingsItem(
                    icon: Icons.notifications_outlined,
                    title: l10n.settingsNotificationsTitle,
                    subtitle: l10n.settingsNotificationsSubtitle,
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    title: l10n.settingsAppearanceTitle,
                    subtitle: l10n.settingsAppearanceSubtitle,
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.cloud_outlined,
                    title: l10n.settingsBackupTitle,
                    subtitle: l10n.settingsBackupSubtitle,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: SoMineTokens.spacingXXL),
            ),

            // Destek
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SoMineTokens.spacingL,
                ),
                child: Text(
                  l10n.settingsSectionSupport,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: SoMineTokens.textSecondary,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: SoMineTokens.spacingM),
            ),

            SliverToBoxAdapter(
              child: _SettingsSection(
                items: [
                  _SettingsItem(
                    icon: Icons.help_outline_rounded,
                    title: l10n.settingsHelpCenter,
                    onTap: () => _launchUrl('https://somine.app/help'),
                  ),
                  _SettingsItem(
                    icon: Icons.mail_outline_rounded,
                    title: l10n.settingsSendFeedback,
                    onTap: () => _launchUrl('mailto:hello@somine.app'),
                  ),
                  _SettingsItem(
                    icon: Icons.star_outline_rounded,
                    title: l10n.settingsRateApp,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: SoMineTokens.spacingXXL),
            ),

            // Çıkış
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SoMineTokens.spacingL,
                ),
                child: _LogoutButton(
                  label: l10n.settingsLogout,
                  onTap: () => _showLogoutDialog(context, ref, l10n),
                ),
              ),
            ),

            // Versiyon - her zaman en altta
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(SoMineTokens.spacingXXL),
                    child: Center(
                      child: Text(
                        'So Mine v1.0.0',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(height: 100), // Bottom nav bar space
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
        ),
        title: Text(l10n.settingsLogout),
        content: Text(l10n.settingsLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.settingsCancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(homeTabIndexProvider.notifier).state = 0; // Reset to Feed tab
              ref.read(authRepositoryProvider).signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: Text(l10n.settingsLogout),
          ),
        ],
      ),
    );
  }
}

/// Profil kartı
class _ProfileCard extends StatelessWidget {
  final dynamic user;
  final AppLocalizations l10n;

  const _ProfileCard({this.user, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SoMineTokens.spacingL,
      ),
      padding: const EdgeInsets.all(SoMineTokens.spacingXL),
      decoration: BoxDecoration(
        gradient: SoMineTokens.primaryGradient,
        borderRadius: BorderRadius.circular(SoMineTokens.radiusXLarge),
        boxShadow: [
          BoxShadow(
            color: SoMineTokens.accentEnd.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: user?.photoUrl != null
                ? ClipOval(
                    child: Image.network(
                      user!.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultAvatar(),
                    ),
                  )
                : _defaultAvatar(),
          ),

          const SizedBox(width: SoMineTokens.spacingL),

          // Bilgiler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.displayName ?? l10n.settingsDefaultUserName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? l10n.settingsDefaultGuestLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),

          // Düzenle butonu
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
            ),
            child: const Icon(
              Icons.edit_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultAvatar() {
    return const Icon(
      Icons.person_rounded,
      color: Colors.white,
      size: 36,
    );
  }
}

/// Ayarlar bölümü
class _SettingsSection extends StatelessWidget {
  final List<_SettingsItem> items;

  const _SettingsSection({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: SoMineTokens.spacingL,
      ),
      decoration: BoxDecoration(
        color: SoMineTokens.cardBackground,
        borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
        boxShadow: SoMineTokens.cardShadow,
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;

          return Column(
            children: [
              item,
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 56 + SoMineTokens.spacingL,
                  endIndent: SoMineTokens.spacingL,
                  color: SoMineTokens.background,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

/// Tek ayar öğesi
class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
      child: Padding(
        padding: const EdgeInsets.all(SoMineTokens.spacingL),
        child: Row(
          children: [
            // İkon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: SoMineTokens.background,
                borderRadius: BorderRadius.circular(SoMineTokens.radiusMedium),
              ),
              child: Icon(
                icon,
                color: SoMineTokens.textSecondary,
                size: 20,
              ),
            ),

            const SizedBox(width: SoMineTokens.spacingL),

            // Başlık ve alt başlık
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),

            // Trailing
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: SoMineTokens.textTertiary,
                ),
          ],
        ),
      ),
    );
  }
}

/// Çıkış butonu
class _LogoutButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;

  const _LogoutButton({this.onTap, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SoMineTokens.spacingL),
        decoration: BoxDecoration(
          color: SoMineTokens.cardBackground,
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
          boxShadow: SoMineTokens.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: Colors.red.shade400,
              size: 20,
            ),
            const SizedBox(width: SoMineTokens.spacingS),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.red.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
