import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  static const MethodChannel _channel = MethodChannel('com.somine.app/debug');

  StreamSubscription? _intentDataStreamSubscription;
  final ValueNotifier<String?> sharedUrlNotifier = ValueNotifier<String?>(null);
  bool _isInitialized = false; // Prevent double initialization

  /// Initialize listeners for share intents (Warm Start only)
  void initialize() {
    if (_isInitialized) return; // Guard against duplicate init
    _isInitialized = true;
    
    // For sharing or opening urls/text coming from outside the app while the app is in the memory (Warm Start)
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // NOTE: We REMOVED getInitialMedia() here because it causes crashes during cold start.
    // Instead, we use checkInitialShare() which is called manually by HomeScreen when ready.
  }

  /// Manually check for shared content from App Group (Cold Start)
  Future<void> checkInitialShare() async {
    try {
      final String? jsonString = await _channel.invokeMethod('getSharedData');
      if (jsonString != null && jsonString.isNotEmpty) {
        debugPrint("ShareService: Found initial share data: $jsonString");
        
        try {
          // Parse JSON: [{"path": "...", "type": "url/text", "mimeType": ...}]
          final List<dynamic> items = jsonDecode(jsonString);
          if (items.isNotEmpty) {
             final item = items.first;
             if (item is Map<String, dynamic>) {
                final path = item['path'] as String?;
                if (path != null && path.isNotEmpty) {
                   sharedUrlNotifier.value = path;
                   
                   // Clear data from native storage after successful read
                   await _channel.invokeMethod('clearSharedData');
                }
             }
          }
        } catch (e) {
           debugPrint("ShareService parsing error: $e");
        }
      } else {
        debugPrint("ShareService: No initial share data found.");
      }
    } catch (e) {
      debugPrint("ShareService checkInitialShare error: $e");
    }
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    // We only care about text/url sharing for now
    final file = files.first;
    final content = file.path;
    
    if (content.isNotEmpty) {
      debugPrint("Received shared content: $content");
      // Pass the raw content (text/link) to the UI
      sharedUrlNotifier.value = content;
    }
  }

  /// Simple regex to extract URL from text
  String? _extractUrl(String text) {
    // Basic regex for URL extraction
    // Finds http/https URLs
    final RegExp urlRegExp = RegExp(
      r"(https?:\/\/(?:www\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|www\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\.[^\s]{2,}|https?:\/\/[a-zA-Z0-9]+\.[^\s]{2,})",
      caseSensitive: false,
    );

    final match = urlRegExp.firstMatch(text);
    if (match != null) {
      return match.group(0);
    }
    return null;
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }
}
