import 'package:flutter/material.dart';
import 'package:somine_app/core/design/app_colors_extension.dart';

class CustomNoteIcon extends StatelessWidget {
  final double width;
  final double height;
  
  const CustomNoteIcon({
    Key? key,
    this.width = 48,
    this.height = 56,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.colors.primary, context.colors.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           // Lines mimicking text - White
           Container(height: 3, width: double.infinity, decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(1.5))),
           const SizedBox(height: 6),
           Container(height: 3, width: double.infinity, decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), borderRadius: BorderRadius.circular(1.5))),
           const SizedBox(height: 6),
           Container(height: 3, width: 24, decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(1.5))),
           const SizedBox(height: 6),
           Container(height: 3, width: double.infinity, decoration: BoxDecoration(color: Colors.white.withOpacity(0.5), borderRadius: BorderRadius.circular(1.5))),
        ],
      ),
    );
  }
}
