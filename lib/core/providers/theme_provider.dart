
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/services/preferences_service.dart';

enum AppThemeEnum {
  air,
  midnight,
  vibe
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeEnum>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeEnum> {
  ThemeNotifier() : super(AppThemeEnum.air) {
    _loadTheme();
  }

  final PreferencesService _prefs = PreferencesService();

  Future<void> _loadTheme() async {
    final themeStr = await _prefs.getTheme();
    state = _fromString(themeStr);
  }

  Future<void> setTheme(AppThemeEnum theme) async {
    state = theme;
    await _prefs.setTheme(_toString(theme));
  }

  AppThemeEnum _fromString(String val) {
    switch (val) {
      case 'midnight': return AppThemeEnum.midnight;
      case 'vibe': return AppThemeEnum.vibe;
      case 'air':
      default: return AppThemeEnum.air;
    }
  }

  String _toString(AppThemeEnum theme) {
    switch (theme) {
      case AppThemeEnum.midnight: return 'midnight';
      case AppThemeEnum.vibe: return 'vibe';
      case AppThemeEnum.air:
      default: return 'air';
    }
  }
}
