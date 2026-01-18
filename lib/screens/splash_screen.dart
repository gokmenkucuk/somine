import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:somine_app/widgets/somine_loading_widget.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const SplashScreen({super.key, required this.onAnimationComplete});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Simulate minimum splash duration
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onAnimationComplete();
      }
    });

    // Set Status Bar is handled by AppTheme now to ensure consistency
    // SystemChrome.setSystemUIOverlayStyle removed
  }

  @override
  Widget build(BuildContext context) {
    return const SoMineLoadingWidget();
  }
}
