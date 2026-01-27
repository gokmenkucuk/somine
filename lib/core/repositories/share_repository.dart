import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:somine_app/core/models/share_model.dart';
import 'package:somine_app/core/models/notification_model.dart';
import 'package:somine_app/core/repositories/notification_repository.dart';

class ShareRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final NotificationRepository _notificationRepository = NotificationRepository();
  
  CollectionReference get _sharesCollection => _firestore.collection('collection_shares');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Kullanıcı adı ile kullanıcı bul (öncelikli arama yöntemi)
  Future<Map<String, dynamic>?> findUserByUsername(String username) async {
    try {
      // @ işaretini kaldır ve normalize et
      final normalized = username.toLowerCase().trim().replaceAll('@', '');
      
      if (normalized.isEmpty) return null;
      
      final snapshot = await _usersCollection
          .where('username', isEqualTo: normalized)
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'email': data['email'],
        'displayName': data['displayName'] ?? data['email'],
        'username': data['username'],
        'photoBase64': data['photoBase64'],
      };
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error finding user by username: $e');
      return null;
    }
  }

  /// E-posta ile kullanıcı bul (fallback)
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    try {
      final snapshot = await _usersCollection
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();
      
      if (snapshot.docs.isEmpty) return null;
      
      final doc = snapshot.docs.first;
      final data = doc.data() as Map<String, dynamic>;
      return {
        'id': doc.id,
        'email': data['email'],
        'displayName': data['displayName'] ?? data['email'],
        'username': data['username'],
        'photoBase64': data['photoBase64'],
      };
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error finding user by email: $e');
      return null;
    }
  }

  /// Kullanıcı adı veya e-posta ile kullanıcı bul
  Future<Map<String, dynamic>?> findUser(String query) async {
    // Önce kullanıcı adı ile ara (@ ile başlıyorsa veya genel arama)
    if (query.startsWith('@') || !query.contains('@')) {
      final userByUsername = await findUserByUsername(query);
      if (userByUsername != null) return userByUsername;
    }
    
    // E-posta içeriyorsa e-posta ile ara
    if (query.contains('@') && !query.startsWith('@')) {
      return await findUserByEmail(query);
    }
    
    return null;
  }

  /// Son paylaşılan kullanıcıları getir (daha önce paylaşım yapılmış kişiler)
  Future<List<Map<String, dynamic>>> getRecentlySharedUsers(String currentUserId, {int limit = 5}) async {
    try {
      // Kullanıcının yaptığı paylaşımları al
      final snapshot = await _sharesCollection
          .where('fromUserId', isEqualTo: currentUserId)
          .orderBy('createdAt', descending: true)
          .limit(20) // Son 20 paylaşımı al, sonra unique yapalım
          .get();
      
      // Benzersiz kullanıcıları topla (Map ile duplicate önle)
      final Map<String, Map<String, dynamic>> uniqueUsers = {};
      
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final toUserId = data['toUserId'] as String?;
        
        if (toUserId != null && !uniqueUsers.containsKey(toUserId)) {
          // Kullanıcı detaylarını al
          final userDoc = await _usersCollection.doc(toUserId).get();
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            uniqueUsers[toUserId] = {
              'id': toUserId,
              'email': userData['email'],
              'displayName': userData['displayName'] ?? userData['email'],
              'username': userData['username'],
              'photoBase64': userData['photoBase64'],
            };
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

  /// Yeni paylaşım oluştur
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
      // Alıcıyı bul (ID varsa ID ile, yoksa email ile)
      Map<String, dynamic>? targetUser;
      
      if (toUserId != null && toUserId.isNotEmpty) {
        final doc = await _usersCollection.doc(toUserId).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          targetUser = {
            'id': doc.id,
            'email': data['email'],
            'displayName': data['displayName'] ?? data['email'],
            'username': data['username'],
            'photoBase64': data['photoBase64'],
          };
        }
      } else {
         targetUser = await findUserByEmail(toUserEmail);
      }

      if (targetUser == null) {
        throw Exception('Kullanıcı bulunamadı');
      }
      
      // Kendine paylaşım yapılamaz
      if (targetUser['id'] == fromUserId) {
        throw Exception('Kendinize paylaşım yapamazsınız');
      }
      
      // Aynı koleksiyon zaten paylaşılmış mı kontrol et
      final existingShare = await _sharesCollection
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
        toUserId: targetUser['id'],
        toUserEmail: targetUser['email'] ?? '',
        categoryId: categoryId,
        categoryName: categoryName,
        status: ShareStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef = await _sharesCollection.add(share.toFirestore());
      
      // Alıcıya bildirim gönder
      await _notificationRepository.createNotification(
        userId: targetUser['id'],
        type: NotificationType.shareRequest,
        title: 'Yeni Paylaşım İsteği',
        message: '$fromUserName "$categoryName" koleksiyonunu sizinle paylaşmak istiyor',
        data: {
          'shareId': docRef.id,
          'categoryName': categoryName,
          'fromUserName': fromUserName,
        },
      );
      
      debugPrint('✅ [ShareRepository] Share created: ${docRef.id}');
      return share.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error creating share: $e');
      rethrow;
    }
  }

  /// Paylaşımı kabul et
  Future<void> acceptShare(String shareId) async {
    try {
      final shareDoc = await _sharesCollection.doc(shareId).get();
      if (!shareDoc.exists) throw Exception('Paylaşım bulunamadı');
      
      final share = ShareModel.fromFirestore(shareDoc);
      
      await _sharesCollection.doc(shareId).update({
        'status': ShareStatus.accepted.name,
        'acceptedAt': Timestamp.now(),
      });

      // Paylaşan kişiye bildirim gönder
      await _notificationRepository.createNotification(
        userId: share.fromUserId,
        type: NotificationType.shareAccepted,
        title: 'Paylaşım Kabul Edildi',
        message: '"${share.categoryName}" koleksiyonunu paylaştığınız kişi kabul etti',
        data: {
          'shareId': shareId,
          'categoryName': share.categoryName,
        },
      );
      
      debugPrint('✅ [ShareRepository] Share accepted: $shareId');
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error accepting share: $e');
      rethrow;
    }
  }

  /// Paylaşımı reddet
  Future<void> rejectShare(String shareId) async {
    try {
      final shareDoc = await _sharesCollection.doc(shareId).get();
      if (!shareDoc.exists) throw Exception('Paylaşım bulunamadı');
      
      final share = ShareModel.fromFirestore(shareDoc);
      
      await _sharesCollection.doc(shareId).update({
        'status': ShareStatus.rejected.name,
        'rejectedAt': Timestamp.now(),
      });

      // Paylaşan kişiye bildirim gönder
      await _notificationRepository.createNotification(
        userId: share.fromUserId,
        type: NotificationType.shareRejected,
        title: 'Paylaşım Reddedildi',
        message: '"${share.categoryName}" koleksiyonunu paylaştığınız kişi reddetti',
        data: {
          'shareId': shareId,
          'categoryName': share.categoryName,
        },
      );
      
      debugPrint('✅ [ShareRepository] Share rejected: $shareId');
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error rejecting share: $e');
      rethrow;
    }
  }

  /// Paylaşımı geri çek
  Future<void> revokeShare(String shareId) async {
    try {
      // Önce paylaşım detayını al (kime gönderildiğini bulmak için)
      final doc = await _sharesCollection.doc(shareId).get();
      
      // Eğer doküman varsa bildirimleri temizle
      if (doc.exists) {
        try {
          final data = doc.data() as Map<String, dynamic>;
          final toUserId = data['toUserId'] as String?;
          
          if (toUserId != null) {
            // İlgili bildirimi sil
            await _notificationRepository.deleteNotificationsByShareId(
              toUserId, 
              shareId
            );
          }
        } catch (e) {
          debugPrint('⚠️ [ShareRepository] Could not cleanup notifications: $e');
          // Bildirim silinemese bile paylaşımı silmeye devam et
        }
      }

      // Sonra paylaşımı sil
      await _sharesCollection.doc(shareId).delete();
      debugPrint('✅ [ShareRepository] Share revoked: $shareId');
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error revoking share: $e');
      rethrow;
    }
  }

  /// Paylaştıklarım (Stream)
  Stream<List<ShareModel>> getMyShares(String userId) {
    return _sharesCollection
        .where('fromUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
          final shares = snapshot.docs
              .map((doc) => ShareModel.fromFirestore(doc))
              .toList();
          // Client-side sorting to avoid composite index requirement
          shares.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return shares;
        });
  }

  /// Benimle paylaşılanlar - Kabul edilenler (Stream)
  Stream<List<ShareModel>> getSharedWithMe(String userId) {
    return _sharesCollection
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: ShareStatus.accepted.name)
        .snapshots()
        .map((snapshot) {
          final shares = snapshot.docs
              .map((doc) => ShareModel.fromFirestore(doc))
              .toList();
          // Client-side sorting
          shares.sort((a, b) {
            final dateA = a.acceptedAt ?? a.createdAt;
            final dateB = b.acceptedAt ?? b.createdAt;
            return dateB.compareTo(dateA);
          });
          return shares;
        });
  }

  /// Bekleyen paylaşım istekleri (Stream)
  Stream<List<ShareModel>> getPendingShareRequests(String userId) {
    return _sharesCollection
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: ShareStatus.pending.name)
        .snapshots()
        .map((snapshot) {
          final shares = snapshot.docs
              .map((doc) => ShareModel.fromFirestore(doc))
              .toList();
          // Client-side sorting
          shares.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return shares;
        });
  }

  /// Tek paylaşım detayı
  Future<ShareModel?> getShareById(String shareId) async {
    try {
      final doc = await _sharesCollection.doc(shareId).get();
      if (!doc.exists) return null;
      return ShareModel.fromFirestore(doc);
    } catch (e) {
      debugPrint('❌ [ShareRepository] Error getting share: $e');
      return null;
    }
  }
}
