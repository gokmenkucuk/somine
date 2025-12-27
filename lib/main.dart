import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/app_theme.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/services/share_service.dart';
import 'package:somine_app/screens/capture_screen.dart';
import 'package:somine_app/screens/home_screen.dart';
import 'package:somine_app/screens/login_screen.dart';
import 'package:somine_app/screens/splash_screen.dart';
import 'package:somine_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Global error handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('Flutter Error: ${details.exception}');
  };
  
  // Platform error handling
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Platform Error: $error');
    return true;
  };
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw Exception('Firebase initialization timeout');
      },
    );
    debugPrint('Firebase initialized successfully');
  } catch (e, stack) {
    debugPrint('Firebase initialization error: $e');
    debugPrint('Stack trace: $stack');
    // Continue anyway for now
  }

  // Initialize Share Service
  ShareService().initialize();
  
  // Debug Assets
  try {
     // We need services import for rootBundle
     // But let's just use a simple try/catch around the run logic or inside the first widget?
     // Actually rootBundle is global in services.
  } catch (e) {}

  runApp(
    const ProviderScope(
      child: SoMineApp(),
    ),
  );
}

class SoMineApp extends StatefulWidget {
  const SoMineApp({super.key});

  @override
  State<SoMineApp> createState() => _SoMineAppState();
}

class _SoMineAppState extends State<SoMineApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isSplashFinished = false;

  @override
  void initState() {
    super.initState();
    ShareService().sharedUrlNotifier.addListener(_handleSharedUrl);
  }

  @override
  void dispose() {
    ShareService().sharedUrlNotifier.removeListener(_handleSharedUrl);
    super.dispose();
  }

  void _handleSharedUrl() {
    final url = ShareService().sharedUrlNotifier.value;
    if (url != null) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => CaptureScreen(url: url),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'So Mine', // Updated title
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: _isSplashFinished
          ? const AuthWrapper()
          : SplashScreen(
              onAnimationComplete: () {
                setState(() => _isSplashFinished = true);
              },
            ),
    );
  }
}

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final guestState = ref.watch(guestUserStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) return const HomeScreen();
        if (guestState.isGuest && guestState.hasPerformedAction) {
          return const LoginScreen(forceLogin: true);
        }
        if (guestState.isGuest) return const HomeScreen();
        return const LoginScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Hata: $error')),
      ),
    );
  }
}




