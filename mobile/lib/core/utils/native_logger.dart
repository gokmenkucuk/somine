import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class NativeLogger {
  static const MethodChannel _channel = MethodChannel('com.somine.app/debug');

  static Future<void> printNativeLogs() async {
    try {
      final String logs = await _channel.invokeMethod('getNativeLogs');
      debugPrint('\n=== NATIVE LOGS START ===\n');
      debugPrint(logs);
      debugPrint('\n=== NATIVE LOGS END ===\n');
      
      // Optional: Clear logs after reading
      // await _channel.invokeMethod('clearNativeLogs');
    } catch (e) {
      debugPrint('Failed to get native logs: $e');
    }
  }
}
