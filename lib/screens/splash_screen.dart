import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:somine_app/core/design/design_tokens.dart';
import 'package:somine_app/widgets/loading_indicator.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const SplashScreen({super.key, required this.onAnimationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000), // 2 seconds breathing
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Start animation and listener
    _controller.forward();

    // Simulate minimum splash duration
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onAnimationComplete();
      }
    });

    // Set Status Bar
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: const LoadingIndicator(size: 32),
        ),
      ),
    );
  }
}
