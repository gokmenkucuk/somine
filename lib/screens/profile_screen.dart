import 'package:flutter/material.dart';
import 'package:somine_app/widgets/user_avatar.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:somine_app/screens/recently_deleted_screen.dart';
import 'package:somine_app/screens/appearance_screen.dart';
import 'package:somine_app/screens/login_screen.dart';
import 'package:somine_app/screens/account_info_screen.dart';
import 'package:somine_app/screens/notification_settings_screen.dart';
import 'package:somine_app/screens/invite_friend_screen.dart';
import 'package:somine_app/screens/help_support_screen.dart';
import 'package:somine_app/screens/my_shares_screen.dart';
import 'package:somine_app/screens/shared_with_me_screen.dart';
import 'package:somine_app/screens/share_requests_screen.dart';
import 'package:somine_app/screens/notifications_screen.dart';
import 'package:somine_app/core/repositories/auth_repository.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/providers/subscription_provider.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/providers/share_providers.dart';
import 'package:somine_app/core/providers/notification_providers.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/screens/paywall_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPro = ref.watch(isPremiumProvider);
    final itemCountAsync = ref.watch(itemCountProvider);
    final categoriesAsync = ref.watch(categoriesProvider);
    
    final itemCount = itemCountAsync.valueOrNull ?? 0;
    final collectionCount = categoriesAsync.valueOrNull?.length ?? 0;
    
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // --- CUSTOM HEADER ---
            const SizedBox(height: 12),

            // --- SCROLLABLE CONTENT ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    // --- HEADER ---
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Column(
                        children: [
                            // Avatar
                            const UserAvatar(radius: 55, showBorder: true),
                          const SizedBox(height: 16),

                          // Name
                          Text(
                            user?.displayName ?? "isimsiz",
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: context.colors.headline,
                            ),
                          ),

                          // Title / Bio
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [context.colors.primary, context.colors.secondary], // Oil Green
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                                child: Text(
                                "İşte benim dijital dünyam!",
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.white, // Required for ShaderMask
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- STATS ---
                    FadeInUp(
                      delay: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceWhite,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: context.colors.premiumShadow.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(context, "İçerik", itemCount.toString(), PhosphorIconsRegular.article),
                            _buildVerticalDivider(context),
                            _buildStatItem(context, "Koleksiyon", collectionCount.toString(), PhosphorIconsRegular.cards),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- MENU GROUPS ---
                    FadeInUp(
                      delay: const Duration(milliseconds: 300),
                      child: Column(
                        children: [
                          // Group 1: Account & Appearance
                          _buildMenuSection(
                            context,
                            children: [
                              _buildMenuItem(
                                context,
                                icon: CupertinoIcons.person_circle,
                                title: "Hesap Bilgileri",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AccountInfoScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(context),
                              _buildMenuItem(
                                context,
                                icon: CupertinoIcons.paintbrush,
                                title: "Görünüm & App İkonu",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AppearanceScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Membership Plan (Standalone Highlighted)
                          _buildMembershipCard(context, isPro: isPro, ref: ref),

                          const SizedBox(height: 20),

                          // Group: Sharing
                          _buildMenuSection(
                            context,
                            children: [
                              _buildMenuItem(
                                context,
                                icon: PhosphorIconsRegular.cards,
                                title: "Paylaştıklarım",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const MySharesScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(context),
                              _buildMenuItemWithBadge(
                                context,
                                icon: PhosphorIconsRegular.cards,
                                title: "Benimle Paylaşılanlar",
                                badgeCount: ref.watch(pendingShareRequestCountProvider),
                                onTap: () {
                                  final pendingCount = ref.read(pendingShareRequestCountProvider);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => pendingCount > 0 
                                          ? const ShareRequestsScreen()
                                          : const SharedWithMeScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(context),
                              _buildMenuItemWithBadge(
                                context,
                                icon: PhosphorIconsRegular.bell,
                                title: "Bildirimler",
                                badgeCount: ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Group 2: Content & Settings
                          _buildMenuSection(
                            context,
                            children: [
                              _buildMenuItem(
                                context,
                                icon: CupertinoIcons.trash,
                                title: "Son Silinenler",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const RecentlyDeletedScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(context),
                              _buildMenuItem(
                                context,
                                icon: CupertinoIcons.gear,
                                title: "Bildirim Ayarları",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const NotificationSettingsScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Group 3: Support
                          _buildMenuSection(
                            context,
                            children: [
                              _buildMenuItem(
                                context,
                                icon: CupertinoIcons.gift,
                                title: "Arkadaşını Davet Et",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const InviteFriendScreen(),
                                    ),
                                  );
                                },
                              ),
                              _buildDivider(context),
                              _buildMenuItem(
                                context,
                                icon: CupertinoIcons.question_circle,
                                title: "Yardım ve Destek",
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HelpSupportScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Group 4: Logout
                          Container(
                            decoration: BoxDecoration(
                              color: context.colors.surfaceWhite,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: context.colors.premiumShadow.withOpacity(0.03),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  // Show Logout Confirmation Dialog
                                  final shouldLogout = await showCupertinoDialog<bool>(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: const Text('Çıkış Yap'),
                                      content: const Text('Hesabınızdan çıkmak istediğinize emin misiniz?'),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('İptal'),
                                          onPressed: () => Navigator.pop(context, false),
                                        ),
                                        CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          child: const Text('Çıkış Yap'),
                                          onPressed: () => Navigator.pop(context, true),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldLogout == true && context.mounted) {
                                    // Perform logout
                                    await AuthRepository().signOut();

                                    // Navigate to Login Screen (replace all routes)
                                    if (context.mounted) {
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        (route) => false,
                                      );
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEE2E2), // Soft Red Bg
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.logout,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        "Çıkış Yap",
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Delete Account Button
                          Container(
                            decoration: BoxDecoration(
                              color: context.colors.surfaceWhite,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () async {
                                  // Show Delete Account Confirmation Dialog
                                  final shouldDelete = await showCupertinoDialog<bool>(
                                    context: context,
                                    builder: (context) => CupertinoAlertDialog(
                                      title: const Text('Hesabı Sil'),
                                      content: const Text(
                                        'Bu işlem geri alınamaz! Tüm verileriniz (içerikler, koleksiyonlar) kalıcı olarak silinecek. Devam etmek istiyor musunuz?'
                                      ),
                                      actions: [
                                        CupertinoDialogAction(
                                          child: const Text('İptal'),
                                          onPressed: () => Navigator.pop(context, false),
                                        ),
                                        CupertinoDialogAction(
                                          isDestructiveAction: true,
                                          child: const Text('Hesabı Sil'),
                                          onPressed: () => Navigator.pop(context, true),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (shouldDelete == true && context.mounted) {
                                    // Capture navigator before async operation
                                    final navigator = Navigator.of(context);
                                    
                                    try {
                                      // Show loading
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (context) => const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );

                                      // Perform account deletion
                                      await AuthRepository().deleteAccount();

                                      // Close loading using captured navigator
                                      navigator.pop();

                                      // Navigate to Login Screen
                                      navigator.pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                                        (route) => false,
                                      );
                                    } catch (e) {
                                      // Close loading
                                      navigator.pop();
                                      
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Hesap silinemedi: $e')),
                                        );
                                      }
                                    }
                                  }
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.delete_forever,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        "Hesabı Sil",
                                        style: GoogleFonts.outfit(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Version
                          Text(
                            "v1.0.0",
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: context.colors.hint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helpers ---

  Widget _buildMembershipCard(BuildContext context, {required bool isPro, required WidgetRef ref}) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  // Gradient like Tümü button for Midnight, solid for Air
  final backgroundGradient = isDark 
      ? LinearGradient(
          colors: [context.colors.secondary.withOpacity(0.5), context.colors.surfaceWhite],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      : LinearGradient(
          colors: [context.colors.primary, context.colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

  return Container(
    decoration: BoxDecoration(
      gradient: backgroundGradient,
      borderRadius: BorderRadius.circular(20),
      border: isDark ? Border.all(color: context.colors.secondary.withOpacity(0.3), width: 1) : null,
      boxShadow: [
        BoxShadow(
          color: isDark 
              ? context.colors.secondary.withOpacity(0.35) 
              : context.colors.primary.withOpacity(0.3),
          blurRadius: 15,
          offset: const Offset(0, 8),
        ),
      ],
    ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to Paywall
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PaywallScreen()),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Row(
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: isPro
                      ? ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Color(0xFFFFE082), Color(0xFFFFD54F)], // Bright Gold
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                          child: const Icon(
                            CupertinoIcons.star_fill,
                            color: Colors.white, // Required for ShaderMask
                            size: 24,
                          ),
                        )
                      : const Icon(
                          CupertinoIcons.star,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
                const SizedBox(width: 16),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Üyelik Planı",
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(
                          isPro ? "PREMIUM" : "STANDART",
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.white70,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.colors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: context.colors.primary),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.colors.headline,
                height: 1.1,
              ),
            ),
             Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.colors.hint,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    return Container(height: 24, width: 1, color: context.colors.hint.withOpacity(0.2));
  }

  Widget _buildMenuSection(BuildContext context, {required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.colors.premiumShadow.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.colors.hint.withOpacity(0.1),
      indent: 60, // Align with text start
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    String? badge,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Icon Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: context.colors.primary.withOpacity(0.8), size: 20),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: context.colors.headline,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: context.colors.hint,
                        ),
                      ),
                  ],
                ),
              ),

              // Right Side (Badge + Arrow)
              if (badge != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? Colors.blue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: badgeColor ?? Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemWithBadge(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int badgeCount,
    required VoidCallback onTap,
  }) {
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Icon Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: context.colors.primary.withOpacity(0.8), size: 20),
              ),
              const SizedBox(width: 16),

              // Text
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.colors.headline,
                  ),
                ),
              ),

              // Badge
              if (badgeCount > 0) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : badgeCount.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],

              const Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
