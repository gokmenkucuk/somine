import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:somine_app/core/repositories/user_repository.dart';
import 'package:somine_app/core/repositories/category_repository.dart';
import 'package:somine_app/core/repositories/item_repository.dart';
import 'package:somine_app/core/repositories/share_repository.dart';
import 'package:somine_app/core/repositories/notification_repository.dart';
import 'package:somine_app/core/repositories/storage_repository.dart';
import 'package:somine_app/core/models/backend_auth_session.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';
import 'package:somine_app/core/services/metadata_service.dart';
import 'package:somine_app/core/services/push_notification_service.dart';
import 'package:somine_app/core/services/subscription_service.dart';

/// Hata kodları: UI bunları l10n metinlerine çevirir; ham `e.toString()`
/// kullanıcıya gösterilmez.
enum AuthFailureCode {
  /// Kullanıcı giriş/doğrulama sayfasını kapattı — sessizce yok sayılır.
  cancelled,
  network,

  /// Yeniden doğrulamada farklı bir hesap seçildi.
  accountMismatch,
  unknown,
}

class AuthFailure implements Exception {
  final AuthFailureCode code;
  final Object? cause;

  const AuthFailure(this.code, [this.cause]);

  bool get isCancelled => code == AuthFailureCode.cancelled;

  /// Firebase / Google / Apple hatalarını tek bir koda indirger.
  static AuthFailure from(Object error) {
    if (error is AuthFailure) return error;
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'canceled':
        case 'cancelled':
        case 'web-context-canceled':
        case 'web-context-cancelled':
          return AuthFailure(AuthFailureCode.cancelled, error);
        case 'network-request-failed':
          return AuthFailure(AuthFailureCode.network, error);
        case 'user-mismatch':
          return AuthFailure(AuthFailureCode.accountMismatch, error);
      }
    }
    if (error is PlatformException) {
      switch (error.code) {
        case 'sign_in_canceled':
        case 'canceled':
          return AuthFailure(AuthFailureCode.cancelled, error);
        case 'network_error':
          return AuthFailure(AuthFailureCode.network, error);
      }
    }
    final text = error.toString().toLowerCase();
    // ASAuthorizationError 1001 = kullanıcı iptali.
    if (text.contains('error 1001') || text.contains('canceled') ||
        text.contains('cancelled')) {
      return AuthFailure(AuthFailureCode.cancelled, error);
    }
    if (text.contains('network')) {
      return AuthFailure(AuthFailureCode.network, error);
    }
    return AuthFailure(AuthFailureCode.unknown, error);
  }

  @override
  String toString() => 'AuthFailure($code${cause != null ? ': $cause' : ''})';
}

