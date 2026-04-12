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

/// Builds a [CachedNetworkImage] that automatically injects an
/// Authorization header for our private API storage images.
/// Falls back to a plain [CachedNetworkImage] for external URLs.
Widget buildAuthImage({
  required String imageUrl,
  BoxFit fit = BoxFit.cover,
  Widget Function(BuildContext, String)? placeholder,
  Widget Function(BuildContext, String, dynamic)? errorWidget,
}) {
  if (!isApiStorageUrl(imageUrl)) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }

  return FutureBuilder<String?>(
    future: BackendAuthService().getValidAccessToken(
      firebaseUser: FirebaseAuth.instance.currentUser,
    ),
    builder: (context, snapshot) {
      final token = snapshot.data;
      return CachedNetworkImage(
        imageUrl: imageUrl,
        httpHeaders: token != null ? {'Authorization': 'Bearer $token'} : {},
        fit: fit,
        placeholder: placeholder,
        errorWidget: errorWidget,
      );
    },
  );
}
