
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/services/preferences_service.dart';

enum AppThemeEnum {
  /// Telefonun açık/karanlık ayarını izler: açıkta Air, karanlıkta Midnight.
  /// Herkese açık (ücretsiz); elle sabit Midnight ve Vibe Premium'dur.
  system,
  air,
  midnight,
  vibe
}

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeEnum>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<AppThemeEnum> {
  ThemeNotifier() : super(AppThemeEnum.system) {
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
      case 'air': return AppThemeEnum.air;
      default: return AppThemeEnum.system;
    }
  }

  String _toString(AppThemeEnum theme) {
    switch (theme) {
      case AppThemeEnum.midnight: return 'midnight';
      case AppThemeEnum.vibe: return 'vibe';
      case AppThemeEnum.air: return 'air';
      case AppThemeEnum.system: return 'system';
    }
  }
}
