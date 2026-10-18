import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/exceptions/network_exceptions.dart';
import 'package:somine_app/core/models/blocked_user_model.dart';
import 'package:somine_app/core/models/share_model.dart';
import 'package:somine_app/core/services/api_client.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';

class ShareRepository {
  final BackendAuthService _backendAuthService = BackendAuthService();
  final ApiClient _apiClient = ApiClient();

  Future<Map<String, dynamic>?> findUserByUsername(String username) async {
    try {
      final normalized = username.toLowerCase().trim().replaceAll('@', '');
      if (normalized.isEmpty) return null;

      final matches = await _searchUsersViaApi(normalized);
      for (final match in matches) {
        if ((match['username'] as String?)?.toLowerCase() == normalized) {
          return match;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error finding user by username: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      final normalized = email.toLowerCase().trim();
      if (normalized.isEmpty) return null;

      final matches = await _searchUsersViaApi(normalized);
      for (final match in matches) {
        if ((match['email'] as String?)?.toLowerCase() == normalized) {
          return match;
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error finding user by email: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> findUser(String query) async {
    if (query.startsWith('@') || !query.contains('@')) {
      final userByUsername = await findUserByUsername(query);
      if (userByUsername != null) return userByUsername;
    }

    if (query.contains('@') && !query.startsWith('@')) {
      return findUserByEmail(query);
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> getRecentlySharedUsers(
    String currentUserId, {
    int limit = 5,
  }) async {
    try {
      final shares = await _getOutgoingSharesFromApi();
      final uniqueUsers = <String, Map<String, dynamic>>{};

      for (final share in shares) {
        if (share.toUserId.isEmpty || uniqueUsers.containsKey(share.toUserId)) {
          continue;
        }

        Map<String, dynamic>? user;
        if (share.toUserEmail.isNotEmpty) {
          user = await findUserByEmail(share.toUserEmail);
        }

        uniqueUsers[share.toUserId] =
            user ??
            {
              'id': share.toUserId,
              'email': share.toUserEmail,
              'displayName': share.toUserEmail,
              'username': null,
              'photoBase64': null,
            };

        if (uniqueUsers.length >= limit) break;
      }

      return uniqueUsers.values.toList();
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error getting recently shared users: $e');
      return [];
    }
  }

  /// Bu ayki paylaşım hakkı (GET /api/shares/quota). Hata olursa null:
  /// arayüz hak bilgisini göstermez ama paylaşımı engellemez.
  Future<ShareQuota?> getShareQuota() async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.get(
        _buildUri('/api/shares/quota'),
        headers: _jsonHeaders(accessToken),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return null;
      return ShareQuota.fromApi(jsonDecode(response.body) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('⚠️ [ShareRepository] Share quota unavailable: $e');
      return null;
    }
  }

  Future<ShareModel?> createShare({
    required String fromUserId,
    required String fromUserName,
    required String fromUserEmail,
    required String toUserEmail,
    String? toUserId,
    required String categoryId,
    required String categoryName,
  }) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.post(
        _buildUri('/api/shares'),
        headers: _jsonHeaders(accessToken),
        body: jsonEncode({
          'categoryId': categoryId,
          'toUserEmail': toUserEmail,
          'toUserId': toUserId,
        }),
      );

      // Bu üç mesaj paylaşım sayfasında KULLANICIYA aynen gösteriliyor. Daha önce
      // düz Exception('Türkçe metin') idi ve İngilizce cihazda da Türkçe çıkıyordu.
      // Artık dilden bağımsız bir kod taşıyorlar; çeviriyi FailureMapper yapıyor.
      if (response.statusCode == 404) {
        throw const ValidationException(
          'share target user not found',
          userMessage: '',
          code: AppErrorCodes.shareUserNotFound,
        );
      }
      if (response.statusCode == 403 &&
          response.body.contains('limit_reached')) {
        throw const ValidationException(
          'monthly share limit reached',
          userMessage: '',
          code: AppErrorCodes.shareMonthlyLimit,
        );
      }
      if (response.statusCode == 409) {
        throw const ConflictException(
          'collection already shared with this user',
          userMessage: '',
          code: AppErrorCodes.shareAlreadyShared,
        );
      }
      if (response.statusCode == 400) {
        throw const ValidationException(
          'share request could not be created',
          userMessage: '',
          code: AppErrorCodes.shareCreateFailed,
        );
      }

      _throwIfNotSuccessful(response, action: 'create share');
      return ShareModel.fromApi(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error creating share: $e');
      rethrow;
    }
  }

  Future<void> acceptShare(String shareId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.put(
        _buildUri('/api/shares/$shareId/accept'),
        headers: _jsonHeaders(accessToken),
      );

      _throwIfNotSuccessful(response, action: 'accept share');
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error accepting share: $e');
      rethrow;
    }
  }

  Future<void> rejectShare(String shareId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.put(
        _buildUri('/api/shares/$shareId/reject'),
        headers: _jsonHeaders(accessToken),
      );

      _throwIfNotSuccessful(response, action: 'reject share');
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error rejecting share: $e');
      rethrow;
    }
  }

  Future<void> revokeShare(String shareId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.delete(
        _buildUri('/api/shares/$shareId'),
        headers: _jsonHeaders(accessToken),
      );

      _throwIfNotSuccessful(response, action: 'revoke share');
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error revoking share: $e');
      rethrow;
    }
  }

  Future<String> createPublicLink(String shareId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.post(
        _buildUri('/api/shares/$shareId/public-link'),
        headers: _jsonHeaders(accessToken),
      );

      _throwIfNotSuccessful(response, action: 'create public link');
      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      return payload['url'] as String? ?? '';
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error creating public link: $e');
      rethrow;
    }
  }

  Future<void> revokePublicLink(String shareId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.delete(
        _buildUri('/api/shares/$shareId/public-link'),
        headers: _jsonHeaders(accessToken),
      );

      _throwIfNotSuccessful(response, action: 'revoke public link');
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error revoking public link: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // App Store 1.2 (kullanıcı üretimi içerik): şikâyet, engelleme, kaldırma.
  //
  // Bu uçların hataları _throwIfModerationFailed ile, FailureMapper'ın dilden
  // bağımsız eşleyebildiği tiplere çevrilir (sunucunun İngilizce "error"
  // metni kullanıcıya hiç gösterilmez).
  // ---------------------------------------------------------------------------

  /// Alıcı olarak paylaşılan koleksiyonu şikâyet eder.
  Future<void> reportShare(
    String shareId,
    ShareReportReason reason, {
    String? note,
  }) async {
    try {
      final accessToken = await _requireAccessToken();
      final trimmedNote = note?.trim();
      final response = await _apiClient.post(
        _buildUri('/api/shares/$shareId/report'),
        headers: _jsonHeaders(accessToken),
        body: jsonEncode({
          'reason': reason.apiValue,
          if (trimmedNote != null && trimmedNote.isNotEmpty)
            'note': trimmedNote,
        }),
      );

      _throwIfModerationFailed(response, action: 'report share');
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error reporting share: $e');
      rethrow;
    }
  }

  /// Kullanıcıyı engeller. Sunucu, ondan gelen bekleyen istekleri reddeder ve
  /// paylaştığı koleksiyonlara erişimi kaldırır.
  Future<void> blockUser(String userId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.post(
        _buildUri('/api/users/$userId/block'),
        headers: _jsonHeaders(accessToken),
      );

      _throwIfModerationFailed(response, action: 'block user');
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error blocking user: $e');
      rethrow;
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.delete(
        _buildUri('/api/users/$userId/block'),
        headers: _jsonHeaders(accessToken),
      );

      _throwIfModerationFailed(response, action: 'unblock user');
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error unblocking user: $e');
      rethrow;
    }
  }

  Future<List<BlockedUserModel>> getBlockedUsers() async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.get(
        _buildUri('/api/users/blocked'),
        headers: _jsonHeaders(accessToken),
      );

      _throwIfModerationFailed(response, action: 'fetch blocked users');
      final payload = jsonDecode(response.body) as List<dynamic>;
      return payload
          .whereType<Map<String, dynamic>>()
          .map(BlockedUserModel.fromApi)
          .toList();
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error fetching blocked users: $e');
      rethrow;
    }
  }

  /// Alıcı olarak kabul edilmiş paylaşımı kütüphaneden kaldırır (gönderene
  /// bildirim gitmez).
  Future<void> leaveShare(String shareId) async {
    try {
      final accessToken = await _requireAccessToken();
      final response = await _apiClient.put(
        _buildUri('/api/shares/$shareId/leave'),
        headers: _jsonHeaders(accessToken),
      );

      _throwIfModerationFailed(response, action: 'leave share');
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error leaving share: $e');
      rethrow;
    }
  }

  /// "Reddet ve engelle": paylaşımı gönderen kişiyi engeller. Engelleme bekleyen
  /// isteği sunucuda zaten reddettiği için ayrıca reject çağrılmaz (böylece
  /// gönderene "reddedildi" bildirimi de gitmez). [fromUserId] bilinmiyorsa
  /// (eski bildirim verisi) gelen paylaşımlardan bulunur.
  Future<void> blockShareSender(String shareId, {String? fromUserId}) async {
    var senderId = fromUserId?.trim() ?? '';
    if (senderId.isEmpty) {
      final incoming = await _getIncomingSharesFromApi();
      for (final share in incoming) {
        if (share.id == shareId) {
          senderId = share.fromUserId;
          break;
        }
      }
    }

    if (senderId.isEmpty) {
      throw const FeatureUnavailableException(
        'share sender could not be resolved',
        userMessage: '',
      );
    }

    await blockUser(senderId);
  }

  Stream<List<ShareModel>> getMyShares(String userId) async* {
    while (true) {
      yield await _getOutgoingSharesFromApi();
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Stream<List<ShareModel>> getSharedWithMe(String userId) async* {
    while (true) {
      final shares = await _getIncomingSharesFromApi();
      final accepted =
          shares
              .where((share) => share.status == ShareStatus.accepted)
              .toList();
      accepted.sort((a, b) {
        final dateA = a.acceptedAt ?? a.createdAt;
        final dateB = b.acceptedAt ?? b.createdAt;
        return dateB.compareTo(dateA);
      });
      yield accepted;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Stream<List<ShareModel>> getPendingShareRequests(String userId) async* {
    while (true) {
      final shares = await _getIncomingSharesFromApi();
      final pending =
          shares.where((share) => share.status == ShareStatus.pending).toList();
      pending.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      yield pending;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Future<ShareModel?> getShareById(String shareId) async {
    try {
      final outgoing = await _getOutgoingSharesFromApi();
      for (final share in outgoing) {
        if (share.id == shareId) return share;
      }

      final incoming = await _getIncomingSharesFromApi();
      for (final share in incoming) {
        if (share.id == shareId) return share;
      }

      return null;
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error getting share: $e');
      return null;
    }
  }

  /// Revokes outgoing shares. Incoming shares and the rest of the account
  /// data are removed server-side by DELETE /api/users/me.
  Future<void> deleteAllUserShares(String userId) async {
    try {
      final outgoing = await _getOutgoingSharesFromApi();
      for (final share in outgoing) {
        if (share.id != null) {
          try {
            await revokeShare(share.id!);
          } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error deleting all shares: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _searchUsersViaApi(String query) async {
    if (query.trim().length < 2) {
      return [];
    }

    final accessToken = await _requireAccessToken();
    final response = await _apiClient.get(
      _buildUri('/api/users/search', queryParameters: {'q': query}),
      headers: _jsonHeaders(accessToken),
    );

    if (response.statusCode == 400) {
      return [];
    }

    _throwIfNotSuccessful(response, action: 'search users');

    final payload = jsonDecode(response.body) as List<dynamic>;
    return payload.whereType<Map<String, dynamic>>().map(_mapApiUser).toList();
  }

  Future<List<ShareModel>> _getOutgoingSharesFromApi() async {
    final accessToken = await _requireAccessToken();
    final response = await _apiClient.get(
      _buildUri('/api/shares/outgoing'),
      headers: _jsonHeaders(accessToken),
    );

    _throwIfNotSuccessful(response, action: 'fetch outgoing shares');
    return _parseShareList(response.body);
  }

  Future<List<ShareModel>> _getIncomingSharesFromApi() async {
    final accessToken = await _requireAccessToken();
    final response = await _apiClient.get(
      _buildUri('/api/shares/incoming'),
      headers: _jsonHeaders(accessToken),
    );

    _throwIfNotSuccessful(response, action: 'fetch incoming shares');
    return _parseShareList(response.body);
  }

  List<ShareModel> _parseShareList(String responseBody) {
    final payload = jsonDecode(responseBody) as List<dynamic>;
    return payload
        .whereType<Map<String, dynamic>>()
        .map(ShareModel.fromApi)
        .toList();
  }

  Map<String, dynamic> _mapApiUser(Map<String, dynamic> json) {
    return {
      'id': json['id'] as String? ?? '',
      'email': json['email'] as String?,
      'displayName': json['displayName'] as String? ?? json['email'],
      'username': json['username'] as String?,
      'photoBase64': json['photoBase64'] as String?,
      'photoUrl': json['photoUrl'] as String?,
    };
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

  Uri _buildUri(String path, {Map<String, String>? queryParameters}) {
    final baseUrl = ApiConfig.baseUrl;
    final normalizedBase =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    return Uri.parse('$normalizedBase$path').replace(
      queryParameters:
          queryParameters?.isEmpty == true ? null : queryParameters,
    );
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
        'share request unauthorized',
        userMessage: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      ),
      409 => const ConflictException(
        'share request conflict',
        userMessage: 'Bu işlem zaten yapıldı.',
      ),
      >= 400 && < 500 => ValidationException(
        'share request failed',
        userMessage: _parseApiError(response.body),
      ),
      >= 500 => const ServerException(
        'share server error',
        userMessage: 'Sunucu hatası oluştu. Lütfen biraz sonra tekrar deneyin.',
      ),
      _ => const ServerException(
        'share request failed',
        userMessage: 'İşlem başarısız oldu. Lütfen tekrar deneyin.',
      ),
    };
  }

  void _throwIfModerationFailed(
    http.Response response, {
    required String action,
  }) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    debugPrint('API Error [$action]: ${response.statusCode}');

    // userMessage boş: metni FailureMapper tipe göre yerelleştirir.
    throw switch (response.statusCode) {
      401 => UnauthorizedException('$action unauthorized', userMessage: ''),
      // 404: paylaşım/kullanıcı artık yok ya da sunucu bu ucu henüz tanımıyor.
      404 => FeatureUnavailableException('$action not found', userMessage: ''),
      409 => ConflictException('$action conflict', userMessage: ''),
      _ => ServerException(
        '$action failed (${response.statusCode})',
        userMessage: '',
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

/// Ücretsiz planın aylık paylaşım hakkı. Premium'da [unlimited] true.
class ShareQuota {
  final bool unlimited;
  final int limit;
  final int used;
  final int remaining;

  const ShareQuota({
    required this.unlimited,
    required this.limit,
    required this.used,
    required this.remaining,
  });

  factory ShareQuota.fromApi(Map<String, dynamic> json) => ShareQuota(
    unlimited: json['unlimited'] == true,
    limit: (json['limit'] as num?)?.toInt() ?? 0,
    used: (json['used'] as num?)?.toInt() ?? 0,
    remaining: (json['remaining'] as num?)?.toInt() ?? 0,
  );
}
