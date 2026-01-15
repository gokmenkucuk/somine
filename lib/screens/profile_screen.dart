import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:animate_do/animate_do.dart';
import 'package:somine_app/screens/recently_deleted_screen.dart';
import 'package:somine_app/screens/appearance_screen.dart';
import 'package:somine_app/screens/login_screen.dart';
import 'package:somine_app/core/repositories/auth_repository.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            // --- CUSTOM HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Right Actions (Share)
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceWhite,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.premiumShadow.withOpacity(0.05), // Subtle shadow for secondary action
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(CupertinoIcons.share, size: 22, color: context.colors.headline),
                    ),
                  ),
                ],
              ),
            ),

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
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [context.colors.primary, context.colors.secondary], // Oil Green
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: context.colors.primary.withOpacity(0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const CircleAvatar(
                                radius: 55,
                                backgroundImage: NetworkImage(
                                  'https://picsum.photos/seed/avatar_gokmen/200/200',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Name
                          Text(
                            "Gökmen Küçük",
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
                                "It is so mine!",
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
                            _buildStatItem(context, "İçerik", "142"),
                            _buildVerticalDivider(context),
                            _buildStatItem(context, "Koleksiyon", "12"),
                            _buildVerticalDivider(context),
                            _buildStatItem(context, "Favori", "5"),
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
                                icon: CupertinoIcons.person,
                                title: "Hesap Bilgileri",
                                onTap: () {},
                              ),
                              _buildDivider(context),
                              _buildMenuItem(
                                context,
                                icon: CupertinoIcons.paintbrush,
                                title: "Görünüm & App İkonu",
                                badge: "YENİ",
                                badgeColor: Colors.blue,
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
                          _buildMembershipCard(context, isPro: true), // Mock PRO status

                          const SizedBox(height: 20),

                          // Group 2: Content & Settings
                          _buildMenuSection(
                            context,
                            children: [
                              _buildMenuItem(
                                context,
                                icon: CupertinoIcons.trash,
                                title: "Son Silinenler",
                                badge: "3",
                                badgeColor: Colors.redAccent,
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
                                icon: CupertinoIcons.bell,
                                title: "Bildirim Ayarları",
                                onTap: () {},
                              ),
                              _buildDivider(context),
                              _buildMenuItem(
                                context,
                                icon: CupertinoIcons.arrow_down_doc,
                                title: "Yer İmlerini İçe Aktar",
                                onTap: () {
                                  // Mock Import Action
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "İçe aktarma penceresi açılıyor...",
                                      ),
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
                                onTap: () {},
                              ),
                              _buildDivider(context),
                              _buildMenuItem(
                                context,
                                icon: CupertinoIcons.question_circle,
                                title: "Yardım ve Destek",
                                onTap: () {},
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

  Widget _buildMembershipCard(BuildContext context, {required bool isPro}) {
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
          onTap: () {}, // Handle Tap
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
                          isPro ? "PRO ÜYE" : "STANDART",
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

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.colors.headline,
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
}
