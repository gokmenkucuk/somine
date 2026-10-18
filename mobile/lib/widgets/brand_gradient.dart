import 'package:flutter/material.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';

/// Marka gradyanının (primary → secondary) üzerine yazı/ikon basılan
/// yüzeyler (ekle butonu, FAB, PRO rozeti) için erişilebilir varyantı.
///
/// Temanın marka renkleri korunur; yalnızca ön plan rengiyle (temanın
/// `onPrimary`'si) kontrast eşiğini karşılamayan durak, tonu (hue) aynı
/// kalacak şekilde HSL açıklığı kaydırılarak koyulaştırılır/açılır.
/// Örn. Air temasında beyaz yazı için #688E8B→#95C5C1 (açık uçta 1.9:1)
/// gradyanı ~4.5:1'e çekilir; Midnight'ın koyu `onPrimary`'si zaten
/// yeterli olduğundan orada renkler değişmez.
class BrandGradient {
  BrandGradient._();

  /// Normal metin için WCAG AA eşiği.
  static const double textContrast = 4.5;

  /// Yalnız ikon içeren (metinsiz) kontroller için WCAG eşiği.
  static const double iconContrast = 3.0;

  /// Gradyan üzerindeki içerik rengi (Air/Vibe: beyaz, Midnight: koyu lacivert).
  static Color foreground(BuildContext context) =>
      Theme.of(context).colorScheme.onPrimary;

  /// Ön plan rengiyle [minContrast] eşiğini sağlayan gradyan durakları.
  static List<Color> colors(
    BuildContext context, {
    double minContrast = textContrast,
  }) {
    final fg = foreground(context);
    return [
      ensureContrast(context.colors.primary, fg, minContrast),
      ensureContrast(context.colors.secondary, fg, minContrast),
    ];
  }

  static LinearGradient linear(
    BuildContext context, {
    double minContrast = textContrast,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: colors(context, minContrast: minContrast),
      begin: begin,
      end: end,
    );
  }

  /// WCAG kontrast oranı.
  static double contrastRatio(Color a, Color b) {
    final la = a.computeLuminance();
    final lb = b.computeLuminance();
    final hi = la > lb ? la : lb;
    final lo = la > lb ? lb : la;
    return (hi + 0.05) / (lo + 0.05);
  }

  /// [background]'u, [foreground] ile en az [minContrast] oranı sağlanana
  /// kadar (tonu koruyarak) koyulaştırır ya da açar.
  static Color ensureContrast(
    Color background,
    Color foreground,
    double minContrast,
  ) {
    if (contrastRatio(background, foreground) >= minContrast) {
      return background;
    }
    final darken = foreground.computeLuminance() > 0.5;
    var hsl = HSLColor.fromColor(background);
    for (var i = 0; i < 100; i++) {
      final next = (hsl.lightness + (darken ? -0.01 : 0.01)).clamp(0.0, 1.0);
      hsl = hsl.withLightness(next);
      final candidate = hsl.toColor();
      if (contrastRatio(candidate, foreground) >= minContrast ||
          next == 0.0 ||
          next == 1.0) {
        return candidate;
      }
    }
    return hsl.toColor();
  }
}
