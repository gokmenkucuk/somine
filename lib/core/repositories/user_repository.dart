import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/models/user_model.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BackendAuthService _backendAuthService = BackendAuthService();
  final http.Client _httpClient = http.Client();

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      final localUser = await _getLocalUser(uid);

      if (_shouldUseBackendForUser(uid)) {
        final backendUser = await _getCurrentUserFromApi();
        if (backendUser != null) {
          return _mergeBackendUser(backendUser, localUser, uid);
        }
      }

      return localUser;
    } catch (e) {
      debugPrint('❌ [UserRepository] Error getting user: $e');
      rethrow;
    }
  }

  /// Create or update user from Firebase Auth
  Future<UserModel> createOrUpdateUser(User firebaseUser) async {
    try {
      await _createOrUpdateLocalUser(firebaseUser);

      if (_backendAuthService.isEnabled) {
        try {
          await _backendAuthService.ensureSession(firebaseUser);
          final backendUser = await _getCurrentUserFromApi();
          final localUser = await _getLocalUser(firebaseUser.uid);
          if (backendUser != null) {
            return _mergeBackendUser(backendUser, localUser, firebaseUser.uid);
          }
        } catch (e) {
          debugPrint(
            '⚠️ [UserRepository] Backend create/update sync failed: $e',
          );
        }
      }

      final updatedDoc = await _getLocalUser(firebaseUser.uid);
      if (updatedDoc == null) {
        throw Exception('User could not be created or loaded.');
      }

      return updatedDoc;
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
      if (_shouldUseBackendForUser(uid)) {
        await _updateCurrentUserViaApi(
          displayName: displayName,
          username: username,
          photoURL: photoURL,
        );
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (displayName != null) updates['displayName'] = displayName;
      if (username != null) updates['username'] = username;
      if (photoURL != null) updates['photoURL'] = photoURL;

      await _usersCollection.doc(uid).set(updates, SetOptions(merge: true));

      // 2. Update Firebase Auth (Sync)
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        if (displayName != null) {
          await currentUser.updateDisplayName(displayName);
        }
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

  Future<void> updateProfilePhotoBase64({
    required String uid,
    required String photoBase64,
  }) async {
    try {
      if (_shouldUseBackendForUser(uid)) {
        await _updateCurrentUserViaApi(
          photoURL: null,
          photoBase64: photoBase64,
        );
      }

      await _usersCollection.doc(uid).set({
        'photoBase64': photoBase64,
        'photoURL': null,
        'photoUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ [UserRepository] Profile photo updated: $uid');
    } catch (e) {
      debugPrint('❌ [UserRepository] Error updating profile photo: $e');
      rethrow;
    }
  }

  Future<void> clearProfilePhoto(String uid) async {
    try {
      if (_shouldUseBackendForUser(uid)) {
        await _updateCurrentUserViaApi(photoURL: null, photoBase64: null);
      }

      await _usersCollection.doc(uid).set({
        'photoBase64': null,
        'photoURL': null,
        'photoUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('✅ [UserRepository] Profile photo cleared: $uid');
    } catch (e) {
      debugPrint('❌ [UserRepository] Error clearing profile photo: $e');
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
    return _usersCollection.doc(uid).snapshots().asyncMap((doc) async {
      final localUser = doc.exists ? UserModel.fromFirestore(doc) : null;

      if (_shouldUseBackendForUser(uid)) {
        try {
          final backendUser = await _getCurrentUserFromApi();
          if (backendUser != null) {
            return _mergeBackendUser(backendUser, localUser, uid);
          }
        } catch (e) {
          debugPrint('⚠️ [UserRepository] Backend stream sync failed: $e');
        }
      }

      return localUser;
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

      if (_backendAuthService.isEnabled) {
        final matches = await _searchUsersViaApi(normalized);
        return !matches.any((user) => user.username == normalized);
      }

      final snapshot =
          await _usersCollection
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

      if (_shouldUseBackendForUser(uid)) {
        await _updateCurrentUserViaApi(username: normalized);
      } else {
        final existing =
            await _usersCollection
                .where('username', isEqualTo: normalized)
                .limit(1)
                .get();

        if (existing.docs.isNotEmpty && existing.docs.first.id != uid) {
          throw Exception('Bu kullanıcı adı zaten alınmış');
        }
      }

      await _usersCollection.doc(uid).set({
        'username': normalized,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

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

      if (_backendAuthService.isEnabled) {
        final matches = await _searchUsersViaApi(normalized);
        return matches.where((user) => user.username == normalized).firstOrNull;
      }

      final snapshot =
          await _usersCollection
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

  Future<UserModel?> _getLocalUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) {
      return null;
    }

    return UserModel.fromFirestore(doc);
  }

  bool _shouldUseBackendForUser(String uid) {
    return _backendAuthService.isEnabled &&
        FirebaseAuth.instance.currentUser?.uid == uid;
  }

  Future<void> _createOrUpdateLocalUser(User firebaseUser) async {
    final userRef = _usersCollection.doc(firebaseUser.uid);
    final existingDoc = await userRef.get();

    String? displayName = firebaseUser.displayName;
    if (displayName == null || displayName.isEmpty) {
      if (firebaseUser.email != null && firebaseUser.email!.contains('@')) {
        final emailName = firebaseUser.email!.split('@').first;
        displayName = emailName
            .replaceAll('.', ' ')
            .replaceAll('_', ' ')
            .split(' ')
            .map(
              (word) =>
                  word.isNotEmpty
                      ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
                      : '',
            )
            .join(' ');
        debugPrint(
          '📝 [UserRepository] Used email for displayName: $displayName',
        );
      }
    }

    if (existingDoc.exists) {
      final existingData = existingDoc.data();
      final existingDisplayName = existingData?['displayName'] as String?;

      await userRef.update({
        'email': firebaseUser.email,
        if (existingDisplayName == null || existingDisplayName.isEmpty)
          'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('✅ [UserRepository] User updated: ${firebaseUser.uid}');
      return;
    }

    final now = DateTime.now();
    final newUser = UserModel(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: displayName,
      photoURL: null,
      createdAt: now,
      updatedAt: now,
    );
    await userRef.set(newUser.toFirestore());
    debugPrint('✅ [UserRepository] User created: ${firebaseUser.uid}');
  }

  Future<UserModel?> _getCurrentUserFromApi() async {
    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final response = await _httpClient.get(
      _buildUri('/api/users/me'),
      headers: _jsonHeaders(accessToken),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to fetch current user. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return UserModel(
      uid: FirebaseAuth.instance.currentUser?.uid ?? '',
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      username: json['username'] as String?,
      photoURL: json['photoUrl'] as String?,
      photoBase64: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _updateCurrentUserViaApi({
    String? displayName,
    String? username,
    String? photoURL,
    String? photoBase64,
  }) async {
    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No backend access token available.');
    }

    final response = await _httpClient.put(
      _buildUri('/api/users/me'),
      headers: _jsonHeaders(accessToken),
      body: jsonEncode({
        'displayName': displayName,
        'username': username,
        'photoUrl': photoURL,
        'photoBase64': photoBase64,
      }),
    );

    if (response.statusCode == 409) {
      throw Exception('Bu kullanıcı adı zaten alınmış');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to update current user. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }
  }

  Future<List<UserModel>> _searchUsersViaApi(String query) async {
    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      return [];
    }

    final response = await _httpClient.get(
      _buildUri('/api/users/search?q=$query'),
      headers: _jsonHeaders(accessToken),
    );

    if (response.statusCode == 400) {
      return [];
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to search users. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }

    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .whereType<Map<String, dynamic>>()
        .map(
          (json) => UserModel(
            uid: json['id'] as String? ?? '',
            email: null,
            displayName: json['displayName'] as String?,
            username: json['username'] as String?,
            photoURL: json['photoUrl'] as String?,
            photoBase64: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        )
        .toList();
  }

  UserModel _mergeBackendUser(
    UserModel backendUser,
    UserModel? localUser,
    String uid,
  ) {
    return UserModel(
      uid: uid,
      email: backendUser.email ?? localUser?.email,
      displayName: backendUser.displayName ?? localUser?.displayName,
      username: backendUser.username ?? localUser?.username,
      photoURL: backendUser.photoURL ?? localUser?.photoURL,
      photoBase64: localUser?.photoBase64,
      createdAt: localUser?.createdAt ?? backendUser.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Uri _buildUri(String pathWithQuery) {
    final baseUrl = ApiConfig.baseUrl;
    final normalizedBase =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    return Uri.parse('$normalizedBase$pathWithQuery');
  }

  Map<String, String> _jsonHeaders(String accessToken) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (ApiConfig.apiKey.isNotEmpty) 'X-SoMine-Api-Key': ApiConfig.apiKey,
      'Authorization': 'Bearer $accessToken',
    };
  }
}
