import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareService {
  static final ShareService _instance = ShareService._internal();
  factory ShareService() => _instance;
  ShareService._internal();

  StreamSubscription? _intentDataStreamSubscription;
  final ValueNotifier<String?> sharedUrlNotifier = ValueNotifier<String?>(null);

  /// Initialize listeners for share intents
  void initialize() {
    // For sharing or opening urls/text coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
    }, onError: (err) {
      debugPrint("getIntentDataStream error: $err");
    });

    // For sharing or opening urls/text coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      _handleSharedFiles(value);
      // Reset to prevent re-triggering on next cold start
      ReceiveSharingIntent.instance.reset();
    });
  }

  void _handleSharedFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    // We only care about text/url sharing for now
    final file = files.first;
    
    // Check if it's text or path that might contain a URL
    // receive_sharing_intent unifies text and files
    // For text sharing, the 'path' usually contains the text/url
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
