import 'package:flutter/material.dart';

/// Design tokens for So Mine app
/// Soft, white, creative design language
class DesignTokens {
  // Colors
  static const Color background = Color(0xFFF8F9FA); // Ghost White
  static const Color surface = Colors.white;
  static const Color primary = Color(0xFF3B82F6); // Fallback primary
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF60A5FA), Color(0xFF2DD4BF)], // Blue to Turquoise
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient floatingButtonGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2DD4BF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  
  // Border Colors
  static const Color border = Color(0xFFE5E7EB);
  
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  
  // Border Radius
  static const double radiusSM = 8.0;
  static const double radiusMD = 12.0;
  static const double radiusLG = 16.0;
  static const double radiusXL = 24.0;
  static const double radiusFull = 999.0;
  
  // Shadows
  static List<BoxShadow> get shadowSM => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get shadowMD => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 6),
    ),
  ];
  
  static List<BoxShadow> get shadowLG => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.12),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
  
  static List<BoxShadow> get shadowGlow => [
    BoxShadow(
      color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

/// New Design Tokens (v2) - Matches Task Specs
class SoMineTokens {
  // Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  static const double spacingXXL = 48.0;
  static const double spacingSection = 64.0;

  // Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusXLarge = 32.0;
  static const double radiusRound = 999.0;

  // Colors
  static const Color background = Color(0xFFF8F9FB); 
  static const Color cardBackground = Colors.white;
  static const Color textPrimary = Color(0xFF1A1E38); // Deep Navy
  static const Color textSecondary = Color(0xFF89898E);
  static const Color textTertiary = Color(0xFFB0B0B5);
  static const Color accentEnd = Color(0xFF0EA5E9);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF22D3EE), Color(0xFF0EA5E9)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<LinearGradient> showcaseGradients = [
    LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]), // Lavender
    LinearGradient(colors: [Color(0xFFFB923C), Color(0xFFFDBA74)]), // Peach
    LinearGradient(colors: [Color(0xFF34D399), Color(0xFF6EE7B7)]), // Mint
    LinearGradient(colors: [Color(0xFF60A5FA), Color(0xFF93C5FD)]), // Blue
  ];

  // Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1A1E38).withValues(alpha: 0.06),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get cardShadowElevated => [
    BoxShadow(
      color: const Color(0xFF1A1E38).withValues(alpha: 0.12),
      blurRadius: 30,
      offset: const Offset(0, 15),
    ),
  ];

  // Animation
  static const Duration animationFast = Duration(milliseconds: 200);
}
