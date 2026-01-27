import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/app_theme.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/theme_provider.dart';
import 'package:somine_app/core/design/app_theme.dart';
import 'package:somine_app/core/services/share_service.dart';
import 'package:somine_app/screens/home_screen.dart';
import 'package:somine_app/screens/login_screen.dart';
import 'package:somine_app/screens/splash_screen.dart';
import 'package:somine_app/firebase_options.dart';
import 'package:somine_app/widgets/loading_indicator.dart';
import 'package:somine_app/widgets/somine_loading_widget.dart';
import 'package:somine_app/screens/onboarding_name_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:somine_app/core/utils/native_logger.dart';

import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Lock orientation to Portrait
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    await initializeDateFormatting('tr', null);
    timeago.setLocaleMessages('tr', timeago.TrMessages());
    timeago.setDefaultLocale('tr');
    
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      
      debugPrint('Firebase & Crashlytics initialized successfully');
    } catch (e, stack) {
      debugPrint('Firebase initialization error: $e');
    }

    // Initialize Share Service AFTER Firebase and with error handling
    try {
      ShareService().initialize();
      debugPrint('ShareService initialized successfully');
    } catch (e, stack) {
      debugPrint('ShareService initialization error: $e');
    }

    // Print native logs from previous run (Crash debugging)
    NativeLogger.printNativeLogs();
    
    runApp(
      const ProviderScope(
        child: SoMineApp(),
      ),
    );
  }, (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
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
    // Share handling moved to HomeScreen to ensure auth & data is ready
  }

  void _onSplashComplete() {
    setState(() => _isSplashFinished = true);
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeProvider);

    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'So Mine', 
      theme: AppTheme.getTheme(currentTheme),
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('tr', ''),
        Locale('en', ''),
      ],
      home: _isSplashFinished
          ? const AuthWrapper()
          : SplashScreen(
              onAnimationComplete: _onSplashComplete,
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




