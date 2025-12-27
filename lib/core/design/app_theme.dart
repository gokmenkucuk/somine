import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.backgroundTop, // Was DesignTokens.background
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
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme.copyWith(
          // Büyük Başlıklar
          displayLarge: GoogleFonts.outfit(fontSize: 57, fontWeight: FontWeight.bold, letterSpacing: -1.5, color: AppColors.headline),
          displayMedium: GoogleFonts.outfit(fontSize: 45, fontWeight: FontWeight.bold, letterSpacing: -1.0, color: AppColors.headline),
          displaySmall: GoogleFonts.outfit(fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: -0.8, color: AppColors.headline),
          // Alt Başlıklar
          headlineLarge: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.8, color: AppColors.headline),
          headlineMedium: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: -0.6, color: AppColors.headline),
          headlineSmall: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -0.5, color: AppColors.headline),
          // Body
          bodyLarge: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.normal, color: AppColors.body),
          bodyMedium: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.normal, color: AppColors.body),
          bodySmall: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.normal, color: AppColors.body),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.headline),
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.headline,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.surfaceWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD), // Keeping Radius tokens
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceWhite,
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
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMD,
          vertical: DesignTokens.spacingMD,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
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
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

