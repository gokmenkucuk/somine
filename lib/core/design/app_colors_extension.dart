
import 'package:flutter/material.dart';

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
    );
  }
}

// Kolay erişim için extension
extension AppThemeContextExtension on BuildContext {
  AppColorsExtension get colors => Theme.of(this).extension<AppColorsExtension>()!;
}
