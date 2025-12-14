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

