import 'package:flutter/material.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';

class CustomNoteIcon extends StatelessWidget {
  final double size;
  
  const CustomNoteIcon({
    Key? key,
    this.size = 40, // Square icon
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size, // Square for perfect centering
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.colors.primary, context.colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        // No shadow offset to maintain visual center
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Container(height: 2.5, width: double.infinity, decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(1))),
           const SizedBox(height: 4),
           Container(height: 2.5, width: double.infinity, decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(1))),
           const SizedBox(height: 4),
           Container(height: 2.5, width: size * 0.5, decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(1))),
        ],
      ),
    );
  }
}
