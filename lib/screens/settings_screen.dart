import 'package:flutter/material.dart';
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

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(SoMineTokens.spacingL),
                child: Text(
                  'Profil',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ),

            // Profil kartı
            SliverToBoxAdapter(
              child: _ProfileCard(user: user),
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
                  'Ayarlar',
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
                    title: 'Bildirimler',
                    subtitle: 'Bildirim tercihlerini yönet',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.palette_outlined,
                    title: 'Görünüm',
                    subtitle: 'Tema ve görünüm ayarları',
                    onTap: () {},
                  ),
                  _SettingsItem(
                    icon: Icons.cloud_outlined,
                    title: 'Yedekleme',
                    subtitle: 'Verilerini yedekle ve geri yükle',
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
                  'Destek',
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
                    title: 'Yardım Merkezi',
                    onTap: () => _launchUrl('https://somine.app/help'),
                  ),
                  _SettingsItem(
                    icon: Icons.mail_outline_rounded,
                    title: 'Geri Bildirim Gönder',
                    onTap: () => _launchUrl('mailto:hello@somine.app'),
                  ),
                  _SettingsItem(
                    icon: Icons.star_outline_rounded,
                    title: 'Uygulamayı Değerlendir',
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
                  onTap: () => _showLogoutDialog(context, ref),
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

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SoMineTokens.radiusLarge),
        ),
        title: const Text('Çıkış Yap'),
        content: const Text('Hesabından çıkış yapmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
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
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

/// Profil kartı
class _ProfileCard extends StatelessWidget {
  final dynamic user;

  const _ProfileCard({this.user});

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
                  user?.displayName ?? 'Kullanıcı',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.email ?? 'Misafir',
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

  const _LogoutButton({this.onTap});

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
              'Çıkış Yap',
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
