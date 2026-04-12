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
        await _printNativeShareLogs();
        
        try {
          // Parse JSON: [{"path": "...", "type": "url/text", "mimeType": ...}]
          final List<dynamic> items = jsonDecode(jsonString);
          
          // Find first item with non-empty path (Google Maps sends multiple items)
          String? foundUrl;
          for (final item in items) {
            if (item is Map<String, dynamic>) {
              final path = item['path'] as String?;
              final type = item['type'] as String?;
              
              // Prefer URL type items, but accept any non-empty path
              if (path != null && path.isNotEmpty) {
                foundUrl = path;
                debugPrint("ShareService: Found valid path: $path (type: $type)");
                
                // If it's explicitly a URL type, use it immediately
                if (type == 'url') break;
              }
            }
          }
          
          if (foundUrl != null) {
            final extractedUrl = _extractUrl(foundUrl);
            final sharedContent = extractedUrl ?? foundUrl;
            debugPrint("ShareService: Resolved shared content: $sharedContent");
            sharedUrlNotifier.value = sharedContent;
            // Clear data from native storage after successful read
            await _channel.invokeMethod('clearSharedData');
          }
        } catch (e) {
           debugPrint("ShareService parsing error: $e");
        }
      } else {
        debugPrint("ShareService: No initial share data found.");
        await _printNativeShareLogs();
      }
    } catch (e) {
      debugPrint("ShareService checkInitialShare error: $e");
    }
  }

  Future<void> _printNativeShareLogs() async {
    try {
      final String logs = await _channel.invokeMethod('getNativeLogs');
      if (logs.contains('[SHARE_EXT]')) {
        debugPrint('\n=== SHARE EXTENSION LOGS START ===\n$logs\n=== SHARE EXTENSION LOGS END ===\n');
      }
    } catch (e) {
      debugPrint("ShareService native log read error: $e");
    }
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    // We only care about text/url sharing for now
    final file = files.first;
    final content = file.path;
    
    if (content.isNotEmpty) {
      debugPrint("Received shared content: $content");
      // Extract URL in case the shared content contains text + URL (e.g. Pinterest, Medium)
      final extractedUrl = _extractUrl(content);
      final sharedContent = extractedUrl ?? content;
      debugPrint("ShareService: Resolved stream content: $sharedContent");
      sharedUrlNotifier.value = sharedContent;
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
