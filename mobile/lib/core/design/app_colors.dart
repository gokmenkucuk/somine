import 'package:flutter/material.dart';

class AppColors {
  // 1. ZEMİN (GRADIENTS)
  static const Color backgroundTop = Color(0xFFFFFFFF);
  static const Color backgroundBottom = Color(0xFFE8F1EF);
  
  // 2. MARKA (BRAND)
  static const Color primary = Color(0xFF688E8B); // Derin Adaçayı (User: End Color)
  static const Color secondary = Color(0xFF95C5C1); // Su Yeşili / Mint (User: Start Color)
  static const Color accentDark = Color(0xFF323736); // Koyu Kömür (Floating Btn)

  // 3. YAZI (TEXT)
  static const Color headline = Color(0xFF2D312F); // Mat Antrasit
  static const Color body = Color(0xFF636E72); // Taş Grisi
  /// İkincil/yardımcı METİN rengi. Beyaz üzerinde 5.49:1, #E8F1EF üzerinde
  /// 4.78:1 (WCAG AA). Eski gümüş #B2BEC3 metin olarak 1.9:1 kalıyordu.
  static const Color hint = Color(0xFF5F6B70); // Koyu Gümüş
  /// Metin OLMAYAN soluk yüzeyler (ayraç, iskelet, dekoratif dolgu) için
  /// eski gümüş ton. Metinde kullanma.
  static const Color hintSubtle = Color(0xFFB2BEC3); // Gümüş

  // 4. İKONLAR & YÜZEYLER
  static const Color iconActive = Color(0xFF6E8E91);
  static const Color iconInactive = Color(0xFF7C8482); // ≥3:1 (beyaz 3.83, zemin 3.33)
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  
  // 5. GÖLGE (SHADOW)
  static Color premiumShadow = const Color(0xFF6E8E91).withValues(alpha: 0.15);

  // 6. SEMANTİK (AYRAÇ & TEHLİKE)
  /// İnce ayraç/kenarlık: gümüşün soluk hali (~grey300 görünümü).
  static Color divider = hintSubtle.withValues(alpha: 0.4);
  /// Yıkıcı aksiyon rengi - ColorScheme.error ile aynı. Metin olarak beyazda
  /// 5.62:1; dolgu olarak üzerinde beyaz metin 5.62:1.
  static const Color danger = Color(0xFFC62828);
  /// Başarı / onay metni (beyaz 5.69, zemin 4.95).
  static const Color success = Color(0xFF2B7530);
  /// Uyarı metni (beyaz 5.51, zemin 4.79).
  static const Color warning = Color(0xFF9C5806);
  /// Bilgi metni (beyaz 5.75, zemin 5.00).
  static const Color info = Color(0xFF1565C0);

  // 7. SOSYAL MEDYA (MUTED)
  static const Color youtube = Color(0xFFFF6B6B);
  static const Color instagram = Color(0xFFC13584);
}
