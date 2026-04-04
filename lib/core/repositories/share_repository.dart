import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/models/notification_model.dart';
import 'package:somine_app/core/models/share_model.dart';
import 'package:somine_app/core/repositories/notification_repository.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';

class ShareRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationRepository _notificationRepository =
      NotificationRepository();
  final BackendAuthService _backendAuthService = BackendAuthService();
  final http.Client _httpClient = http.Client();

  CollectionReference get _sharesCollection =>
      _firestore.collection('collection_shares');
  CollectionReference get _usersCollection => _firestore.collection('users');

  Future<Map<String, dynamic>?> findUserByUsername(String username) async {
    try {
      final normalized = username.toLowerCase().trim().replaceAll('@', '');
      if (normalized.isEmpty) return null;

      if (_backendAuthService.isEnabled) {
        final matches = await _searchUsersViaApi(normalized);
        for (final match in matches) {
          if ((match['username'] as String?)?.toLowerCase() == normalized) {
            return match;
          }
        }
      }

      final snapshot =
          await _usersCollection
              .where('username', isEqualTo: normalized)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      return _mapFirestoreUser(doc.id, data);
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error finding user by username: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      final normalized = email.toLowerCase().trim();
      if (normalized.isEmpty) return null;

      if (_backendAuthService.isEnabled) {
        final matches = await _searchUsersViaApi(normalized);
        for (final match in matches) {
          if ((match['email'] as String?)?.toLowerCase() == normalized) {
            return match;
          }
        }
      }

      final snapshot =
          await _usersCollection
              .where('email', isEqualTo: normalized)
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) return null;

      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      return _mapFirestoreUser(doc.id, data);
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
      if (_useBackendForCurrentUser(currentUserId)) {
        final shares = await _getOutgoingSharesFromApi();
        final uniqueUsers = <String, Map<String, dynamic>>{};

        for (final share in shares) {
          if (share.toUserId.isEmpty ||
              uniqueUsers.containsKey(share.toUserId)) {
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
      }

      final snapshot =
          await _sharesCollection
              .where('fromUserId', isEqualTo: currentUserId)
              .orderBy('createdAt', descending: true)
              .limit(20)
              .get();

      final uniqueUsers = <String, Map<String, dynamic>>{};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final toUserId = data['toUserId'] as String?;

        if (toUserId != null && !uniqueUsers.containsKey(toUserId)) {
          final userDoc = await _usersCollection.doc(toUserId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            uniqueUsers[toUserId] = _mapFirestoreUser(toUserId, userData);
          }
        }

        if (uniqueUsers.length >= limit) break;
      }

      return uniqueUsers.values.toList();
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error getting recently shared users: $e');
      return [];
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
      if (_useBackendForCurrentUser(fromUserId)) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.post(
          _buildUri('/api/shares'),
          headers: _jsonHeaders(accessToken),
          body: jsonEncode({
            'categoryId': categoryId,
            'toUserEmail': toUserEmail,
            'toUserId': toUserId,
          }),
        );

        if (response.statusCode == 404) {
          throw Exception('Kullanıcı bulunamadı');
        }
        if (response.statusCode == 409) {
          throw Exception('Bu koleksiyon zaten bu kişiyle paylaşılmış');
        }
        if (response.statusCode == 400) {
          throw Exception('Paylaşım isteği oluşturulamadı');
        }

        _throwIfNotSuccessful(response, action: 'create share');
        return ShareModel.fromApi(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      Map<String, dynamic>? targetUser;

      if (toUserId != null && toUserId.isNotEmpty) {
        final doc = await _usersCollection.doc(toUserId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          targetUser = _mapFirestoreUser(doc.id, data);
        }
      } else {
        targetUser = await findUserByEmail(toUserEmail);
      }

      if (targetUser == null) {
        throw Exception('Kullanıcı bulunamadı');
      }

      if (targetUser['id'] == fromUserId) {
        throw Exception('Kendinize paylaşım yapamazsınız');
      }

      final existingShare =
          await _sharesCollection
              .where('fromUserId', isEqualTo: fromUserId)
              .where('toUserId', isEqualTo: targetUser['id'])
              .where('categoryId', isEqualTo: categoryId)
              .where('status', isEqualTo: ShareStatus.pending.name)
              .get();

      if (existingShare.docs.isNotEmpty) {
        throw Exception('Bu koleksiyon zaten bu kişiyle paylaşılmış');
      }

      final share = ShareModel(
        fromUserId: fromUserId,
        fromUserName: fromUserName,
        fromUserEmail: fromUserEmail,
        toUserId: targetUser['id'] as String? ?? '',
        toUserEmail: targetUser['email'] as String? ?? '',
        categoryId: categoryId,
        categoryName: categoryName,
        status: ShareStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef = await _sharesCollection.add(share.toFirestore());

      await _notificationRepository.createNotification(
        userId: targetUser['id'] as String? ?? '',
        type: NotificationType.shareRequest,
        title: 'Yeni Paylaşım İsteği',
        message:
            '$fromUserName "$categoryName" koleksiyonunu sizinle paylaşmak istiyor',
        data: {
          'shareId': docRef.id,
          'categoryName': categoryName,
          'fromUserName': fromUserName,
        },
      );

      return share.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error creating share: $e');
      rethrow;
    }
  }

  Future<void> acceptShare(String shareId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.put(
          _buildUri('/api/shares/$shareId/accept'),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'accept share');
        return;
      }

      final shareDoc = await _sharesCollection.doc(shareId).get();
      if (!shareDoc.exists) throw Exception('Paylaşım bulunamadı');

      final share = ShareModel.fromFirestore(shareDoc);

      await _sharesCollection.doc(shareId).update({
        'status': ShareStatus.accepted.name,
        'acceptedAt': Timestamp.now(),
      });

      await _notificationRepository.createNotification(
        userId: share.fromUserId,
        type: NotificationType.shareAccepted,
        title: 'Paylaşım Kabul Edildi',
        message:
            '"${share.categoryName}" koleksiyonunu paylaştığınız kişi kabul etti',
        data: {'shareId': shareId, 'categoryName': share.categoryName},
      );
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error accepting share: $e');
      rethrow;
    }
  }

  Future<void> rejectShare(String shareId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.put(
          _buildUri('/api/shares/$shareId/reject'),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'reject share');
        return;
      }

      final shareDoc = await _sharesCollection.doc(shareId).get();
      if (!shareDoc.exists) throw Exception('Paylaşım bulunamadı');

      final share = ShareModel.fromFirestore(shareDoc);

      await _sharesCollection.doc(shareId).update({
        'status': ShareStatus.rejected.name,
        'rejectedAt': Timestamp.now(),
      });

      await _notificationRepository.createNotification(
        userId: share.fromUserId,
        type: NotificationType.shareRejected,
        title: 'Paylaşım Reddedildi',
        message:
            '"${share.categoryName}" koleksiyonunu paylaştığınız kişi reddetti',
        data: {'shareId': shareId, 'categoryName': share.categoryName},
      );
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error rejecting share: $e');
      rethrow;
    }
  }

  Future<void> revokeShare(String shareId) async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final accessToken = await _requireAccessToken();
        final response = await _httpClient.delete(
          _buildUri('/api/shares/$shareId'),
          headers: _jsonHeaders(accessToken),
        );

        _throwIfNotSuccessful(response, action: 'revoke share');
        return;
      }

      final doc = await _sharesCollection.doc(shareId).get();

      if (doc.exists) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final toUserId = data['toUserId'] as String?;

          if (toUserId != null) {
            await _notificationRepository.deleteNotificationsByShareId(
              toUserId,
              shareId,
            );
          }
        } catch (e) {
          debugPrint(
            '⚠️ [ShareRepository] Could not cleanup notifications: $e',
          );
        }
      }

      await _sharesCollection.doc(shareId).delete();
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error revoking share: $e');
      rethrow;
    }
  }

  Stream<List<ShareModel>> getMyShares(String userId) async* {
    if (!_useBackendForCurrentUser(userId)) {
      yield* _sharesCollection
          .where('fromUserId', isEqualTo: userId)
          .snapshots()
          .map((snapshot) {
            final shares =
                snapshot.docs
                    .map((doc) => ShareModel.fromFirestore(doc))
                    .toList();
            shares.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return shares;
          });
      return;
    }

    while (true) {
      yield await _getOutgoingSharesFromApi();
      await Future<void>.delayed(const Duration(seconds: 2));
    }
  }

  Stream<List<ShareModel>> getSharedWithMe(String userId) async* {
    if (!_useBackendForCurrentUser(userId)) {
      yield* _sharesCollection
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: ShareStatus.accepted.name)
          .snapshots()
          .map((snapshot) {
            final shares =
                snapshot.docs
                    .map((doc) => ShareModel.fromFirestore(doc))
                    .toList();
            shares.sort((a, b) {
              final dateA = a.acceptedAt ?? a.createdAt;
              final dateB = b.acceptedAt ?? b.createdAt;
              return dateB.compareTo(dateA);
            });
            return shares;
          });
      return;
    }

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
    if (!_useBackendForCurrentUser(userId)) {
      yield* _sharesCollection
          .where('toUserId', isEqualTo: userId)
          .where('status', isEqualTo: ShareStatus.pending.name)
          .snapshots()
          .map((snapshot) {
            final shares =
                snapshot.docs
                    .map((doc) => ShareModel.fromFirestore(doc))
                    .toList();
            shares.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return shares;
          });
      return;
    }

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
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (_backendAuthService.isEnabled && currentUserId != null) {
        final outgoing = await _getOutgoingSharesFromApi();
        for (final share in outgoing) {
          if (share.id == shareId) return share;
        }

        final incoming = await _getIncomingSharesFromApi();
        for (final share in incoming) {
          if (share.id == shareId) return share;
        }

        return null;
      }

      final doc = await _sharesCollection.doc(shareId).get();
      if (!doc.exists) return null;
      return ShareModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error getting share: $e');
      return null;
    }
  }

  bool _useBackendForCurrentUser(String userId) {
    return _backendAuthService.isEnabled &&
        FirebaseAuth.instance.currentUser?.uid == userId;
  }

  Future<List<Map<String, dynamic>>> _searchUsersViaApi(String query) async {
    if (query.trim().length < 2) {
      return [];
    }

    final accessToken = await _requireAccessToken();
    final response = await _httpClient.get(
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
    final response = await _httpClient.get(
      _buildUri('/api/shares/outgoing'),
      headers: _jsonHeaders(accessToken),
    );

    _throwIfNotSuccessful(response, action: 'fetch outgoing shares');
    return _parseShareList(response.body);
  }

  Future<List<ShareModel>> _getIncomingSharesFromApi() async {
    final accessToken = await _requireAccessToken();
    final response = await _httpClient.get(
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

  Map<String, dynamic> _mapFirestoreUser(String id, Map<String, dynamic> data) {
    return {
      'id': id,
      'email': data['email'],
      'displayName': data['displayName'] ?? data['email'],
      'username': data['username'],
      'photoBase64': data['photoBase64'],
      'photoUrl': data['photoURL'],
    };
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
      throw Exception('Backend access token could not be obtained.');
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
      'Authorization': 'Bearer $accessToken',
    };
  }

  void _throwIfNotSuccessful(http.Response response, {required String action}) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    throw Exception(
      'Failed to $action. Status: ${response.statusCode}. Body: ${response.body}',
    );
  }
}
