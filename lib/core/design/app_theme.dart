import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'design_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: DesignTokens.background,
      colorScheme: ColorScheme.light(
        primary: DesignTokens.primary,
        secondary: const Color(0xFF2DD4BF), // Turquoise from gradient
        surface: DesignTokens.surface,
        error: Colors.red,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: DesignTokens.textPrimary,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
        ThemeData.light().textTheme.apply(
          bodyColor: DesignTokens.textPrimary,
          displayColor: DesignTokens.textPrimary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.textPrimary),
        titleTextStyle: GoogleFonts.poppins(
          color: DesignTokens.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardTheme(
        color: DesignTokens.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.radiusMD),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DesignTokens.surface,
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
          borderSide: const BorderSide(color: DesignTokens.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DesignTokens.spacingMD,
          vertical: DesignTokens.spacingMD,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DesignTokens.primary,
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
          foregroundColor: DesignTokens.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

