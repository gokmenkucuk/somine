import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/error_codes.dart' as auth_error;

enum VaultAuthResult {
  success,
  failure,
  canceled,
  error,
  unavailable
}

/// Vault service for biometric authentication (FaceID/TouchID)
class VaultService {
  static final VaultService _instance = VaultService._internal();
  factory VaultService() => _instance;
  VaultService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  
  /// Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (e) {
      debugPrint('Biometric availability check error: $e');
      return false;
    }
  }

  /// Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Get biometrics error: $e');
      return [];
    }
  }



  /// Authenticate with biometrics
  Future<VaultAuthResult> authenticate({String reason = 'Gizli kasaya erişmek için doğrulama yapın'}) async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        debugPrint('Biometric authentication not available');
        return VaultAuthResult.unavailable;
      }

      final bool success = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow passcode fallback
          useErrorDialogs: true,
        ),
      );
      
      return success ? VaultAuthResult.success : VaultAuthResult.failure;
    } on PlatformException catch (e) {
      debugPrint('Authentication error: ${e.message} Code: ${e.code}');
      if (e.code == 'UserCanceled' || e.code == 'userCanceled' || e.code == auth_error.notAvailable) {
        return VaultAuthResult.canceled;
      }
      return VaultAuthResult.error;
    }
  }

  /// Check if device supports Face ID (iOS specific)
  Future<bool> hasFaceId() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.face);
  }

  /// Check if device supports Touch ID / Fingerprint
  Future<bool> hasFingerprint() async {
    final biometrics = await getAvailableBiometrics();
    return biometrics.contains(BiometricType.fingerprint) ||
           biometrics.contains(BiometricType.strong) ||
           biometrics.contains(BiometricType.weak);
  }
}
