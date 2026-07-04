import 'package:flutter/material.dart';

/// A gradient background widget for Vibe theme
/// Dark background with subtle red/pink glow
class VibeBackground extends StatelessWidget {
  final Widget child;
  
  const VibeBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0A12), // Very dark base
      child: Stack(
        children: [
          // Right side red/pink glow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, 0.3), // Top-right
                  radius: 1.0,
                  colors: [
                    const Color(0xFFC41E3A).withValues(alpha: 0.5), // Dark Red glow
                    const Color(0xFFC41E3A).withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.3, 0.7],
                ),
              ),
            ),
          ),
          
          // Subtle blue tint on left
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.8, -0.5), // Top-left
                  radius: 1.2,
                  colors: [
                    const Color(0xFF2A4A6A).withValues(alpha: 0.3), // Subtle teal/blue
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          
          // Content
          child,
        ],
      ),
    );
  }
}

/// A card with soft shadow for Vibe theme
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;
  final bool hasGradientGlow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.hasGradientGlow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white.withValues(alpha: 0.85),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
