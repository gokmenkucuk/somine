import 'dart:async' hide TimeoutException;
import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:uuid/uuid.dart';
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/exceptions/network_exceptions.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';
import 'package:somine_app/core/utils/auth_image_provider.dart';

class StorageRepository {
  final Uuid _uuid = const Uuid();
  final BackendAuthService _backendAuthService = BackendAuthService();
  final http.Client _httpClient = http.Client();
  static const Duration _requestTimeout = Duration(seconds: 15);
  static const Duration _uploadTimeout = Duration(seconds: 60);

  /// Uploads a file to backend storage
  /// Returns the file URL
  Future<String> uploadFile(
    File file,
    String path, {
    String? contentType,
  }) async {
    try {
      final uploadedUrl = await _uploadFileViaApi(
        fileBytes: await file.readAsBytes(),
        originalFileName: _basename(path.isNotEmpty ? path : file.path),
        contentType: contentType ?? _inferContentTypeFromPath(file.path),
      );

      if (uploadedUrl == null) {
        throw const ServerException(
          'upload file failed',
          userMessage: 'Dosya yüklenemedi. Lütfen tekrar deneyin.',
        );
      }

      return uploadedUrl;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    }
  }

  /// Downloads an image from a URL and uploads it to backend storage
  /// Returns the persistent storage URL
  ///
  /// [userId] - The folder to store the image in
  /// [sourceUrl] - The original image URL (e.g. from Instagram CDN)
  Future<String?> persistenceImageFromUrl(
    String userId,
    String sourceUrl,
  ) async {
    if (sourceUrl.isEmpty) return null;

    // Safety: already-persisted URLs (backend storage or legacy Firebase
    // Storage links kept from the migration) must not be re-uploaded
    if (sourceUrl.contains('firebasestorage.googleapis.com') ||
        sourceUrl.contains('/storage/')) {
      return sourceUrl;
    }

    try {
      // 1. Download the image
      final response = await _withTimeout(
        _httpClient.get(
          Uri.parse(sourceUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
            'Referer': resolveRefererForUrl(sourceUrl),
            'Accept': 'image/webp,image/avif,image/*,*/*;q=0.8',
          },
        ),
        'download image',
        timeout: _uploadTimeout,
      );
      if (response.statusCode != 200) {
        throw ServerException(
          'download image failed: ${response.statusCode}',
          userMessage: 'Görsel indirilemedi. Lütfen tekrar deneyin.',
        );
      }

      // 2. Determine content type
      String contentType = 'image/jpeg'; // Default
      final headerType = response.headers['content-type'];
      if (headerType != null && headerType.startsWith('image/')) {
        contentType = headerType;
      }

      return await _uploadFileViaApi(
        fileBytes: response.bodyBytes,
        originalFileName:
            '${_uuid.v4()}.${_extensionFromContentType(contentType)}',
        contentType: contentType,
      );
    } catch (e) {
      debugPrint('Error persisting image: $e');
      // On failure, return null (or could return original URL as fallback)
      return null;
    }
  }

  Future<void> deleteAllUserFiles(String userId) async {
    // Storage cleanup happens server-side via DELETE /api/users/me
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
        fileBytes,
        filename: originalFileName,
        contentType: MediaType.parse(contentType),
      ),
    );

    final streamedResponse = await _withTimeout(
      request.send(),
      'upload file',
      timeout: _uploadTimeout,
    );
    final response = await _withTimeout(
      http.Response.fromStream(streamedResponse),
      'read upload response',
      timeout: _uploadTimeout,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint(
        'API Error [upload file]: ${response.statusCode} - ${response.body}',
      );
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
          userMessage:
              'Sunucu hatası oluştu. Lütfen biraz sonra tekrar deneyin.',
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

  Future<T> _withTimeout<T>(
    Future<T> future,
    String action, {
    Duration timeout = _requestTimeout,
  }) {
    return future.timeout(
      timeout,
      onTimeout:
          () =>
              throw TimeoutException(
                '$action timed out after ${timeout.inSeconds} seconds',
                userMessage:
                    'Bağlantı zaman aşımına uğradı. Lütfen tekrar deneyin.',
              ),
    );
  }
}
