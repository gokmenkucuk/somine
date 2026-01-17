import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:somine_app/core/services/storage_service.dart';

/// Migration service to fix expired Instagram image URLs
/// This should be run once to migrate old Instagram CDN URLs to Firebase Storage
class ImageMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final StorageService _storageService = StorageService();

  /// Migrate all Instagram CDN images to Firebase Storage
  /// Returns the count of successfully migrated images
  Future<int> migrateInstagramImages({
    required String userId,
    Function(int current, int total)? onProgress,
  }) async {
    int migratedCount = 0;
    
    try {
      // 1. Get all items for this user
      final querySnapshot = await _firestore
          .collection('items')
          .where('userId', isEqualTo: userId)
          .get();

      final itemsToMigrate = <QueryDocumentSnapshot>[];

      // 2. Filter items with Instagram CDN URLs
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final displayImage = data['displayImage'] as String?;
        
        if (displayImage != null && 
            displayImage.isNotEmpty &&
            _isInstagramCdnUrl(displayImage)) {
          itemsToMigrate.add(doc);
        }
      }

      debugPrint('🔄 Found ${itemsToMigrate.length} items with Instagram CDN URLs to migrate');

      // 3. Migrate each image
      for (int i = 0; i < itemsToMigrate.length; i++) {
        final doc = itemsToMigrate[i];
        final data = doc.data() as Map<String, dynamic>;
        final oldUrl = data['displayImage'] as String;

        onProgress?.call(i + 1, itemsToMigrate.length);

        try {
          // Upload to Firebase Storage
          final newUrl = await _storageService.uploadImageFromUrl(oldUrl, userId);

          if (newUrl != null) {
            // Update Firestore document
            await doc.reference.update({'displayImage': newUrl});
            migratedCount++;
            debugPrint('✅ Migrated: ${doc.id} -> $newUrl');
          } else {
            debugPrint('⚠️ Failed to upload: ${doc.id}');
          }
        } catch (e) {
          debugPrint('❌ Error migrating ${doc.id}: $e');
        }

        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 200));
      }

      debugPrint('🎉 Migration complete: $migratedCount/${itemsToMigrate.length} images migrated');
      
    } catch (e) {
      debugPrint('❌ Migration error: $e');
    }

    return migratedCount;
  }

  /// Check if URL is an Instagram CDN URL (not Firebase Storage)
  bool _isInstagramCdnUrl(String url) {
    return (url.contains('cdninstagram.com') || 
            url.contains('instagram.com') ||
            url.contains('fbcdn.net')) &&
           !url.contains('firebasestorage.googleapis.com');
  }

  /// Get count of items needing migration (for UI preview)
  Future<int> getItemsNeedingMigration(String userId) async {
    int count = 0;
    
    final querySnapshot = await _firestore
        .collection('items')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final displayImage = data['displayImage'] as String?;
      
      if (displayImage != null && 
          displayImage.isNotEmpty &&
          _isInstagramCdnUrl(displayImage)) {
        count++;
      }
    }

    return count;
  }
}
