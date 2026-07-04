import 'package:flutter/services.dart';
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';

class AppIcon {
  final String key; // Native bundle key (matches CFBundleAlternateIcons in Info.plist)
  final String name; // Display name
  final String previewAsset; // Asset path for preview in UI (e.g. assets/app_icons/preview_dark.png)
  final bool isPremium;

  const AppIcon({
    required this.key, 
    required this.name, 
    required this.previewAsset,
    this.isPremium = true, // Most alternates are premium
  });
}

class IconService {
  // Define available icons
  // 'default' key is special -> passes null to native to reset
  static const List<AppIcon> icons = [
    AppIcon(key: 'default', name: 'Varsayılan', previewAsset: 'assets/app_icons/preview_default.png', isPremium: false),
    AppIcon(key: 'dark', name: 'Midnight Black', previewAsset: 'assets/app_icons/preview_dark.png', isPremium: true),
    AppIcon(key: 'light', name: 'Pure White', previewAsset: 'assets/app_icons/preview_light.png', isPremium: true),
    AppIcon(key: 'gold', name: 'Royal Gold', previewAsset: 'assets/app_icons/preview_gold.png', isPremium: true),
    AppIcon(key: 'neon', name: 'Cyber Neon', previewAsset: 'assets/app_icons/preview_neon.png', isPremium: true),
    AppIcon(key: 'retro', name: 'Retro 80s', previewAsset: 'assets/app_icons/preview_retro.png', isPremium: true),
  ];

  Future<bool> isSupported() async {
    try {
      return await FlutterDynamicIcon.supportsAlternateIcons;
    } on PlatformException {
      return false;
    }
  }

  Future<String?> getCurrentIcon() async {
    try {
      return await FlutterDynamicIcon.getAlternateIconName();
    } on PlatformException {
      return null;
    }
  }

  Future<void> setIcon(String key) async {
    try {
      if (key == 'default') {
        await FlutterDynamicIcon.setAlternateIconName(null);
      } else {
        await FlutterDynamicIcon.setAlternateIconName(key);
      }
    } on PlatformException {
      // Handle known errors (e.g. user cancelled)
      rethrow;
    }
  }
}
