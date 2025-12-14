import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/screens/category_manager_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final guestState = ref.watch(guestUserStateProvider);

    return Scaffold(
      backgroundColor: DesignTokens.background,
      appBar: AppBar(
        title: Text('Ayarlar', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: DesignTokens.background,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Profile Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
                boxShadow: DesignTokens.shadowSM,
              ),
              child: Row(
                children: [
                   Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DesignTokens.background,
                        image: user?.photoURL != null 
                          ? DecorationImage(image: NetworkImage(user!.photoURL!))
                          : null,
                      ),
                      child: user?.photoURL == null 
                        ? const Icon(Icons.person, size: 30, color: DesignTokens.textTertiary)
                        : null,
                   ),
                   const SizedBox(width: 16),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(
                           user?.displayName ?? 'Misafir Kullanıcı',
                           style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                         ),
                         Text(
                           user?.email ?? 'Giriş yapılmadı',
                           style: GoogleFonts.poppins(fontSize: 14, color: DesignTokens.textSecondary),
                         ),
                       ],
                     ),
                   ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sections
            _buildSection(
              title: 'Görünüm',
              children: [
                _SettingsTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Tema',
                  subtitle: 'Aydınlık (Varsayılan)',
                  onTap: () {}, // TODO: Implement Theme Switcher
                ),
                _SettingsTile(
                  icon: Icons.category_outlined,
                  title: 'Kategorileri Yönet',
                  onTap: () {
                     Navigator.push(
                       context,
                       MaterialPageRoute(builder: (_) => const CategoryManagerScreen()),
                     );
                  },
                ),
              ],
            ),
            
            _buildSection(
              title: 'Veri',
              children: [
                 _SettingsTile(
                  icon: Icons.cloud_done_outlined,
                  title: 'Senkronizasyon',
                  subtitle: 'Bulut ile eşitlendi',
                  iconColor: Colors.green,
                  onTap: () {},
                ),
              ],
            ),
            
            _buildSection(
              title: 'Hakkında',
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Image.asset('assets/images/logo.png', width: 48, height: 48),
                      const SizedBox(height: 8),
                      Text('So Mine.', style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('v1.0.0 (Build 12)', style: GoogleFonts.poppins(color: DesignTokens.textTertiary, fontSize: 12)),
                    ],
                  ),
                ),
                _SettingsTile(
                  icon: Icons.logout,
                  title: 'Çıkış Yap',
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () async {
                    final authRepository = ref.read(authRepositoryProvider);
                    await authRepository.signOut();
                    ref.read(guestUserStateProvider.notifier).reset();
                    if (context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Text(
            title.toUpperCase(),
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: DesignTokens.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(DesignTokens.radiusLG),
            boxShadow: DesignTokens.shadowSM,
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? DesignTokens.textSecondary, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? DesignTokens.textPrimary,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: DesignTokens.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: DesignTokens.border),
          ],
        ),
      ),
    );
  }
}
