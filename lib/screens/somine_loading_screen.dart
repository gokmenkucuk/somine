import 'package:flutter/material.dart';
import 'package:somine_app/screens/home_screen.dart';
import 'package:somine_app/widgets/somine_loading_widget.dart';

/// Branded loading screen shown after login while app initializes
class SoMineLoadingScreen extends StatefulWidget {
  const SoMineLoadingScreen({super.key});

  @override
  State<SoMineLoadingScreen> createState() => _SoMineLoadingScreenState();
}

class _SoMineLoadingScreenState extends State<SoMineLoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to HomeScreen after a delay
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Wait for loading animation to show
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const SoMineLoadingWidget();
  }
}
