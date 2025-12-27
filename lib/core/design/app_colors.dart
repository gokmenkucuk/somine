import 'package:flutter/material.dart';

class AppColors {
  // 1. ZEMİN (GRADIENTS)
  static const Color backgroundTop = Color(0xFFFFFFFF);
  static const Color backgroundBottom = Color(0xFFE8F1EF);
  
  // 2. MARKA (BRAND)
  static const Color primary = Color(0xFF6E8E91); // Derin Adaçayı
  static const Color secondary = Color(0xFFD8E2DC); // Sis Yeşili
  static const Color accentDark = Color(0xFF323736); // Koyu Kömür (Floating Btn)

  // 3. YAZI (TEXT)
  static const Color headline = Color(0xFF2D312F); // Mat Antrasit
  static const Color body = Color(0xFF636E72); // Taş Grisi
  static const Color hint = Color(0xFFB2BEC3); // Gümüş

  // 4. İKONLAR & YÜZEYLER
  static const Color iconActive = Color(0xFF6E8E91);
  static const Color iconInactive = Color(0xFF949B99);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  
  // 5. GÖLGE (SHADOW)
  static Color premiumShadow = const Color(0xFF6E8E91).withValues(alpha: 0.15);

  // 6. SOSYAL MEDYA (MUTED)
  static const Color youtube = Color(0xFFFF6B6B);
  static const Color instagram = Color(0xFFC13584);
}
