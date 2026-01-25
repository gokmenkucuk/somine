import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:somine_app/core/models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  CollectionReference get _notificationsCollection => _firestore.collection('notifications');

  /// Yeni bildirim oluştur
  Future<NotificationModel> createNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic> data = const {},
  }) async {
    try {
      final notification = NotificationModel(
        userId: userId,
        type: type,
        title: title,
        message: message,
        data: data,
        isRead: false,
        createdAt: DateTime.now(),
      );

      final docRef = await _notificationsCollection.add(notification.toFirestore());
      
      debugPrint('✅ [NotificationRepository] Notification created: ${docRef.id}');
      return notification.copyWith(id: docRef.id);
    } catch (e) {
      debugPrint('❌ [NotificationRepository] Error creating notification: $e');
      rethrow;
    }
  }

  /// Kullanıcının tüm bildirimleri (Stream)
  Stream<List<NotificationModel>> getNotifications(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        // orderBy('createdAt', descending: true)  <- Bu index gerektirir, kaldırdık
        .snapshots()
        .map((snapshot) {
          final docs = snapshot.docs
              .map((doc) => NotificationModel.fromFirestore(doc))
              .toList();
          
          // Dart tarafında sıralama yapıyoruz (Index gerektirmez)
          docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          
          return docs;
        });
  }

  /// Okunmamış bildirim sayısı (Stream)
  Stream<int> getUnreadCount(String userId) {
    return _notificationsCollection
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).update({
        'isRead': true,
      });
      debugPrint('✅ [NotificationRepository] Notification marked as read: $notificationId');
    } catch (e) {
      debugPrint('❌ [NotificationRepository] Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();
      
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      
      await batch.commit();
      debugPrint('✅ [NotificationRepository] All notifications marked as read for user: $userId');
    } catch (e) {
      debugPrint('❌ [NotificationRepository] Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Bildirimi sil
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
      debugPrint('✅ [NotificationRepository] Notification deleted: $notificationId');
    } catch (e) {
      debugPrint('❌ [NotificationRepository] Error deleting notification: $e');
      rethrow;
    }
  }

  /// Belirli bir paylaşıma ait bildirimleri sil
  Future<void> deleteNotificationsByShareId(String userId, String shareId) async {
    try {
      // data map'i içindeki shareId alanına göre sorgula
      final snapshot = await _notificationsCollection
          .where('userId', isEqualTo: userId)
          .where('data.shareId', isEqualTo: shareId)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
      debugPrint('✅ [NotificationRepository] Notifications deleted for shareId: $shareId');
    } catch (e) {
      debugPrint('❌ [NotificationRepository] Error deleting notifications for shareId: $e');
      // Ana akışı bozmamak için hata fırlatmıyoruz, sadece logluyoruz
    }
  }
}
