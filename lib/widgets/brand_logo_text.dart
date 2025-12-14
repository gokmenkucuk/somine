import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Brand logo widget - shows logo image or text fallback
class BrandLogoText extends StatelessWidget {
  final String? text;
  final double? fontSize;
  final Color? color;
  final FontWeight? fontWeight;
  final bool useImage;
  
  const BrandLogoText({
    super.key,
    this.text,
    this.fontSize,
    this.color,
    this.fontWeight,
    this.useImage = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Try to show logo image, fallback to text
    if (useImage) {
      try {
        return Image.asset(
          'assets/images/logo.png',
          height: fontSize ?? 80,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildText(context, theme);
          },
        );
      } catch (e) {
        return _buildText(context, theme);
      }
    }
    
    return _buildText(context, theme);
  }
  
  Widget _buildText(BuildContext context, ThemeData theme) {
    return Text(
      text ?? 'So mine.',
      style: GoogleFonts.outfit(
        fontSize: fontSize ?? 24,
        fontWeight: fontWeight ?? FontWeight.w600,
        color: color ?? theme.colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
    );
  }
}

