import 'package:flutter/material.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';

/// Görsel yüklenirken gösterilen parıltı (shimmer) yer tutucusu.
///
/// Renkler kart yüzeyinden (`surfaceWhite`) türetilir, böylece açık, koyu ve
/// vibe temalarının üçünde de karta gömülü durur. Sabit gri tonları koyu temada
/// kartın üstünde parlak beyaz bir blok olarak göründüğü için kullanılmaz.
class ImageShimmerPlaceholder extends StatefulWidget {
  const ImageShimmerPlaceholder({super.key});

  @override
  State<ImageShimmerPlaceholder> createState() =>
      _ImageShimmerPlaceholderState();
}

class _ImageShimmerPlaceholderState extends State<ImageShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = context.colors.surfaceWhite;
    final tint = context.colors.hint;
    // Yüzeyin üzerine ince bir tül: açık temada açık gri, koyu temada koyu
    // gri-mavi verir; her iki durumda da kartla aynı aileden kalır.
    final base = Color.alphaBlend(tint.withValues(alpha: 0.18), surface);
    final highlight = Color.alphaBlend(tint.withValues(alpha: 0.06), surface);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment((_animation.value - 1), 0),
              end: Alignment(_animation.value, 0),
              colors: [base, highlight, base],
            ),
          ),
        );
      },
    );
  }
}