class AuthRepository {
  final UserRepository _userRepository = UserRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final ItemRepository _itemRepository = ItemRepository();
  final ShareRepository _shareRepository = ShareRepository();
  final NotificationRepository _notificationRepository = NotificationRepository();
  final StorageRepository _storageRepository = StorageRepository();
  final BackendAuthService _backendAuthService = BackendAuthService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  FirebaseAuth get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      throw Exception('Firebase Auth not initialized: $e');
    }
  }

  // iOS Client ID from GoogleService-Info.plist
  static const String _iosClientId =
      '1056446356536-5h06gjgaukp8bfte8hrtudodkf5j1rfd.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: _iosClientId,
    scopes: ['email', 'profile'],
  );

  /// Get current user
  User? get currentUser {
    try {
      return _auth.currentUser;
    } catch (e) {
      return null;
    }
  }

  /// Get auth state stream
  Stream<User?> get authStateChanges {
    try {
      return _auth.authStateChanges();
    } catch (e) {
      return Stream.value(null);
    }
  }

  /// Get user changes stream (fires on profile update)
  Stream<User?> get userChanges async* {
    try {
      await for (final user in _auth.userChanges()) {
        if (user == null) {
          await _backendAuthService.clearSession();
          yield null;
          continue;
        }

        try {
          await _backendAuthService.ensureSession(user);
        } catch (e) {
          debugPrint('⚠️ [AuthRepository] Backend session sync failed: $e');
        }

        yield user;
      }
    } catch (e) {
      yield null;
    }
  }

  Future<BackendAuthSession?> get backendSession =>
      _backendAuthService.getStoredSession();

  Future<String?> getValidBackendAccessToken() async {
    return _backendAuthService.getValidAccessToken(firebaseUser: currentUser);
  }

  /// Sign in with Google
  Future<({UserCredential? userCredential, bool isNewUser})>
  signInWithGoogle() async {
    try {
      debugPrint('🔵 [AuthRepository] Starting Google Sign-In flow...');

      // Check if Firebase Auth is available
      try {
        FirebaseAuth.instance;
        debugPrint('✅ [AuthRepository] Firebase Auth instance available');
      } catch (e) {
        debugPrint('❌ [AuthRepository] Firebase Auth not available: $e');
        throw Exception('Firebase Auth not initialized: $e');
      }

      // Ensure clean state before signing in
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      // Trigger the authentication flow
      debugPrint('🔵 [AuthRepository] Calling GoogleSignIn.signIn()...');
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      debugPrint('🔵 [AuthRepository] GoogleSignIn.signIn() completed');

      if (googleUser == null) {
        debugPrint('⚠️ [AuthRepository] User canceled Google Sign-In');
        return (userCredential: null, isNewUser: false);
      }

      debugPrint(
        '✅ [AuthRepository] Google user obtained: ${googleUser.email}',
      );
      debugPrint('🔵 [AuthRepository] Getting authentication details...');

      // Obtain the auth details from the request
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        debugPrint(
          '❌ [AuthRepository] Failed to get Google authentication: $e',
        );
        try {
          await _googleSignIn.disconnect();
        } catch (_) {}
        throw AuthFailure.from(e);
      }

      debugPrint('✅ [AuthRepository] Google auth details obtained');

      // Create a new credential
      debugPrint('🔵 [AuthRepository] Creating Firebase credential...');
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      debugPrint('✅ [AuthRepository] Firebase credential created');

      // Sign in to Firebase with the Google credential
      debugPrint('🔵 [AuthRepository] Signing in to Firebase...');
      final userCredential = await _auth.signInWithCredential(credential);
      debugPrint('✅ [AuthRepository] Firebase sign-in successful!');
      if (kDebugMode) {
        debugPrint('   - User ID: ${userCredential.user?.uid}');
        debugPrint('   - Email: ${userCredential.user?.email}');
      }

      // Create/update user document in Firestore
      bool isNewUser = false;
      if (userCredential.user != null) {
        // _handleUserLogin hata verirse sonraki adımlar ATLANMAMALI:
        // geçici bir sunucu hatası, aboneliğin RevenueCat'e hiç
        // tanıtılmamasına yol açıyordu (bkz. 2026-08-02 premium sorunu).
        try {
          isNewUser = await _handleUserLogin(userCredential.user!);
        } catch (e) {
          debugPrint('⚠️ [AuthRepository] handleUserLogin failed: $e');
        }
        await _syncSubscriptionAfterLogin(userCredential.user!);
        await _syncBackendSessionAfterLogin(
          userCredential.user!,
          BackendIdentityProvider.google,
        );
      }

      return (userCredential: userCredential, isNewUser: isNewUser);
    } catch (e, stack) {
      debugPrint('❌ [AuthRepository] Google sign-in error: $e');
      debugPrint('❌ [AuthRepository] Stack trace: $stack');

      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      throw AuthFailure.from(e);
    }
  }

  /// Sign in with Apple
  Future<({UserCredential? userCredential, bool isNewUser})>
  signInWithApple() async {
    try {
      debugPrint('🔵 [AuthRepository] Starting Apple Sign-In flow...');

      // Create an instance of the Apple Sign In provider
      final appleProvider = AppleAuthProvider();

      // Sign in with Apple
      final userCredential = await _auth.signInWithProvider(appleProvider);
      debugPrint('✅ [AuthRepository] Apple sign-in successful!');

      if (userCredential.user != null) {
        await _ensureAppleDisplayName(userCredential.user!);
      }

      // Create/update user document in Firestore
      bool isNewUser = false;
      if (userCredential.user != null) {
        // Google akışıyla aynı gerekçe: bir adımın hatası sonrakileri kesmesin.
        try {
          isNewUser = await _handleUserLogin(userCredential.user!);
        } catch (e) {
          debugPrint('⚠️ [AuthRepository] handleUserLogin failed: $e');
        }
        await _syncSubscriptionAfterLogin(userCredential.user!);
        await _syncBackendSessionAfterLogin(
          userCredential.user!,
          BackendIdentityProvider.apple,
        );
      }

      return (userCredential: userCredential, isNewUser: isNewUser);
    } catch (e, stack) {
      debugPrint('❌ [AuthRepository] Apple sign-in error: $e');
      debugPrint('❌ [AuthRepository] Stack trace: $stack');
      throw AuthFailure.from(e);
    }
  }

  /// Apple adı yalnız ilk yetkilendirmede verir; Firebase iOS SDK bunu
  /// (credential'daki fullName ile) normalde displayName'e yazar. Yazmadıysa
  /// sağlayıcı kaydındaki adı kullanıcıya kopyalar ki onboarding'de kullanıcı
  /// adını yeniden yazmak zorunda kalmasın.
  Future<void> _ensureAppleDisplayName(User user) async {
    try {
      final current = user.displayName?.trim() ?? '';
      if (current.isNotEmpty) return;
      final fromProvider = user.providerData
          .map((p) => p.displayName?.trim() ?? '')
          .firstWhere((name) => name.isNotEmpty, orElse: () => '');
      if (fromProvider.isEmpty) return;
      await user.updateDisplayName(fromProvider);
      await user.reload();
    } catch (e) {
      debugPrint('⚠️ [AuthRepository] Apple display name sync failed: $e');
    }
  }

  /// Handle user login - create/update Firestore document
  /// Returns true if this is a new user
  Future<bool> _handleUserLogin(User firebaseUser) async {
    try {
      debugPrint('🔵 [AuthRepository] Handling user login in Firestore...');

      // Check if user already exists
      final existingUser = await _userRepository.getUser(firebaseUser.uid);
      final isNewUser = existingUser == null;

      debugPrint(
        '🔵 [AuthRepository] isNewUser: $isNewUser (existingUser: ${existingUser != null})',
      );

      // Create or update user document
      await _userRepository.createOrUpdateUser(firebaseUser);
      debugPrint('✅ [AuthRepository] User document created/updated');

      // Note: For new users, categories and demo content are now created
      // in OnboardingPrepScreen for better UX with progress display

      return isNewUser;
    } catch (e) {
      debugPrint('❌ [AuthRepository] Error handling user login: $e');
      // Don't throw - we don't want to block login if Firestore fails
      return false;
    }
  }

  /// Create demo content for new users
  // ignore: unused_element
  Future<void> _createDemoContent(
    String userId,
    List<CategoryModel> categories,
  ) async {
    try {
      debugPrint('🔵 [AuthRepository] Creating demo content for new user...');

      // Find categories
      final placesCategory = categories.firstWhere(
        (c) => c.name == 'Gitmek İstediğim Yerler',
        orElse: () => categories.first,
      );

      final musicCategory = categories.firstWhere(
        (c) => c.name == 'Dinlemek İstediğim',
        orElse: () => categories.first,
      );

      // Demo URLs with their categories
      final demoUrls = [
        {
          'url': 'https://www.instagram.com/reel/C4BRE6vIFIX/',
          'categoryId': placesCategory.id,
        },
        {
          'url': 'https://www.youtube.com/watch?v=Sf9CaRfv-BM',
          'categoryId': placesCategory.id,
        },
        {
          'url': 'https://www.youtube.com/shorts/Ah_2uDsoXQ8',
          'categoryId': placesCategory.id,
        },
        {
          'url': 'https://www.youtube.com/watch?v=i9UDD6zyCGs',
          'categoryId': musicCategory.id,
        },
        {
          'url': 'https://www.youtube.com/watch?v=Pclv31cDTTc',
          'categoryId': musicCategory.id,
        },
        {
          'url': 'https://www.youtube.com/watch?v=FkFB8f8bzbY',
          'categoryId': musicCategory.id,
        },
        {
          'url': 'https://www.youtube.com/watch?v=oD6fL4yyhDk',
          'categoryId': musicCategory.id,
        },
        {
          'url': 'https://www.youtube.com/watch?v=fR2JHaCDrMw',
          'categoryId': musicCategory.id,
        },
        {
          'url': 'https://www.youtube.com/watch?v=RP8REaM3WQ4',
          'categoryId': musicCategory.id,
        },
      ];

      final now = DateTime.now();
      int hourOffset = 0;

      for (final demo in demoUrls) {
        try {
          final url = demo['url'] as String;
          final categoryId = demo['categoryId'] as String;

          // Fetch metadata from URL
          debugPrint('🔵 [AuthRepository] Fetching metadata for: $url');
          final metadata = await MetadataService.fetchMetadata(url);

          final item = ItemModel(
            id: '',
            userId: userId,
            categoryId: categoryId,
            type: ItemType.link,
            url: url,
            ogMetadata: metadata,
            createdAt: now.subtract(Duration(hours: hourOffset)),
            updatedAt: now.subtract(Duration(hours: hourOffset)),
          );

          await _itemRepository.createItem(item);
          debugPrint(
            '✅ [AuthRepository] Demo item created: ${metadata?.title ?? url}',
          );
          hourOffset++;
        } catch (e) {
          debugPrint('⚠️ [AuthRepository] Error creating demo item: $e');
        }
      }

      debugPrint('✅ [AuthRepository] Demo content created');
    } catch (e) {
      debugPrint('⚠️ [AuthRepository] Error creating demo content: $e');
      // Don't throw - demo content is optional
    }
  }

  /// Sign out
  Future<void> signOut() async {
    debugPrint('🔵 [AuthRepository] Signing out...');

    // Push token'ı backend oturumu kapanmadan sil: çıkış yapılmış cihaza
    // bildirim gitmesin. Hata yutulur, çıkışı engellemez.
    await PushNotificationService().unregisterCurrentDevice();

    try {
      await _backendAuthService.logout();
    } catch (e) {
      debugPrint('⚠️ [AuthRepository] Backend logout error: $e');
    }

    try {
      await _subscriptionService.logout();
    } catch (e) {
      debugPrint('⚠️ [AuthRepository] Subscription logout error: $e');
    }

    // 1. Sign out from Firebase
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('⚠️ [AuthRepository] Firebase signOut error: $e');
    }

    // 2. Sign out from Google (Clear local session)
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      debugPrint('⚠️ [AuthRepository] Google signOut error: $e');
    }

    // 3. Disconnect from Google (Revoke permissions/Force picker)
    try {
      await _googleSignIn.disconnect();
    } catch (e) {
      debugPrint('⚠️ [AuthRepository] Google disconnect error: $e');
    }

    debugPrint('✅ [AuthRepository] Signed out');
  }

  /// Delete user account and all associated data
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user logged in');
      }

      // 0. Proactively reauthenticate to prevent data loss if authentication is cancelled
      String? appleAuthorizationCode;
      try {
        appleAuthorizationCode = await _reauthenticateUser(user);
        debugPrint('✅ [AuthRepository] Pre-deletion re-authentication completed');
      } catch (e) {
        debugPrint('⚠️ [AuthRepository] Re-authentication failed or cancelled: $e');
        throw AuthFailure.from(e);
      }

      final userId = user.uid;
      debugPrint('🔵 [AuthRepository] Deleting account for user: $userId');

      // 0b. Bu cihazın push token'ını sil (sunucu hesap silmede de siler;
      // bu, silme yarıda kalırsa bile cihaza bildirim gitmemesini sağlar).
      await PushNotificationService().unregisterCurrentDevice();

      // 1. Delete all user items
      try {
        await _itemRepository.deleteAllUserItems(userId);
        debugPrint('✅ [AuthRepository] User items deleted');
      } catch (e) {
        debugPrint('⚠️ [AuthRepository] Error deleting items: $e');
      }

      // 2. Delete all user categories
      try {
        await _categoryRepository.deleteAllUserCategories(userId);
        debugPrint('✅ [AuthRepository] User categories deleted');
      } catch (e) {
        debugPrint('⚠️ [AuthRepository] Error deleting categories: $e');
      }

      // 3. Delete all user shares
      try {
        await _shareRepository.deleteAllUserShares(userId);
        debugPrint('✅ [AuthRepository] User shares deleted');
      } catch (e) {
        debugPrint('⚠️ [AuthRepository] Error deleting shares: $e');
      }

      // 4. Delete all user notifications
      try {
        await _notificationRepository.deleteAllUserNotifications(userId);
        debugPrint('✅ [AuthRepository] User notifications deleted');
      } catch (e) {
        debugPrint('⚠️ [AuthRepository] Error deleting notifications: $e');
      }

      // 5. Delete all user storage files
      try {
        await _storageRepository.deleteAllUserFiles(userId);
        debugPrint('✅ [AuthRepository] User storage files deleted');
      } catch (e) {
        debugPrint('⚠️ [AuthRepository] Error deleting storage files: $e');
      }

      // 6. Sunucudaki hesabı sil (DELETE /api/users/me; verileri de siler).
      // ZORUNLU: başarısız olursa Firebase hesabını silmeden dur. Aksi halde
      // Firebase'de olmayan ama sunucuda kalan "hayalet" bir hesap oluşur ve
      // başkaları ona paylaşım gönderebilir.
      try {
        await _userRepository.deleteUser(userId);
        debugPrint('✅ [AuthRepository] User document deleted');
      } catch (e) {
        debugPrint('❌ [AuthRepository] Server account deletion failed, aborting: $e');
        rethrow;
      }

      // 7a. Sign in with Apple belirtecini iptal et (App Review 5.1.1(v)).
      // Başarısızlık silmeyi engellemez; yalnızca loglanır.
      if (appleAuthorizationCode != null && appleAuthorizationCode.isNotEmpty) {
        try {
          await _auth.revokeTokenWithAuthorizationCode(appleAuthorizationCode);
          debugPrint('✅ [AuthRepository] Apple token revoked');
        } catch (e) {
          debugPrint('⚠️ [AuthRepository] Apple token revoke failed: $e');
        }
      }

      // 7. Delete Firebase Auth account
      try {
        await user.delete();
        debugPrint('✅ [AuthRepository] Firebase Auth account deleted');
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          // Fallback if somehow it still requires login despite proactive reauth
          try {
            await _reauthenticateUser(user);
          } catch (reauthError) {
            throw AuthFailure.from(reauthError);
          }
          await user.delete();
        } else {
          throw AuthFailure.from(e);
        }
      }

      // 8a. Silinen hesabın abonelik/backend oturumu cihazda kalmasın.
      try {
        await _subscriptionService.logout();
      } catch (e) {
        debugPrint('⚠️ [AuthRepository] Subscription logout error: $e');
      }
      try {
        await _backendAuthService.clearSession();
      } catch (e) {
        debugPrint('⚠️ [AuthRepository] Backend session clear error: $e');
      }

      // 8. Clean up Google Sign In (after successful deletion)
      try {
        await _googleSignIn.signOut();
        await _googleSignIn.disconnect();
      } catch (e) {
        debugPrint('⚠️ [AuthRepository] Google signOut error: $e');
      }
    } catch (e) {
      debugPrint('❌ [AuthRepository] Error deleting account: $e');
      rethrow;
    }
  }

  /// Reauthenticate user before sensitive operations.
  ///
  /// Apple sağlayıcısında, belirteç iptali için kullanılacak
  /// `authorizationCode` döner (diğer sağlayıcılarda null).
  Future<String?> _reauthenticateUser(User user) async {
    try {
      // Check which provider the user used
      final providerData = user.providerData;
      if (providerData.isEmpty) {
        debugPrint(
          '⚠️ [AuthRepository] No provider data, skipping reauthentication',
        );
        return null;
      }

      final providerId = providerData.first.providerId;
      debugPrint(
        '🔵 [AuthRepository] Reauthenticating with provider: $providerId',
      );

      if (providerId == 'google.com') {
        // Force account selection by signing out first
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
        
        // Reauthenticate with Google
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw const AuthFailure(AuthFailureCode.cancelled);
        }
        final googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await user.reauthenticateWithCredential(credential);
        debugPrint('✅ [AuthRepository] Google reauthentication successful');
        return null;
      } else if (providerId == 'apple.com') {
        // Reauthenticate with Apple
        final appleProvider = AppleAuthProvider();
        final result = await user.reauthenticateWithProvider(appleProvider);
        debugPrint('✅ [AuthRepository] Apple reauthentication successful');
        return result.additionalUserInfo?.authorizationCode;
      } else {
        debugPrint('⚠️ [AuthRepository] Unknown provider: $providerId');
        return null;
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [AuthRepository] Reauthentication error: $e');
      throw AuthFailure.from(e);
    } catch (e) {
      debugPrint('❌ [AuthRepository] Reauthentication error: $e');
      rethrow;
    }
  }

  Future<void> _syncBackendSessionAfterLogin(
    User firebaseUser,
    BackendIdentityProvider provider,
  ) async {
    // Önceki hesaptan kalan hata sayacı yeni girişi bloklamasın.
    _backendAuthService.resetFailureState();
    try {
      await _backendAuthService.ensureSession(
        firebaseUser,
        provider: provider,
        forceRefresh: true,
      );
      debugPrint('✅ [AuthRepository] Backend session created');
    } catch (e) {
      debugPrint('⚠️ [AuthRepository] Backend session creation failed: $e');
    }
  }

  Future<void> _syncSubscriptionAfterLogin(User firebaseUser) async {
    try {
      await _subscriptionService.setUserId(firebaseUser.uid);
    } catch (e) {
      debugPrint('⚠️ [AuthRepository] Subscription sync failed: $e');
    }
  }
}
