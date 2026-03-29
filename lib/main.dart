import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/design/app_theme.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:somine_app/core/providers/firestore_providers.dart';
import 'package:somine_app/core/providers/item_providers.dart';
import 'package:somine_app/core/providers/theme_provider.dart';
import 'package:somine_app/core/services/backend_realtime_service.dart';
import 'package:somine_app/core/services/share_service.dart';
import 'package:somine_app/screens/home_screen.dart';
import 'package:somine_app/screens/login_screen.dart';
import 'package:somine_app/screens/splash_screen.dart';
import 'package:somine_app/firebase_options.dart';
import 'package:somine_app/widgets/somine_loading_widget.dart';
import 'package:somine_app/screens/onboarding_name_screen.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:somine_app/core/services/notification_service.dart';
import 'package:somine_app/core/services/reminder_scheduler_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:async';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Lock app to portrait mode globally
      // YouTube fullscreen uses native MethodChannel to temporarily unlock
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      await initializeDateFormatting('tr', null);
      timeago.setLocaleMessages('tr', timeago.TrMessages());
      timeago.setDefaultLocale('tr');

      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        // Pass all uncaught "fatal" errors from the framework to Crashlytics
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;

        debugPrint('Firebase & Crashlytics initialized successfully');
      } catch (e) {
        debugPrint('Firebase initialization error: $e');
      }

      // Initialize Share Service AFTER Firebase and with error handling
      try {
        ShareService().initialize();
        debugPrint('ShareService initialized successfully');
      } catch (e) {
        debugPrint('ShareService initialization error: $e');
      }

      // Initialize Notification Service
      try {
        await NotificationService().initialize();
        await NotificationService().requestPermissions();
        debugPrint('NotificationService initialized successfully');

        // Reschedule existing reminders on app start
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await ReminderSchedulerService().rescheduleUserReminders(
            currentUser.uid,
          );
          debugPrint('Reminders rescheduled successfully');
        }
      } catch (e) {
        debugPrint('NotificationService initialization error: $e');
      }

      // Print native logs from previous run (Crash debugging)
      // NativeLogger.printNativeLogs();

      runApp(const ProviderScope(child: SoMineApp()));
    },
    (error, stack) =>
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true),
  );
}

class SoMineApp extends ConsumerStatefulWidget {
  const SoMineApp({super.key});

  @override
  ConsumerState<SoMineApp> createState() => _SoMineAppState();
}

class _SoMineAppState extends ConsumerState<SoMineApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final BackendRealtimeService _backendRealtimeService =
      BackendRealtimeService();
  bool _isSplashFinished = false;
  ProviderSubscription<AsyncValue<User?>>? _authStateSubscription;
  StreamSubscription<Map<String, dynamic>>? _itemsRealtimeSubscription;
  StreamSubscription<Map<String, dynamic>>? _categoriesRealtimeSubscription;

  @override
  void initState() {
    super.initState();
    // Share handling moved to HomeScreen to ensure auth & data is ready
    // Pass navigator key and user ID to NotificationService for notification tap handling
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        NotificationService().setCurrentUser(user.uid);
      }
      NotificationService().setNavigatorKey(_navigatorKey);
    });

    _itemsRealtimeSubscription = _backendRealtimeService.itemsChanges.listen((
      _,
    ) {
      _refreshDerivedItemState();
    });
    _categoriesRealtimeSubscription =
        _backendRealtimeService.categoriesChanges.listen((_) {
          _refreshDerivedCategoryState();
        });
    _authStateSubscription = ref.listenManual<AsyncValue<User?>>(
      authStateProvider,
      (_, next) {
        final user = next.valueOrNull;
        if (user == null) {
          unawaited(_backendRealtimeService.disconnect());
          return;
        }

        unawaited(_backendRealtimeService.connectForCurrentUser());
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _authStateSubscription?.close();
    _itemsRealtimeSubscription?.cancel();
    _categoriesRealtimeSubscription?.cancel();
    super.dispose();
  }

  void _onSplashComplete() {
    setState(() => _isSplashFinished = true);
  }

  void _refreshDerivedItemState() {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      return;
    }

    ref.invalidate(favoriteItemsProvider);
    ref.invalidate(deletedItemsProvider);
    ref.invalidate(itemCountProvider);
    ref.invalidate(uncategorizedCountProvider(user.uid));
    ref.invalidate(paginatedFeedProvider);
  }

  void _refreshDerivedCategoryState() {
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      return;
    }

    ref.invalidate(uncategorizedCountProvider(user.uid));
    ref.invalidate(paginatedFeedProvider);
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
      supportedLocales: const [Locale('tr', ''), Locale('en', '')],
      home:
          _isSplashFinished
              ? const AuthWrapper()
              : SplashScreen(onAnimationComplete: _onSplashComplete),
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
          if (isOnboarding) return const SoMineLoadingWidget();

          final userModelAsync = ref.watch(currentUserModelProvider);
          return userModelAsync.when(
            data: (userModel) {
              final hasUsername =
                  userModel?.username != null &&
                  userModel!.username!.isNotEmpty;
              final hasName =
                  userModel?.displayName != null &&
                  userModel!.displayName!.isNotEmpty;

              if (hasUsername && hasName) {
                return const HomeScreen();
              }

              return OnboardingNameScreen(userId: user.uid);
            },
            loading: () => const SoMineLoadingWidget(),
            error: (_, __) => OnboardingNameScreen(userId: user.uid),
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
      error:
          (error, stack) => Scaffold(body: Center(child: Text('Hata: $error'))),
    );
  }
}
