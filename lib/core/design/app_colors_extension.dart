
import 'package:flutter/material.dart';

import 'app_colors.dart';

@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  // 1. ZEMİN & GRADIENTS
  final Color backgroundTop;
  final Color backgroundBottom;
  
  // 2. MARKA & AKSİYON
  final Color primary;
  final Color secondary;
  final Color accentDark; // Floating Button etc.

  // 3. YAZI
  final Color headline;
  final Color body;
  final Color hint;

  // 4. İKONLAR & HEADER
  final Color iconActive;
  final Color iconInactive;
  final Color surfaceWhite; // Kart rengi

  // 5. ÖZEL
  final Color premiumShadow;

  // 6. SEMANTİK
  /// İnce ayraç / kenarlık / drag-handle rengi (Material varsayılanı yerine).
  final Color divider;

  /// Yıkıcı aksiyon (silme vb.) rengi.
  final Color danger;

  const AppColorsExtension({
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.primary,
    required this.secondary,
    required this.accentDark,
    required this.headline,
    required this.body,
    required this.hint,
    required this.iconActive,
    required this.iconInactive,
    required this.surfaceWhite,
    required this.premiumShadow,
    required this.divider,
    required this.danger,
  });

  @override
  AppColorsExtension copyWith({
    Color? backgroundTop,
    Color? backgroundBottom,
    Color? primary,
    Color? secondary,
    Color? accentDark,
    Color? headline,
    Color? body,
    Color? hint,
    Color? iconActive,
    Color? iconInactive,
    Color? surfaceWhite,
    Color? premiumShadow,
    Color? divider,
    Color? danger,
  }) {
    return AppColorsExtension(
      backgroundTop: backgroundTop ?? this.backgroundTop,
      backgroundBottom: backgroundBottom ?? this.backgroundBottom,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accentDark: accentDark ?? this.accentDark,
      headline: headline ?? this.headline,
      body: body ?? this.body,
      hint: hint ?? this.hint,
      iconActive: iconActive ?? this.iconActive,
      iconInactive: iconInactive ?? this.iconInactive,
      surfaceWhite: surfaceWhite ?? this.surfaceWhite,
      premiumShadow: premiumShadow ?? this.premiumShadow,
      divider: divider ?? this.divider,
      danger: danger ?? this.danger,
    );
  }

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) {
      return this;
    }
    return AppColorsExtension(
      backgroundTop: Color.lerp(backgroundTop, other.backgroundTop, t)!,
      backgroundBottom: Color.lerp(backgroundBottom, other.backgroundBottom, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accentDark: Color.lerp(accentDark, other.accentDark, t)!,
      headline: Color.lerp(headline, other.headline, t)!,
      body: Color.lerp(body, other.body, t)!,
      hint: Color.lerp(hint, other.hint, t)!,
      iconActive: Color.lerp(iconActive, other.iconActive, t)!,
      iconInactive: Color.lerp(iconInactive, other.iconInactive, t)!,
      surfaceWhite: Color.lerp(surfaceWhite, other.surfaceWhite, t)!,
      premiumShadow: Color.lerp(premiumShadow, other.premiumShadow, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
    );
  }

  /// Tema uzantısı bulunamadığında kullanılan varsayılan palet (air teması).
  /// Uygulamanın üç teması da uzantıyı sağlar; bu yedek yalnızca uzantısız
  /// çıplak bir [Theme] altında (ör. widget testleri) devreye girer ve
  /// widget'ların çökmesini önler.
  static final AppColorsExtension fallback = AppColorsExtension(
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
    divider: AppColors.divider,
    danger: AppColors.danger,
  );
}

// Kolay erişim için extension
extension AppThemeContextExtension on BuildContext {
  AppColorsExtension get colors =>
      Theme.of(this).extension<AppColorsExtension>() ??
      AppColorsExtension.fallback;
}
