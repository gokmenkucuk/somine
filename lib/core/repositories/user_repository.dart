import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:somine_app/core/models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      debugPrint('❌ [UserRepository] Error getting user: $e');
      rethrow;
    }
  }

  /// Create or update user from Firebase Auth
  Future<UserModel> createOrUpdateUser(User firebaseUser) async {
    try {
      final userRef = _usersCollection.doc(firebaseUser.uid);
      final existingDoc = await userRef.get();
      
      // Use displayName, or extract from email if null (common with Apple Sign-In)
      String? displayName = firebaseUser.displayName;
      if (displayName == null || displayName.isEmpty) {
        if (firebaseUser.email != null && firebaseUser.email!.contains('@')) {
          // Extract name from email (e.g., john.doe@gmail.com -> John Doe)
          final emailName = firebaseUser.email!.split('@').first;
          displayName = emailName
              .replaceAll('.', ' ')
              .replaceAll('_', ' ')
              .split(' ')
              .map((word) => word.isNotEmpty 
                  ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                  : '')
              .join(' ');
          debugPrint('📝 [UserRepository] Used email for displayName: $displayName');
        }
      }

      if (existingDoc.exists) {
        // Update existing user (only update displayName if it was null before)
        final existingData = existingDoc.data();
        final existingDisplayName = existingData?['displayName'] as String?;
        
        await userRef.update({
          'email': firebaseUser.email,
          // Only update displayName if existing is null/empty or new one is provided
          if (existingDisplayName == null || existingDisplayName.isEmpty)
            'displayName': displayName,
          // 'photoURL': firebaseUser.photoURL, // DISABLED: Don't auto-update photo
          'updatedAt': FieldValue.serverTimestamp(),
        });
        debugPrint('✅ [UserRepository] User updated: ${firebaseUser.uid}');
      } else {
        // Create new user
        final now = DateTime.now();
        final newUser = UserModel(
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: displayName,
          photoURL: null, // DISABLED: Start with no photo
          createdAt: now,
          updatedAt: now,
        );
        await userRef.set(newUser.toFirestore());
        debugPrint('✅ [UserRepository] User created: ${firebaseUser.uid}');
      }

      // Return the updated user
      final updatedDoc = await userRef.get();
      return UserModel.fromFirestore(updatedDoc);
    } catch (e) {
      debugPrint('❌ [UserRepository] Error creating/updating user: $e');
      rethrow;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? displayName,
    String? username,
    String? photoURL,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) updates['displayName'] = displayName;
      if (username != null) updates['username'] = username;
      if (photoURL != null) updates['photoURL'] = photoURL;

      // 1. Update Firestore
      await _usersCollection.doc(uid).update(updates);
      
      // 2. Update Firebase Auth (Sync)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        if (displayName != null) await currentUser.updateDisplayName(displayName);
        if (photoURL != null) await currentUser.updatePhotoURL(photoURL);
        // Force reload to propagate changes to listeners
        await currentUser.reload(); 
      }

      debugPrint('✅ [UserRepository] User profile updated: $uid');
    } catch (e) {
      debugPrint('❌ [UserRepository] Error updating user profile: $e');
      rethrow;
    }
  }

  /// Delete user
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
      debugPrint('✅ [UserRepository] User deleted: $uid');
    } catch (e) {
      debugPrint('❌ [UserRepository] Error deleting user: $e');
      rethrow;
    }
  }

  /// Stream user changes
  Stream<UserModel?> streamUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // ============= USERNAME FUNCTIONS =============

  /// İsimden benzersiz kullanıcı adı oluştur
  Future<String> generateUniqueUsername(String name) async {
    // Türkçe karakterleri dönüştür
    String base = _normalizeTurkish(name.toLowerCase().trim());
    
    // Sadece alfanumerik ve alt çizgi bırak
    base = base.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
    
    // Birden fazla alt çizgiyi teke indir
    base = base.replaceAll(RegExp(r'_+'), '_');
    
    // Baş ve sondaki alt çizgileri kaldır
    base = base.replaceAll(RegExp(r'^_+|_+$'), '');
    
    // Eğer çok kısa ise, farklı kombinasyonlar dene
    if (base.length < 3) {
      // İsim çok kısa, rastgele sayı ekle
      base = '$base${DateTime.now().millisecondsSinceEpoch % 1000}';
    }
    
    // Maksimum 20 karakter
    if (base.length > 20) {
      base = base.substring(0, 20);
    }
    
    // Benzersiz olana kadar numara ekle
    String candidate = base;
    int suffix = 1;
    
    while (!await isUsernameAvailable(candidate)) {
      final suffixStr = '_$suffix';
      if (base.length + suffixStr.length > 20) {
        candidate = '${base.substring(0, 20 - suffixStr.length)}$suffixStr';
      } else {
        candidate = '$base$suffixStr';
      }
      suffix++;
      
      // Sonsuz döngüyü önle
      if (suffix > 1000) {
        candidate = '${base}_${DateTime.now().millisecondsSinceEpoch % 100000}';
        break;
      }
    }
    
    return candidate;
  }

  /// Kullanıcı adı müsait mi kontrol et
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final normalized = username.toLowerCase().trim();
      
      // Geçerlilik kontrolü
      if (!_isValidUsername(normalized)) {
        return false;
      }
      
      final snapshot = await _usersCollection
          .where('username', isEqualTo: normalized)
          .limit(1)
          .get();
      
      return snapshot.docs.isEmpty;
    } catch (e) {
      debugPrint('❌ [UserRepository] Error checking username: $e');
      return false;
    }
  }

  /// Kullanıcı adını güncelle
  Future<bool> updateUsername(String uid, String username) async {
    try {
      final normalized = username.toLowerCase().trim();
      
      // Geçerlilik kontrolü
      if (!_isValidUsername(normalized)) {
        throw Exception('Geçersiz kullanıcı adı formatı');
      }
      
      // Müsaitlik kontrolü (kendi kullanıcı adı hariç)
      final existing = await _usersCollection
          .where('username', isEqualTo: normalized)
          .limit(1)
          .get();
      
      if (existing.docs.isNotEmpty && existing.docs.first.id != uid) {
        throw Exception('Bu kullanıcı adı zaten alınmış');
      }
      
      await _usersCollection.doc(uid).update({
        'username': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ [UserRepository] Username updated: $normalized');
      return true;
    } catch (e) {
      debugPrint('❌ [UserRepository] Error updating username: $e');
      rethrow;
    }
  }

  /// Kullanıcı adı ile kullanıcı bul
  Future<UserModel?> findUserByUsername(String username) async {
    try {
      final normalized = username.toLowerCase().trim().replaceAll('@', '');
      
      final snapshot = await _usersCollection
          .where('username', isEqualTo: normalized)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      return UserModel.fromFirestore(snapshot.docs.first);
    } catch (e) {
      debugPrint('❌ [UserRepository] Error finding user by username: $e');
      return null;
    }
  }

  /// Türkçe karakterleri ASCII'ye dönüştür
  String _normalizeTurkish(String input) {
    const turkishChars = 'ğüşıöçĞÜŞİÖÇ';
    const asciiChars = 'gusiocGUSIOC';
    
    String result = input;
    for (int i = 0; i < turkishChars.length; i++) {
      result = result.replaceAll(turkishChars[i], asciiChars[i]);
    }
    
    // Boşlukları alt çizgiye çevir
    result = result.replaceAll(' ', '_');
    
    return result;
  }

  /// Kullanıcı adı formatı geçerli mi
  bool _isValidUsername(String username) {
    // 3-20 karakter, sadece küçük harf, rakam ve alt çizgi
    final regex = RegExp(r'^[a-z0-9_]{3,20}$');
    return regex.hasMatch(username);
  }
}
