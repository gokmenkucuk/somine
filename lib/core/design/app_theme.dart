
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/providers/theme_provider.dart'; // Import Enum
import 'app_colors.dart';
import 'app_colors_extension.dart';
import 'design_tokens.dart';

class AppTheme {
  
  static ThemeData getTheme(AppThemeEnum mode) {
    switch (mode) {
      case AppThemeEnum.midnight:
        return _midnightTheme;
      case AppThemeEnum.vibe:
        return _vibeTheme;
      case AppThemeEnum.air:
      default:
        return _airTheme;
    }
  }

  // ================= AIR THEME (Default) =================
  static ThemeData get _airTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.backgroundTop,
      extensions: [
        AppColorsExtension(
          backgroundTop: AppColors.backgroundTop,
          backgroundBottom: AppColors.backgroundBottom,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          accentDark: AppColors.accentDark,
          headline: AppColors.headline,
          body: AppColors.body,
          hint: AppColors.hint,
          iconActive: AppColors.iconActive,
          iconInactive: AppColors.iconInactive,
          surfaceWhite: AppColors.surfaceWhite,
          premiumShadow: AppColors.premiumShadow,
        ),
      ],
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceWhite,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: AppColors.headline,
        onSurface: AppColors.headline,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(AppColors.headline, AppColors.body),
      appBarTheme: _buildAppBarTheme(AppColors.headline, brightness: Brightness.light),
      cardTheme: _buildCardTheme(AppColors.surfaceWhite),
      inputDecorationTheme: _buildInputTheme(AppColors.surfaceWhite, AppColors.primary),
      elevatedButtonTheme: _buildElevatedButtonTheme(AppColors.primary, Colors.white),
      textButtonTheme: _buildTextButtonTheme(AppColors.primary),
    );
  }

  // ================= MIDNIGHT THEME (Dark) =================
  static ThemeData get _midnightTheme {
    // Midnight Palette (Updated)
    const bgDark = Color(0xFF121212); // Keep for fallbacks
    const gradientStart = Color(0xFF2DD4BF); // Canlı Turkuaz
    const gradientEnd = Color(0xFF0EA5E9); // Okyanus Mavisi
    
    // Primary/Secondary can match the gradient or be contrast
    const primaryColor = Color(0xFF2DD4BF); 
    const secondaryColor = Color(0xFF0EA5E9);
    
    const surfaceDark = Color(0xFF1E1E1E); 
    const textLight = Color(0xFFF1F5F9); 
    const textDim = Color(0xFF94A3B8);
    const iconDim = Color(0xFF64748B);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      extensions: [
        const AppColorsExtension(
          backgroundTop: bgDark, // Reverted to Dark
          backgroundBottom: bgDark, // Reverted to Dark
          primary: primaryColor,
          secondary: secondaryColor,
          accentDark: primaryColor,
          headline: textLight,
          body: textDim,
          hint: iconDim,
          iconActive: primaryColor,
          iconInactive: iconDim,
          surfaceWhite: surfaceDark,
          premiumShadow: Colors.black54,
        ),
      ],
      colorScheme: const ColorScheme.dark(
        primary: primaryColor, // Changed from primaryAcid
        secondary: secondaryColor, // Changed from primaryAcid
        surface: surfaceDark,
        error: Color(0xFFEF4444),
        onPrimary: Color(0xFF0F172A), // Black content on acid green
        onSecondary: Color(0xFF0F172A),
        onSurface: textLight,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(textLight, textDim),
      appBarTheme: _buildAppBarTheme(textLight, brightness: Brightness.dark),
      cardTheme: _buildCardTheme(surfaceDark),
      inputDecorationTheme: _buildInputTheme(surfaceDark, primaryColor),
      elevatedButtonTheme: _buildElevatedButtonTheme(primaryColor, const Color(0xFF0F172A)),
      textButtonTheme: _buildTextButtonTheme(primaryColor),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Color(0xFF0F172A),
      ),
    );
  }

  // ================= VIBE THEME (Dark Navy to Pink/Red Gradient) =================
  static ThemeData get _vibeTheme {
    // Vibe Palette - Dark with Red/Pink accents
    const bgVibe = Color(0xFF1A2A3A); // Dark Navy
    const surfaceVibe = Color(0xFF2A3A4A); // Slightly lighter for cards
    const primaryVibe = Color(0xFFE86B8A); // Soft Red/Pink
    const secondaryVibe = Color(0xFF5A8AB5); // Blue accent
    const textLight = Color(0xFFF5F5F5); // Light text
    const textDim = Color(0xFFB0C0C8); // Dim text
    const iconDim = Color(0xFF7A9AA8);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.transparent, // Transparent for gradient
      extensions: [
        AppColorsExtension(
          backgroundTop: bgVibe,
          backgroundBottom: const Color(0xFFE8B8A8), // Light Salmon
          primary: primaryVibe,
          secondary: secondaryVibe,
          accentDark: primaryVibe,
          headline: textLight,
          body: textDim,
          hint: iconDim,
          iconActive: primaryVibe,
          iconInactive: iconDim,
          surfaceWhite: surfaceVibe,
          premiumShadow: primaryVibe.withOpacity(0.3),
        ),
      ],
      colorScheme: const ColorScheme.dark(
        primary: primaryVibe,
        secondary: secondaryVibe,
        surface: surfaceVibe,
        error: Colors.redAccent,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textLight,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(textLight, textDim),
      appBarTheme: _buildAppBarTheme(textLight, brightness: Brightness.dark),
      cardTheme: _buildCardTheme(surfaceVibe),
      inputDecorationTheme: _buildInputTheme(surfaceVibe, primaryVibe),
      elevatedButtonTheme: _buildElevatedButtonTheme(primaryVibe, Colors.white),
      textButtonTheme: _buildTextButtonTheme(primaryVibe),
    );
  }

  // ================= HELPERS (Reusing existing logic) =================

  static TextTheme _buildTextTheme(Color headlineColor, Color bodyColor) {
    return GoogleFonts.outfitTextTheme(
      ThemeData.light().textTheme.copyWith(
        displayLarge: GoogleFonts.outfit(fontSize: 57, fontWeight: FontWeight.bold, letterSpacing: -1.5, color: headlineColor),
        displayMedium: GoogleFonts.outfit(fontSize: 45, fontWeight: FontWeight.bold, letterSpacing: -1.0, color: headlineColor),
        displaySmall: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -0.8, color: headlineColor),
        headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.8, color: headlineColor),
        headlineMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.6, color: headlineColor),
        headlineSmall: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: headlineColor),
        bodyLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.normal, color: bodyColor),
        bodyMedium: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.normal, color: bodyColor),
        bodySmall: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.normal, color: bodyColor),
      ),
    );
  }

  static AppBarTheme _buildAppBarTheme(Color color, {Brightness brightness = Brightness.light}) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: color),
      titleTextStyle: GoogleFonts.poppins(
        color: color,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      systemOverlayStyle: brightness == Brightness.dark 
          ? SystemUiOverlayStyle.light // Light icons for dark backgrounds
          : SystemUiOverlayStyle.dark,  // Dark icons for light backgrounds
    );
  }

  static CardTheme _buildCardTheme(Color color) {
    return CardTheme(
      color: color,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
      ),
    );
  }

  static InputDecorationTheme _buildInputTheme(Color fillColor, Color borderColor) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        borderSide: BorderSide(color: borderColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DesignTokens.spacingMD,
        vertical: DesignTokens.spacingMD,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(Color bgColor, Color fgColor) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        foregroundColor: fgColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingLG,
          vertical: DesignTokens.spacingMD,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme(Color color) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: color,
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
