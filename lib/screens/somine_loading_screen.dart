import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    // Yapay bekleme yok: ilk kare çizildikten hemen sonra ana ekrana geç.
    await WidgetsBinding.instance.endOfFrame;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) => const HomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 250),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SoMineLoadingWidget(
      message: widget.isNewUser ? l10n.somineLoadingPreparingCollections : null,
    );
  }
}
