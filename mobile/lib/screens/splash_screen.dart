import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/widgets/somine_loading_widget.dart';

/// Açılış ekranı: yapay bekleme yok — oturum durumu çözülür çözülmez devam eder.
class SplashScreen extends ConsumerStatefulWidget {
  final VoidCallback onAnimationComplete;

  const SplashScreen({super.key, required this.onAnimationComplete});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _completed = false;

  void _complete() {
    if (_completed || !mounted) return;
    _completed = true;
    widget.onAnimationComplete();
  }

  @override
  void initState() {
    super.initState();
    // Durum zaten çözülmüşse (önbellekten) ilk kareden sonra hemen geç.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!ref.read(authStateProvider).isLoading) _complete();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      if (!next.isLoading) _complete();
    });
    return const SoMineLoadingWidget();
  }
}
