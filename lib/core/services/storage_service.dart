import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class StorageService {
  // Use default instance - let auto-config handle the bucket
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads an image from a URL to Firebase Storage
  /// Returns the download URL or null if failed
  Future<String?> uploadImageFromUrl(String url, String userId) async {
    try {
      // 1. Download image
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        debugPrint('❌ [StorageService] Failed to download image: ${response.statusCode}');
        return null;
      }

      // 2. Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getExtensionFromUrl(url);
      final filename = 'items/$userId/$timestamp$extension';

      // 3. Upload to Storage
      final ref = _storage.ref().child(filename);
      // Simple metadata
      final metadata = SettableMetadata(contentType: _getContentType(extension));

      await ref.putData(response.bodyBytes, metadata);

      // 4. Get Download URL
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('✅ [StorageService] Image uploaded: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      debugPrint('❌ [StorageService] Error uploading image: $e');
      return null;
    }
  }

  String _getExtensionFromUrl(String url) {
    try {
      // Remove query parameters
      final uri = Uri.parse(url);
      final path = uri.path;
      final extension = p.extension(path).toLowerCase();
      
      if (['.jpg', '.jpeg', '.png', '.webp', '.gif'].contains(extension)) {
        return extension;
      }
      return '.jpg'; // Default fallback
    } catch (e) {
      return '.jpg';
    }
  }

  String _getContentType(String extension) {
     switch (extension) {
      case '.png': return 'image/png';
      case '.webp': return 'image/webp';
      case '.gif': return 'image/gif';
      default: return 'image/jpeg';
    }
  }

  /// Uploads a file to Firebase Storage
  /// Returns the download URL or null if failed
  Future<String?> uploadFile(File file, String path) async {
    try {
      if (!await file.exists()) {
        debugPrint('❌ [StorageService] File does not exist');
        return null;
      }

      final ref = _storage.ref().child(path);
      
      debugPrint('🔵 [StorageService] Uploading to: $path (${_storage.bucket})');
      
      final bytes = await file.readAsBytes();
      
      // Upload without metadata to avoid any policy issues
      // Use putData for reliability
      final uploadTask = ref.putData(bytes);
      
      // Wait for completion
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
         debugPrint('✅ [StorageService] Upload success. Waiting for URL...');
         
         // Retry logic for getDownloadURL (Consistency delay workaround)
         for (int i = 0; i < 3; i++) {
           try {
             await Future.delayed(Duration(milliseconds: 1000 * (i + 1)));
             final downloadUrl = await ref.getDownloadURL();
             debugPrint('✅ [StorageService] Got URL: $downloadUrl');
             return downloadUrl;
           } catch (e) {
             debugPrint('⚠️ [StorageService] Retry $i failed: $e');
           }
         }
         return null;
      } else {
         debugPrint('❌ [StorageService] Upload failed. State: ${snapshot.state}');
         return null;
      }

    } catch (e, stackTrace) {
      debugPrint('❌ [StorageService] Error: $e');
      debugPrint('❌ [StorageService] Stack: $stackTrace');
      return null;
    }
  }

  Future<String?> uploadProfileImage(File file, String userId) async {
    try {
      final filename = 'users/$userId/profile.jpg';
      final ref = _storage.ref().child(filename);
      
      debugPrint('🔵 [StorageService] Starting upload to: $filename');
      
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': userId,
          'type': 'profile_photo',
        },
      );

      final bytes = await file.readAsBytes();
      
      // Perform upload
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
         debugPrint('✅ [StorageService] Upload task success. Bytes: ${snapshot.totalBytes}');
         
         final downloadUrl = await ref.getDownloadURL();
         debugPrint('✅ [StorageService] Got download URL: $downloadUrl');
         
         // Cache busting param
         return '$downloadUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      } else {
         debugPrint('❌ [StorageService] Upload failed or cancelled. State: ${snapshot.state}');
         return null;
      }

    } catch (e) {
      debugPrint('❌ [StorageService] Error uploading profile image: $e');
      return null;
    }
  }
}
