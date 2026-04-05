
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/providers/theme_provider.dart';
import 'package:somine_app/widgets/vibe_background.dart';
import 'package:somine_app/screens/icon_picker_screen.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/core/providers/subscription_provider.dart';
import 'package:somine_app/screens/paywall_screen.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final isVibe = currentTheme == AppThemeEnum.vibe;
    final isPremium = ref.watch(isPremiumProvider);

    Widget content = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Görünüm"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "TEMA SEÇENEKLERİ",
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            
            // Air (Default)
            _buildThemeOption(
              context: context,
              ref: ref,
              theme: AppThemeEnum.air,
              currentTheme: currentTheme,
              title: "Air",
              subtitle: "Varsayılan, aydınlık ve ferah görünüm.",
              icon: PhosphorIconsRegular.sun,
              gradient: const LinearGradient(
                colors: [Color(0xFFE8F1EF), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            
            const SizedBox(height: 12),

            // Midnight
            _buildThemeOption(
              context: context,
              ref: ref,
              theme: AppThemeEnum.midnight,
              currentTheme: currentTheme,
              title: "Midnight",
              subtitle: "Karanlık mod ve neon vurgular.",
              icon: PhosphorIconsRegular.moonStars,
              gradient: const LinearGradient(
                colors: [Color(0xFF1F1F1F), Color(0xFF121212)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              isDark: true,
              isPremiumOnly: true,
              isPremium: isPremium,
            ),

            const SizedBox(height: 12),

            // Vibe
            _buildThemeOption(
              context: context,
              ref: ref,
              theme: AppThemeEnum.vibe,
              currentTheme: currentTheme,
              title: "Vibe",
              subtitle: "Koyu zemin, kırmızı ışıltı.",
              icon: PhosphorIconsRegular.sparkle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0A0A12), Color(0xFFC41E3A)], // Dark with red glow
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              isDark: true,
              isPremiumOnly: true,
              isPremium: isPremium,
            ),

            const SizedBox(height: 32),
            
            Text(
              "UYGULAMA İKONU",
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),

            InkWell(
              onTap: () {
                 Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => const IconPickerScreen()),
                 );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.colors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(PhosphorIconsFill.appWindow, color: context.colors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "İkonu Değiştir",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodyLarge?.color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Ana ekran ikonunu özelleştir.",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(PhosphorIconsBold.caretRight, color: Colors.grey.withOpacity(0.5), size: 18),
                  ],
                ),
              ),
            ),


          ],
        ),
      ),
    );

    // Wrap with VibeBackground when Vibe theme is active, otherwise use gradient
    if (isVibe) {
      return VibeBackground(child: content);
    } else {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor,
            ],
          ),
        ),
        child: content,
      );
    }
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required WidgetRef ref,
    required AppThemeEnum theme,
    required AppThemeEnum currentTheme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Gradient gradient,
    bool isDark = false,
    bool isPremiumOnly = false,
    bool isPremium = true,
  }) {
    final isSelected = theme == currentTheme;
    final isLocked = isPremiumOnly && !isPremium;

    return GestureDetector(
      onTap: () {
        if (isLocked) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => const PaywallScreen(),
          );
          return;
        }
        ref.read(themeProvider.notifier).setTheme(theme);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
            width: 2,
          ),
        ),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 28,
                color: isDark ? Colors.white : const Color(0xFF6E8E91),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIconsFill.lockKey, size: 14, color: isDark ? Colors.white70 : Colors.grey[700]),
                    ],
                  ),
                )
              else if (isSelected)
                CircleAvatar(
                  radius: 12,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.check, size: 16, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
