import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Native Orientation Service - "Native Gatekeeper Pattern"
/// 
/// iOS normally blocks orientation changes due to UISceneErrorDomain Code=101.
/// This service uses MethodChannel to control orientation at the native level:
/// 
/// - enableLandscape(): Unlocks the door, allows landscape rotation
/// - disableLandscape(): Locks the door, forces portrait only
/// 
/// The magic is in AppDelegate.swift which overrides
/// application(_:supportedInterfaceOrientationsFor:) and returns
/// either .allButUpsideDown or .portrait based on a boolean flag.
class OrientationService {
  static const MethodChannel _channel = MethodChannel('com.somine.app/orientation');

  /// UNLOCK: Enable landscape rotation (for YouTube fullscreen)
  /// Call this in initState() of your fullscreen video widget
  static Future<void> enableLandscape() async {
    debugPrint('🔓 OrientationService: enableLandscape() CALLED');
    try {
      await _channel.invokeMethod('enableLandscape');
      debugPrint('✅ OrientationService: Landscape ENABLED successfully');
    } catch (e) {
      debugPrint('❌ OrientationService: Failed to enable landscape - $e');
    }
  }

  /// LOCK: Disable landscape, force portrait only
  /// Call this in dispose() of your fullscreen video widget
  static Future<void> disableLandscape() async {
    debugPrint('🔒 OrientationService: disableLandscape() CALLED');
    try {
      await _channel.invokeMethod('disableLandscape');
      debugPrint('✅ OrientationService: Landscape DISABLED successfully');
    } catch (e) {
      debugPrint('❌ OrientationService: Failed to disable landscape - $e');
    }
  }

  /// LEGACY: Set orientation to landscape (backwards compatibility)
  static Future<void> setLandscape() async {
    try {
      await _channel.invokeMethod('setOrientation', 'landscape');
    } catch (e) {
      debugPrint('OrientationService: Failed to set landscape - $e');
    }
  }

  /// LEGACY: Set orientation to portrait (backwards compatibility)
  static Future<void> setPortrait() async {
    try {
      await _channel.invokeMethod('setOrientation', 'portrait');
    } catch (e) {
      debugPrint('OrientationService: Failed to set portrait - $e');
    }
  }
}
