
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PreferencesService {
  static const String _keySearchHistory = 'search_history';
  static const String _keyThemeMode = 'theme_mode';

  // Singleton pattern (optional but good for services)
  static final PreferencesService _instance = PreferencesService._internal();
  factory PreferencesService() => _instance;
  PreferencesService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============== FIREBASE SEARCH HISTORY (User-based) ==============

  /// Get saved search history from Firebase
  Future<List<String>> getSearchHistoryFirebase(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('metadata')
          .doc('search_history')
          .get();
      
      if (doc.exists && doc.data() != null) {
        final terms = doc.data()!['terms'];
        if (terms is List) {
          return terms.cast<String>();
        }
      }
      return [];
    } catch (e) {
      // Fallback to local if Firebase fails
      return getSearchHistory();
    }
  }

  /// Add a search term to Firebase history
  Future<void> addSearchTermFirebase(String userId, String term) async {
    if (term.trim().isEmpty) return;
    
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('metadata')
          .doc('search_history');
      
      final doc = await docRef.get();
      List<String> history = [];
      
      if (doc.exists && doc.data() != null) {
        final terms = doc.data()!['terms'];
        if (terms is List) {
          history = terms.cast<String>();
        }
      }
      
      // Remove if exists to move to top
      history.remove(term);
      
      // Add to top
      history.insert(0, term);
      
      // Limit to 10
      if (history.length > 10) {
        history = history.sublist(0, 10);
      }
      
      await docRef.set({
        'terms': history,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Fallback to local
      await addSearchTerm(term);
    }
  }

  /// Remove a specific term from Firebase
  Future<void> removeSearchTermFirebase(String userId, String term) async {
    try {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('metadata')
          .doc('search_history');
      
      final doc = await docRef.get();
      if (doc.exists && doc.data() != null) {
        final terms = doc.data()!['terms'];
        if (terms is List) {
          final history = terms.cast<String>();
          history.remove(term);
          
          await docRef.set({
            'terms': history,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      // Fallback to local
      await removeSearchTerm(term);
    }
  }

  /// Clear all Firebase history
  Future<void> clearSearchHistoryFirebase(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('metadata')
          .doc('search_history')
          .delete();
    } catch (e) {
      // Fallback to local
      await clearSearchHistory();
    }
  }

  // ============== LOCAL SEARCH HISTORY (SharedPreferences) ==============

  /// Get saved search history (local)
  Future<List<String>> getSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_keySearchHistory) ?? [];
  }

  /// Add a search term to history (local)
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

  /// Remove a specific term (local)
  Future<void> removeSearchTerm(String term) async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_keySearchHistory) ?? [];
    
    history.remove(term);
    await prefs.setStringList(_keySearchHistory, history);
  }

  /// Clear all history (local)
  Future<void> clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keySearchHistory);
  }

  // ============== THEME ==============

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
