import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/exceptions/network_exceptions.dart';
import 'package:somine_app/core/models/user_model.dart';
import 'package:somine_app/core/services/api_client.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';

class UserRepository {
  final BackendAuthService _backendAuthService = BackendAuthService();
  final ApiClient _apiClient = ApiClient();

  /// Signals profile changes so [streamUser] listeners refetch.
  /// Static: profile updates can happen through any repository instance.
  static final StreamController<void> _profileChangedController =
      StreamController<void>.broadcast();

  /// Get user by ID
  Future<UserModel?> getUser(String uid) async {
    try {
      return await _getCurrentUserFromApi();
    } catch (e) {
      debugPrint('❌ [UserRepository] Error getting user: $e');
      rethrow;
    }
  }

  /// Create or update user from Firebase Auth
  Future<UserModel> createOrUpdateUser(User firebaseUser) async {
    try {
      await _backendAuthService.ensureSession(firebaseUser);

      var backendUser = await _getCurrentUserFromApi();
      if (backendUser == null) {
        throw Exception('User could not be created or loaded.');
      }

      // Backfill displayName from email for first-time Google users
      // whose Firebase profile has no name.
      if (backendUser.displayName == null || backendUser.displayName!.isEmpty) {
        final derivedName =
            firebaseUser.displayName ?? _displayNameFromEmail(firebaseUser.email);
        if (derivedName != null && derivedName.isNotEmpty) {
          await _updateCurrentUserViaApi(displayName: derivedName);
          backendUser = await _getCurrentUserFromApi() ?? backendUser;
        }
      }

      _profileChangedController.add(null);
      return backendUser;
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
      await _updateCurrentUserViaApi(
        displayName: displayName,
        username: username,
        photoURL: photoURL,
      );

      // Keep Firebase Auth profile in sync so auth listeners see the change
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.uid == uid) {
        if (displayName != null) {
          await currentUser.updateDisplayName(displayName);
        }
        if (photoURL != null) await currentUser.updatePhotoURL(photoURL);
        await currentUser.reload();
      }

      _profileChangedController.add(null);
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
      await _updateCurrentUserViaApi(photoBase64: photoBase64);
      _profileChangedController.add(null);
      debugPrint('✅ [UserRepository] Profile photo updated: $uid');
    } catch (e) {
      debugPrint('❌ [UserRepository] Error updating profile photo: $e');
      rethrow;
    }
  }

  Future<void> clearProfilePhoto(String uid) async {
    try {
      await _updateCurrentUserViaApi(clearPhoto: true);
      _profileChangedController.add(null);
      debugPrint('✅ [UserRepository] Profile photo cleared: $uid');
    } catch (e) {
      debugPrint('❌ [UserRepository] Error clearing profile photo: $e');
      rethrow;
    }
  }

  /// Delete user account and all backend data
  Future<void> deleteUser(String uid) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.delete(
        _buildUri('/api/users/me'),
        headers: _jsonHeaders(accessToken),
      );

      if (response.statusCode != 404) {
        _throwIfNotSuccessful(response, action: 'delete user');
      }
      debugPrint('✅ [UserRepository] User deleted: $uid');
    } catch (e) {
      debugPrint('❌ [UserRepository] Error deleting user: $e');
      rethrow;
    }
  }

  /// Stream user changes (refetches on profile updates)
  Stream<UserModel?> streamUser(String uid) async* {
    while (true) {
      try {
        yield await _getCurrentUserFromApi();

        await for (final _ in _profileChangedController.stream) {
          yield await _getCurrentUserFromApi();
        }
      } catch (error, stackTrace) {
        debugPrint('❌ [UserRepository] streamUser failed: $error');
        yield* Stream<UserModel?>.error(error, stackTrace);
        await Future<void>.delayed(const Duration(seconds: 5));
      }
    }
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

      final matches = await _searchUsersViaApi(normalized);
      return !matches.any((user) => user.username == normalized);
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

      await _updateCurrentUserViaApi(username: normalized);
      _profileChangedController.add(null);

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

      final matches = await _searchUsersViaApi(normalized);
      return matches.where((user) => user.username == normalized).firstOrNull;
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

  String? _displayNameFromEmail(String? email) {
    if (email == null || !email.contains('@')) return null;

    final emailName = email.split('@').first;
    return emailName
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
  }

  Future<UserModel?> _getCurrentUserFromApi() async {
    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    final response = await _apiClient.get(
      _buildUri('/api/users/me'),
      headers: _jsonHeaders(accessToken),
    );

    _throwIfNotSuccessful(response, action: 'fetch current user');

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return UserModel(
      uid: FirebaseAuth.instance.currentUser?.uid ?? '',
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      username: json['username'] as String?,
      photoURL: json['photoUrl'] as String?,
      photoBase64: json['photoBase64'] as String?,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> _updateCurrentUserViaApi({
    String? displayName,
    String? username,
    String? photoURL,
    String? photoBase64,
    bool clearPhoto = false,
  }) async {
    final accessToken = await _requireAccessToken();

    final response = await _apiClient.put(
      _buildUri('/api/users/me'),
      headers: _jsonHeaders(accessToken),
      body: jsonEncode({
        'displayName': displayName,
        'username': username,
        'photoUrl': photoURL,
        'photoBase64': photoBase64,
        if (clearPhoto) 'clearPhoto': true,
      }),
    );

    if (response.statusCode == 409) {
      throw const ConflictException(
        'username already exists',
        userMessage: 'Bu kullanıcı adı zaten alınmış.',
      );
    }

    _throwIfNotSuccessful(response, action: 'update current user');
  }

  Future<List<UserModel>> _searchUsersViaApi(String query) async {
    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      return [];
    }

    final response = await _apiClient.get(
      _buildUri('/api/users/search?q=$query'),
      headers: _jsonHeaders(accessToken),
    );

    if (response.statusCode == 400) {
      return [];
    }

    _throwIfNotSuccessful(response, action: 'search users');

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
            photoBase64: json['photoBase64'] as String?,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        )
        .toList();
  }

  Future<String> _requireAccessToken() async {
    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      throw const UnauthorizedException(
        'backend access token missing',
        userMessage: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      );
    }

    return accessToken;
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

  void _throwIfNotSuccessful(http.Response response, {required String action}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    debugPrint('API Error [$action]: ${response.statusCode}');

    throw switch (response.statusCode) {
      401 => const UnauthorizedException(
        'user request unauthorized',
        userMessage: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      ),
      409 => const ConflictException(
        'user request conflict',
        userMessage: 'Bu işlem zaten yapıldı.',
      ),
      >= 400 && < 500 => ValidationException(
        'user request failed',
        userMessage: _parseApiError(response.body),
      ),
      >= 500 => const ServerException(
        'user server error',
        userMessage: 'Sunucu hatası oluştu. Lütfen biraz sonra tekrar deneyin.',
      ),
      _ => const ServerException(
        'user request failed',
        userMessage: 'İşlem başarısız oldu. Lütfen tekrar deneyin.',
      ),
    };
  }

  String _parseApiError(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>?;
      return json?['message'] as String? ??
          json?['error'] as String? ??
          'İşlem başarısız oldu. Lütfen tekrar deneyin.';
    } catch (_) {
      return 'İşlem başarısız oldu. Lütfen tekrar deneyin.';
    }
  }
}
