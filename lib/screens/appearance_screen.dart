
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/providers/theme_provider.dart';
import 'package:somine_app/widgets/vibe_background.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);
    final isVibe = currentTheme == AppThemeEnum.vibe;

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
            ),

            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                   Icon(PhosphorIconsRegular.info, color: Colors.grey),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       "Uygulama ikonu değişikliği de yakında eklenecektir.",
                       style: GoogleFonts.outfit(color: Colors.grey),
                     ),
                   ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with VibeBackground when Vibe theme is active
    return isVibe ? VibeBackground(child: content) : content;
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
  }) {
    final isSelected = theme == currentTheme;

    return GestureDetector(
      onTap: () {
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
              if (isSelected)
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
