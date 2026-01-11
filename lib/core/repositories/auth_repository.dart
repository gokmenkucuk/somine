import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:somine_app/core/repositories/user_repository.dart';
import 'package:somine_app/core/repositories/category_repository.dart';

class AuthRepository {
  final UserRepository _userRepository = UserRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();

  FirebaseAuth get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      throw Exception('Firebase Auth not initialized: $e');
    }
  }
  
  // iOS Client ID from GoogleService-Info.plist
  static const String _iosClientId = '1056446356536-5h06gjgaukp8bfte8hrtudodkf5j1rfd.apps.googleusercontent.com';
  
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

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle({VoidCallback? onProcessStart}) async {
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
        return null;
      }

      // Trigger the loading indicator callback here, after successful account selection
      onProcessStart?.call();

      debugPrint('✅ [AuthRepository] Google user obtained: ${googleUser.email}');
      debugPrint('🔵 [AuthRepository] Getting authentication details...');

      // Obtain the auth details from the request
      GoogleSignInAuthentication? googleAuth;
      try {
        googleAuth = await googleUser.authentication;
      } catch (e) {
        debugPrint('❌ [AuthRepository] Failed to get Google authentication: $e');
        try {
          await _googleSignIn.disconnect(); 
        } catch (_) {}
        throw Exception('Failed to get Google authentication details: $e');
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
      debugPrint('   - User ID: ${userCredential.user?.uid}');
      debugPrint('   - Email: ${userCredential.user?.email}');

      // Create/update user document in Firestore
      if (userCredential.user != null) {
        await _handleUserLogin(userCredential.user!);
      }

      return userCredential;
    } catch (e, stack) {
      debugPrint('❌ [AuthRepository] Google sign-in error: $e');
      debugPrint('❌ [AuthRepository] Stack trace: $stack');
      
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      
      throw Exception('Google sign-in failed: $e');
    }
  }


  /// Sign in with Apple
  Future<UserCredential?> signInWithApple() async {
    try {
      debugPrint('🔵 [AuthRepository] Starting Apple Sign-In flow...');
      
      // Create an instance of the Apple Sign In provider
      final appleProvider = AppleAuthProvider();

      // Sign in with Apple
      final userCredential = await _auth.signInWithProvider(appleProvider);
      debugPrint('✅ [AuthRepository] Apple sign-in successful!');

      // Create/update user document in Firestore
      if (userCredential.user != null) {
        await _handleUserLogin(userCredential.user!);
      }

      return userCredential;
    } catch (e, stack) {
      debugPrint('❌ [AuthRepository] Apple sign-in error: $e');
      debugPrint('❌ [AuthRepository] Stack trace: $stack');
      throw Exception('Apple sign-in failed: $e');
    }
  }

  /// Handle user login - create/update Firestore document and default categories
  Future<void> _handleUserLogin(User firebaseUser) async {
    try {
      debugPrint('🔵 [AuthRepository] Handling user login in Firestore...');
      
      // Check if user already exists
      final existingUser = await _userRepository.getUser(firebaseUser.uid);
      final isNewUser = existingUser == null;

      // Create or update user document
      await _userRepository.createOrUpdateUser(firebaseUser);
      debugPrint('✅ [AuthRepository] User document created/updated');

      // If new user, create default categories
      if (isNewUser) {
        debugPrint('🔵 [AuthRepository] Creating default categories for new user...');
        await _categoryRepository.createDefaultCategories(firebaseUser.uid);
        debugPrint('✅ [AuthRepository] Default categories created');
      }
    } catch (e) {
      debugPrint('❌ [AuthRepository] Error handling user login: $e');
      // Don't throw - we don't want to block login if Firestore fails
    }
  }

  /// Sign out
  Future<void> signOut() async {
    debugPrint('🔵 [AuthRepository] Signing out...');
    
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
}
