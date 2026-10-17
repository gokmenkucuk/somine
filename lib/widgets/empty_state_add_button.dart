import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';
import 'package:somine_app/widgets/brand_gradient.dart';

/// Boş durumlardaki birincil "ekle" butonu (akış ve katalog).
/// Marka rengini korur; yazı/ikon için ≥4.5:1 kontrast garanti edilir.
class EmptyStateAddButton extends StatelessWidget {
  const EmptyStateAddButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = BrandGradient.foreground(context);
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(PhosphorIconsBold.plus, size: 18, color: foreground),
      label: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      style: FilledButton.styleFrom(
        backgroundColor: BrandGradient.ensureContrast(
          context.colors.primary,
          foreground,
          BrandGradient.textContrast,
        ),
        foregroundColor: foreground,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
