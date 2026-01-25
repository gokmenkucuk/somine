import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/app_theme.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/theme_provider.dart';
import 'package:somine_app/core/design/app_theme.dart';
import 'package:somine_app/core/services/share_service.dart';
import 'package:somine_app/screens/add_content_screen.dart';
import 'package:somine_app/screens/home_screen.dart';
import 'package:somine_app/screens/login_screen.dart';
import 'package:somine_app/screens/splash_screen.dart';
import 'package:somine_app/firebase_options.dart';
import 'package:somine_app/widgets/loading_indicator.dart';
import 'package:somine_app/widgets/somine_loading_widget.dart';
import 'package:somine_app/screens/onboarding_name_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr', null);
  timeago.setLocaleMessages('tr', timeago.TrMessages());
  timeago.setDefaultLocale('tr');
  
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

class SoMineApp extends ConsumerStatefulWidget {
  const SoMineApp({super.key});

  @override
  ConsumerState<SoMineApp> createState() => _SoMineAppState();
}

class _SoMineAppState extends ConsumerState<SoMineApp> {
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
      // Clear immediately to prevent re-processing
      ShareService().sharedUrlNotifier.value = null;
      
      _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => AddContentScreen(initialText: url),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'So Mine', // Updated title
      theme: AppTheme.getTheme(currentTheme),
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
    final isOnboarding = ref.watch(onboardingStateProvider);
    
    // If user is in onboarding flow, don't override navigation
    if (isOnboarding) {
      return const SoMineLoadingWidget();
    }

    return authState.when(
      data: (user) {
        // 1. Authenticated User
        if (user != null) {
          // If explicit onboarding state is set, respect it
          if (isOnboarding) return const SoMineLoadingWidget();
          
          // Check Firestore for profile completion (username)
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, snapshot) {
              // While checking...
              if (snapshot.connectionState == ConnectionState.waiting) {
                 return const SoMineLoadingWidget();
              }
              
              if (snapshot.hasData && snapshot.data!.exists) {
                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final hasUsername = data != null && 
                                  data.containsKey('username') && 
                                  data['username'] != null && 
                                  (data['username'] as String).isNotEmpty;
                
                final hasName = data != null && 
                              data.containsKey('displayName') && 
                              data['displayName'] != null && 
                              (data['displayName'] as String).isNotEmpty;
                
                // If profile is complete (has username & name), go home
                if (hasUsername && hasName) {
                  return const HomeScreen();
                }
              }
              
              // If missing data, force onboarding
              return OnboardingNameScreen(userId: user.uid);
            },
          );
        }

        // 2. Unauthenticated User (Guest or Login)
        // Note: Guest mode is practically disabled/hidden in UI but logic remains just in case
        if (guestState.isGuest && guestState.hasPerformedAction) {
          return const LoginScreen(forceLogin: true);
        }
        if (guestState.isGuest) return const HomeScreen();
        
        // Default: Show Login Screen
        return const LoginScreen();
      },
      loading: () => const SoMineLoadingWidget(),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Hata: $error')),
      ),
    );
  }
}




