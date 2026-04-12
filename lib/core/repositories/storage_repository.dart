import 'dart:io';
import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';
import 'package:somine_app/core/utils/auth_image_provider.dart';

class StorageRepository {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = const Uuid();
  final BackendAuthService _backendAuthService = BackendAuthService();

  /// Uploads a file to Firebase Storage
  /// Returns the download URL
  Future<String> uploadFile(
    File file,
    String path, {
    String? contentType,
  }) async {
    try {
      if (_backendAuthService.isEnabled) {
        final uploadedUrl = await _uploadFileViaApi(
          fileBytes: await file.readAsBytes(),
          originalFileName: _basename(path.isNotEmpty ? path : file.path),
          contentType: contentType ?? _inferContentTypeFromPath(file.path),
        );

        if (uploadedUrl == null) {
          throw Exception('File upload failed.');
        }

        return uploadedUrl;
      }

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
  Future<String?> persistenceImageFromUrl(
    String userId,
    String sourceUrl,
  ) async {
    if (sourceUrl.isEmpty) return null;

    // Safety: If it's already a firebase URL, don't re-upload
    if (sourceUrl.contains('firebasestorage.googleapis.com') ||
        sourceUrl.contains('/storage/')) {
      return sourceUrl;
    }

    try {
      // 1. Download the image
      final response = await http.get(
        Uri.parse(sourceUrl),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
          'Referer': resolveRefererForUrl(sourceUrl),
          'Accept': 'image/webp,image/avif,image/*,*/*;q=0.8',
        },
      );
      if (response.statusCode != 200) {
        throw Exception(
          'Failed to download image source. Status: ${response.statusCode}',
        );
      }

      // 2. Determine content type
      String contentType = 'image/jpeg'; // Default
      final headerType = response.headers['content-type'];
      if (headerType != null && headerType.startsWith('image/')) {
        contentType = headerType;
      }

      if (_backendAuthService.isEnabled) {
        return _uploadFileViaApi(
          fileBytes: response.bodyBytes,
          originalFileName:
              '${_uuid.v4()}.${_extensionFromContentType(contentType)}',
          contentType: contentType,
        );
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

  Future<String?> _uploadFileViaApi({
    required List<int> fileBytes,
    required String originalFileName,
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
    if (ApiConfig.apiKey.isNotEmpty) {
      request.headers['X-SoMine-Api-Key'] = ApiConfig.apiKey;
    }
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: originalFileName,
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

  String _inferContentTypeFromPath(String path) {
    final extension = _extension(path).toLowerCase();
    switch (extension) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.heic':
        return 'image/heic';
      case '.heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
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

  String _extensionFromContentType(String contentType) {
    if (contentType.contains('png')) return 'png';
    if (contentType.contains('webp')) return 'webp';
    if (contentType.contains('gif')) return 'gif';
    if (contentType.contains('heic')) return 'heic';
    if (contentType.contains('heif')) return 'heif';
    return 'jpg';
  }
}
