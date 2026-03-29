import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';

class StorageService {
  // Use default instance - let auto-config handle the bucket
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final BackendAuthService _backendAuthService = BackendAuthService();
  final http.Client _httpClient = http.Client();

  /// Uploads an image from a URL to Firebase Storage
  /// Returns the download URL or null if failed
  Future<String?> uploadImageFromUrl(String url, String userId) async {
    try {
      if (url.contains('/storage/')) {
        return url;
      }

      // 1. Download image
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        debugPrint(
          '❌ [StorageService] Failed to download image: ${response.statusCode}',
        );
        return null;
      }

      final headerType = response.headers['content-type'];
      final contentType =
          headerType != null && headerType.startsWith('image/')
              ? headerType
              : _getContentType(_getExtensionFromUrl(url));

      if (_backendAuthService.isEnabled) {
        return _uploadBytesViaApi(
          response.bodyBytes,
          fileName:
              '${DateTime.now().millisecondsSinceEpoch}${_getExtensionFromUrl(url)}',
          contentType: contentType,
        );
      }

      // 2. Generate filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = _getExtensionFromUrl(url);
      final filename = 'items/$userId/$timestamp$extension';

      // 3. Upload to Storage
      final ref = _storage.ref().child(filename);
      // Simple metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(extension),
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
      final extension = _extension(path).toLowerCase();

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
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      default:
        return 'image/jpeg';
    }
  }

  /// Uploads a file to Firebase Storage
  /// Returns the download URL or null if failed
  Future<String?> uploadFile(File file, String path) async {
    try {
      if (_backendAuthService.isEnabled) {
        return _uploadBytesViaApi(
          await file.readAsBytes(),
          fileName: _basename(path.isNotEmpty ? path : file.path),
          contentType: _getContentType(_extension(file.path).toLowerCase()),
        );
      }

      final ref = _storage.ref().child(path);

      debugPrint(
        '🔵 [StorageService] Uploading to: $path (${_storage.bucket})',
      );
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
      if (_backendAuthService.isEnabled) {
        return _uploadBytesViaApi(
          bytes,
          fileName: _basename(path),
          contentType: _getContentType(_extension(path).toLowerCase()),
        );
      }

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

      debugPrint(
        '📊 [StorageService] Upload snapshot state: ${snapshot.state}',
      );
      debugPrint(
        '📊 [StorageService] Upload total bytes: ${snapshot.totalBytes}',
      );

      if (snapshot.state == TaskState.success) {
        debugPrint(
          '✅ [StorageService] Upload successful, getting download URL...',
        );
        final downloadUrl = await ref.getDownloadURL();
        debugPrint('✅ [StorageService] Bytes uploaded: $downloadUrl');
        return downloadUrl;
      } else {
        debugPrint(
          '❌ [StorageService] Upload failed with state: ${snapshot.state}',
        );
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
      if (_backendAuthService.isEnabled) {
        final uploadedUrl = await _uploadBytesViaApi(
          await file.readAsBytes(),
          fileName: 'profile_$userId.jpg',
          contentType: 'image/jpeg',
        );

        if (uploadedUrl == null) {
          return null;
        }

        return '$uploadedUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      }

      final filename = 'users/$userId/profile.jpg';
      final ref = _storage.ref().child(filename);

      debugPrint('🔵 [StorageService] Starting upload to: $filename');

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': userId, 'type': 'profile_photo'},
      );

      final bytes = await file.readAsBytes();

      // Perform upload
      final uploadTask = ref.putData(bytes, metadata);
      final snapshot = await uploadTask;

      if (snapshot.state == TaskState.success) {
        debugPrint(
          '✅ [StorageService] Upload task success. Bytes: ${snapshot.totalBytes}',
        );

        final downloadUrl = await ref.getDownloadURL();
        debugPrint('✅ [StorageService] Got download URL: $downloadUrl');

        // Cache busting param
        return '$downloadUrl?t=${DateTime.now().millisecondsSinceEpoch}';
      } else {
        debugPrint(
          '❌ [StorageService] Upload failed or cancelled. State: ${snapshot.state}',
        );
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
        debugPrint(
          '🗑️ [StorageService] Skipping base64 image (not in Storage)',
        );
        return;
      }

      if (_backendAuthService.isEnabled) {
        final fileName = _extractStoredFileName(downloadUrl);
        if (fileName == null) {
          debugPrint(
            '⚠️ [StorageService] Could not resolve backend file name from URL',
          );
          return;
        }

        final accessToken = await _backendAuthService.getValidAccessToken(
          firebaseUser: FirebaseAuth.instance.currentUser,
        );

        if (accessToken == null || accessToken.isEmpty) {
          throw Exception('Backend access token could not be obtained.');
        }

        final response = await _httpClient.delete(
          _buildUri('/api/storage/$fileName'),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $accessToken',
          },
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          debugPrint('✅ [StorageService] File deleted via backend: $fileName');
          return;
        }

        debugPrint(
          '❌ [StorageService] Backend delete failed: ${response.statusCode} ${response.body}',
        );
        return;
      }

      final ref = _storage.refFromURL(downloadUrl);
      await ref.delete();
      debugPrint('✅ [StorageService] File deleted: $downloadUrl');
    } catch (e) {
      debugPrint('❌ [StorageService] Error deleting file: $e');
    }
  }

  Future<String?> _uploadBytesViaApi(
    Uint8List bytes, {
    required String fileName,
    required String contentType,
  }) async {
    final accessToken = await _backendAuthService.getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    );

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Backend access token could not be obtained.');
    }

    final request = http.MultipartRequest(
      'POST',
      _buildUri('/api/storage/upload'),
    );
    request.headers['Authorization'] = 'Bearer $accessToken';
    request.headers['Accept'] = 'application/json';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Failed to upload file. Status: ${response.statusCode}. Body: ${response.body}',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    return payload['url'] as String?;
  }

  Uri _buildUri(String path) {
    final baseUrl = ApiConfig.baseUrl;
    final normalizedBase =
        baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;
    return Uri.parse('$normalizedBase$path');
  }

  String? _extractStoredFileName(String url) {
    const storageSegment = '/storage/';
    final markerIndex = url.indexOf(storageSegment);
    if (markerIndex < 0) {
      return null;
    }

    var fileName = url.substring(markerIndex + storageSegment.length);
    final queryIndex = fileName.indexOf(RegExp(r'[?#]'));
    if (queryIndex >= 0) {
      fileName = fileName.substring(0, queryIndex);
    }

    return _basename(fileName);
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? path : segments.last;
  }

  String _extension(String path) {
    final name = _basename(path);
    final index = name.lastIndexOf('.');
    if (index <= 0 || index == name.length - 1) {
      return '';
    }
    return name.substring(index);
  }
}
