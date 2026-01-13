
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keySearchHistory = 'search_history';
  static const String _keyThemeMode = 'theme_mode';

  // Singleton pattern (optional but good for services)
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  /// Get saved search history
  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySearchHistory) ?? [];
  }

  /// Add a search term to history
  /// Adds to the top, removes duplicates, and limits to 10 items
  Future<void> addSearchTerm(String term) async {
    if (term.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_keySearchHistory) ?? [];
    
    // Remove if exists to move to top
    history.remove(term);
    
    // Add to top
    history.insert(0, term);
    
    // Limit to 10
    if (history.length > 10) {
      history.removeRange(10, history.length);
    }
    
    await prefs.setStringList(_keySearchHistory, history);
  }

  /// Remove a specific term
  Future<void> removeSearchTerm(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_keySearchHistory) ?? [];
    
    history.remove(term);
    await prefs.setStringList(_keySearchHistory, history);
  }

  /// Clear all history
  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySearchHistory);
  }

  /// Get saved theme mode (default: 'air')
  Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyThemeMode) ?? 'air';
  }

  /// Save theme mode
  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyThemeMode, theme);
  }
}
