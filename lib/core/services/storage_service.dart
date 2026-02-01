import 'dart:io';
import 'dart:typed_data';
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
      final ref = _storage.ref().child(path);

      debugPrint('🔵 [StorageService] Uploading to: $path (${_storage.bucket})');
      debugPrint('🔵 [StorageService] File path: ${file.path}');

      // Read file bytes first (like uploadImageFromUrl)
      final bytes = await file.readAsBytes();
      debugPrint('🔵 [StorageService] Bytes read: ${bytes.length}');

      // Simple metadata (like uploadImageFromUrl)
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // Use putData (like uploadImageFromUrl - this works!)
      await ref.putData(bytes, metadata);

      // Get Download URL directly (no retry logic needed like uploadImageFromUrl)
      final downloadUrl = await ref.getDownloadURL();
      debugPrint('✅ [StorageService] File uploaded: $downloadUrl');
      return downloadUrl;

    } catch (e, stackTrace) {
      debugPrint('❌ [StorageService] Error: $e');
      debugPrint('❌ [StorageService] Stack: $stackTrace');
      return null;
    }
  }

  /// Uploads bytes to Firebase Storage
  /// Returns the download URL or null if failed
  Future<String?> uploadBytes(Uint8List bytes, String path) async {
    try {
      debugPrint('🔵 [StorageService] uploadBytes called. Path: $path');
      debugPrint('🔵 [StorageService] Bucket: ${_storage.bucket}');
      debugPrint('🔵 [StorageService] Bytes length: ${bytes.length}');

      final ref = _storage.ref().child(path);
      debugPrint('🔵 [StorageService] Full path: ${ref.fullPath}');

      // Simple metadata
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      debugPrint('🔵 [StorageService] Starting putData...');
      final uploadTask = ref.putData(bytes, metadata);

      // Wait for upload with detailed logging
      debugPrint('🔵 [StorageService] Waiting for upload to complete...');
      final snapshot = await uploadTask;

      debugPrint('📊 [StorageService] Upload snapshot state: ${snapshot.state}');
      debugPrint('📊 [StorageService] Upload total bytes: ${snapshot.totalBytes}');

      if (snapshot.state == TaskState.success) {
        debugPrint('✅ [StorageService] Upload successful, getting download URL...');
        final downloadUrl = await ref.getDownloadURL();
        debugPrint('✅ [StorageService] Bytes uploaded: $downloadUrl');
        return downloadUrl;
      } else {
        debugPrint('❌ [StorageService] Upload failed with state: ${snapshot.state}');
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

  /// Delete file from Firebase Storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      // Handle base64 data URLs - can't delete from Storage
      if (downloadUrl.startsWith('data:')) {
        debugPrint('🗑️ [StorageService] Skipping base64 image (not in Storage)');
        return;
      }

      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      debugPrint('✅ [StorageService] File deleted: $downloadUrl');
    } catch (e) {
      debugPrint('❌ [StorageService] Error deleting file: $e');
    }
  }
}
