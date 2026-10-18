import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/services/backend_auth_service.dart';

/// Returns true if this image URL needs an Authorization header
/// (i.e. it points to our own API storage endpoint)
bool isApiStorageUrl(String? url) {
  if (url == null || url.isEmpty) return false;
  return url.contains(ApiConfig.baseUrl) && url.contains('/api/storage/');
}

Map<String, String> _externalImageHeaders(String url) {
  return {
    'Referer': resolveRefererForUrl(url),
    'User-Agent':
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1',
  };
}

Future<Map<String, String>> resolveImageHeaders(String imageUrl) async {
  if (!isApiStorageUrl(imageUrl)) {
    return _externalImageHeaders(imageUrl);
  }

  final token = await BackendAuthService().getValidAccessToken(
    firebaseUser: FirebaseAuth.instance.currentUser,
  );

  return {
    if (ApiConfig.apiKey.isNotEmpty) 'X-SoMine-Api-Key': ApiConfig.apiKey,
    if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
  };
}

String resolveRefererForUrl(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  const cdnToMain = {
    'i.pinimg.com': 'https://www.pinterest.com/',
    'pinimg.com': 'https://www.pinterest.com/',
    'cdninstagram.com': 'https://www.instagram.com/',
    'static.cdninstagram.com': 'https://www.instagram.com/',
    'scontent.cdninstagram.com': 'https://www.instagram.com/',
    'fbcdn.net': 'https://www.facebook.com/',
    'pbs.twimg.com': 'https://twitter.com/',
    'tiktokcdn.com': 'https://www.tiktok.com/',
  };
  for (final entry in cdnToMain.entries) {
    if (host.endsWith(entry.key)) return entry.value;
  }
  return 'https://$host/';
}

/// Builds a [CachedNetworkImage] that automatically injects an
/// Authorization header for our private API storage images.
/// Falls back to a plain [CachedNetworkImage] for external URLs.
Widget buildAuthImage({
  required String imageUrl,
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Alignment alignment = Alignment.center,
  Widget Function(BuildContext, String)? placeholder,
  Widget Function(BuildContext, String, dynamic)? errorWidget,
}) {
  if (!isApiStorageUrl(imageUrl)) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: _externalImageHeaders(imageUrl),
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      placeholder: placeholder,
      errorWidget: (ctx, url, err) {
        return errorWidget?.call(ctx, url, err) ?? const SizedBox.shrink();
      },
    );
  }

  return FutureBuilder<Map<String, String>>(
    future: resolveImageHeaders(imageUrl),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return placeholder?.call(context, imageUrl) ?? const SizedBox.shrink();
      }
      final headers = snapshot.data!;
      return CachedNetworkImage(
        imageUrl: imageUrl,
        cacheKey: '${imageUrl}_auth',
        httpHeaders: headers,
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        placeholder: placeholder,
        errorWidget: (ctx, url, err) {
          return errorWidget?.call(ctx, url, err) ?? const SizedBox.shrink();
        },
      );
    },
  );
}
