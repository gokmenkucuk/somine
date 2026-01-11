import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class StorageService {
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
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
        customMetadata: {
          'originalUrl': url,
          'uploadedBy': userId,
        },
      );

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
}
