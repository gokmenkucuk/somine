import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:somine_app/core/design/design_tokens.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const SplashScreen({super.key, required this.onAnimationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 2 seconds breathing
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
       CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Start animation and listener
    _controller.repeat(reverse: true);
    
    // Simulate minimum splash duration
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onAnimationComplete();
      }
    });

    // Set Status Bar
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignTokens.surface, // Pure White
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            // Breathing Logo
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: child,
                );
              },
              child: Image.asset(
                'assets/images/logo.png',
                width: 120, // Reduced from 200 to imply sublety
                height: 120,
              ),
            ),
            const SizedBox(height: DesignTokens.spacingXL),
            // Typography
            FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  Text(
                    'So Mine.',
                    style: GoogleFonts.poppins(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: DesignTokens.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: DesignTokens.spacingXS),
                  Text(
                    'Curate your world',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: DesignTokens.textTertiary,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Bottom Padding
            const SizedBox(height: DesignTokens.spacingXXL),
          ],
        ),
      ),
    );
  }
}
