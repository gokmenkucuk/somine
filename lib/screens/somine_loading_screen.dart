import 'package:flutter/material.dart';
import 'package:somine_app/screens/home_screen.dart';
import 'package:somine_app/widgets/somine_loading_widget.dart';

/// Branded loading screen shown after login while app initializes
class SoMineLoadingScreen extends StatefulWidget {
  final bool isNewUser;
  
  const SoMineLoadingScreen({
    super.key, 
    this.isNewUser = false,
  });

  @override
  State<SoMineLoadingScreen> createState() => _SoMineLoadingScreenState();
}

class _SoMineLoadingScreenState extends State<SoMineLoadingScreen> {
  String _message = '';

  @override
  void initState() {
    super.initState();
    
    if (widget.isNewUser) {
      _message = 'Koleksiyonlarınızı hazırlıyoruz...';
    }
    
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Wait longer for new users (demo content being created)
    final delay = widget.isNewUser 
        ? const Duration(milliseconds: 4000) 
        : const Duration(milliseconds: 1500);
    
    await Future.delayed(delay);

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
    return SoMineLoadingWidget(
      message: _message.isNotEmpty ? _message : null,
    );
  }
}
