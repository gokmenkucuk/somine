import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();

  /// Uploads a file to Firebase Storage
  /// Returns the download URL
  Future<String> uploadFile(File file, String path, {String? contentType}) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: contentType);
      
      await ref.putFile(file, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  /// Downloads an image from a URL and uploads it to Firebase Storage
  /// Returns the persistent Firebase Storage URL
  /// 
  /// [userId] - The folder to store the image in
  /// [sourceUrl] - The original image URL (e.g. from Instagram CDN)
  Future<String?> persistenceImageFromUrl(String userId, String sourceUrl) async {
    if (sourceUrl.isEmpty) return null;
    
    // Safety: If it's already a firebase URL, don't re-upload
    if (sourceUrl.contains('firebasestorage.googleapis.com')) return sourceUrl;

    try {
      // 1. Download the image
      final response = await http.get(Uri.parse(sourceUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image source. Status: ${response.statusCode}');
      }

      // 2. Determine content type
      String contentType = 'image/jpeg'; // Default
      final headerType = response.headers['content-type'];
      if (headerType != null && headerType.startsWith('image/')) {
        contentType = headerType;
      }
      
      // 3. Generate a path
      // extension from content-type
      String ext = 'jpg';
      if (contentType.contains('png')) ext = 'png';
      if (contentType.contains('webp')) ext = 'webp';
      
      final fileName = '${_uuid.v4()}.$ext';
      final path = 'users/$userId/items/$fileName';
      final ref = _storage.ref().child(path);
      
      // 4. Upload raw bytes
      final metadata = SettableMetadata(contentType: contentType);
      await ref.putData(response.bodyBytes, metadata);
      
      // 5. Get and return new URL
      return await ref.getDownloadURL();
      
    } catch (e) {
      debugPrint('Error persisting image: $e');
      // On failure, return null (or could return original URL as fallback)
      return null; 
    }
  }
}
