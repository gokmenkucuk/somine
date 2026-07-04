import 'dart:async' hide TimeoutException;
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/exceptions/network_exceptions.dart';
import 'package:somine_app/core/services/api_client.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';
import 'package:somine_app/core/utils/auth_image_provider.dart';

class StorageService {
  final BackendAuthService _backendAuthService = BackendAuthService();
  final ApiClient _apiClient = ApiClient();
  static const Duration _uploadTimeout = Duration(seconds: 60);

  /// Uploads an image from a URL to backend storage
  /// Returns the file URL or null if failed
  Future<String?> uploadImageFromUrl(String url, String userId) async {
    try {
      if (url.contains('/storage/')) {
        return url;
      }

      // 1. Download image
      final uri = Uri.parse(url);
      final referer = resolveRefererForUrl(url);
      final response = await _apiClient.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
          'Referer': referer,
          'Accept': 'image/webp,image/avif,image/*,*/*;q=0.8',
        },
      );
      if (response.statusCode != 200) {
        debugPrint(
          '❌ [StorageService] Failed to download image: ${response.statusCode} url=$url',
        );
        return null;
      }

      final headerType = response.headers['content-type'];
      final contentType =
          headerType != null && headerType.startsWith('image/')
              ? headerType
              : _getContentType(_getExtensionFromUrl(url));

      return await _uploadBytesViaApi(
        response.bodyBytes,
        fileName:
            '${DateTime.now().millisecondsSinceEpoch}${_getExtensionFromUrl(url)}',
        contentType: contentType,
      );
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

  /// Uploads a file to backend storage
  /// Returns the file URL or null if failed
  Future<String?> uploadFile(File file, String path) async {
    try {
      return await _uploadBytesViaApi(
        await file.readAsBytes(),
        fileName: _basename(path.isNotEmpty ? path : file.path),
        contentType: _getContentType(_extension(file.path).toLowerCase()),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [StorageService] Error: $e');
      debugPrint('❌ [StorageService] Stack: $stackTrace');
      return null;
    }
  }

  /// Uploads bytes to backend storage
  /// Returns the file URL or null if failed
  Future<String?> uploadBytes(Uint8List bytes, String path) async {
    try {
      return await _uploadBytesViaApi(
        bytes,
        fileName: _basename(path),
        contentType: _getContentType(_extension(path).toLowerCase()),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [StorageService] Error: $e');
      debugPrint('❌ [StorageService] Stack: $stackTrace');
      return null;
    }
  }

  Future<String?> uploadProfileImage(File file, String userId) async {
    try {
      final uploadedUrl = await _uploadBytesViaApi(
        await file.readAsBytes(),
        fileName: 'profile_$userId.jpg',
        contentType: 'image/jpeg',
      );

      if (uploadedUrl == null) {
        return null;
      }

      return '$uploadedUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      debugPrint('❌ [StorageService] Error uploading profile image: $e');
      return null;
    }
  }

  /// Delete file from backend storage
  Future<void> deleteFile(String downloadUrl) async {
    try {
      // Handle base64 data URLs - can't delete from Storage
      if (downloadUrl.startsWith('data:')) {
        debugPrint(
          '🗑️ [StorageService] Skipping base64 image (not in Storage)',
        );
        return;
      }

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
        throw const UnauthorizedException(
          'backend access token missing',
          userMessage: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
        );
      }

      final response = await _apiClient.delete(
        _buildUri('/api/storage/$fileName'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $accessToken',
          if (ApiConfig.apiKey.isNotEmpty) 'X-SoMine-Api-Key': ApiConfig.apiKey,
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        debugPrint('✅ [StorageService] File deleted via backend: $fileName');
        return;
      }

      debugPrint(
        '❌ [StorageService] Backend delete failed: ${response.statusCode}',
      );
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
      throw const UnauthorizedException(
        'backend access token missing',
        userMessage: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
      );
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
        bytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      ),
    );

    final streamedResponse = await request.send().timeout(
      _uploadTimeout,
      onTimeout:
          () => throw const TimeoutException(
            'upload file timed out',
            userMessage: 'Yükleme zaman aşımına uğradı. Lütfen tekrar deneyin.',
          ),
    );
    final response = await http.Response.fromStream(streamedResponse).timeout(
      _uploadTimeout,
      onTimeout:
          () => throw const TimeoutException(
            'read upload response timed out',
            userMessage: 'Yükleme zaman aşımına uğradı. Lütfen tekrar deneyin.',
          ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('API Error [upload file]: ${response.statusCode}');
      throw switch (response.statusCode) {
        401 => const UnauthorizedException(
          'upload file unauthorized',
          userMessage: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.',
        ),
        409 => const ConflictException(
          'upload file conflict',
          userMessage: 'Bu işlem zaten yapıldı.',
        ),
        >= 400 && < 500 => ValidationException(
          'upload file failed',
          userMessage: _parseApiError(response.body),
        ),
        >= 500 => const ServerException(
          'upload file server error',
          userMessage: 'Sunucu hatası oluştu. Lütfen biraz sonra tekrar deneyin.',
        ),
        _ => const ServerException(
          'upload file failed',
          userMessage: 'Dosya yüklenemedi. Lütfen tekrar deneyin.',
        ),
      };
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

  String _parseApiError(String responseBody) {
    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>?;
      return json?['message'] as String? ??
          json?['error'] as String? ??
          'Dosya yüklenemedi. Lütfen tekrar deneyin.';
    } catch (_) {
      return 'Dosya yüklenemedi. Lütfen tekrar deneyin.';
    }
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
