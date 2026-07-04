import 'package:somine_app/core/models/item_model.dart';

class ContentPreviewPolicy {
  const ContentPreviewPolicy._();

  static bool isMapUrl(String? url) {
    final lower = (url ?? '').toLowerCase();
    return isGoogleMapsUrl(lower) ||
        isYandexMapsUrl(lower) ||
        isAppleMapsUrl(lower) ||
        lower.contains('openstreetmap.org');
  }

  static bool isGoogleMapsUrl(String? url) {
    final lower = (url ?? '').toLowerCase();
    return lower.contains('maps.app.goo.gl') ||
        lower.contains('goo.gl/maps') ||
        lower.contains('google.com/maps') ||
        lower.contains('maps.google.com') ||
        lower.contains('maps.google') ||
        lower.contains('share.google');
  }

  static bool isYandexMapsUrl(String? url) {
    final lower = (url ?? '').toLowerCase();
    return lower.contains('yandex.com/maps') ||
        lower.contains('yandex.ru/maps') ||
        lower.contains('yandex.o/maps');
  }

  static bool isAppleMapsUrl(String? url) {
    final lower = (url ?? '').toLowerCase();
    return lower.contains('maps.apple.com');
  }

  static bool isXUrl(String? url) {
    final lower = (url ?? '').toLowerCase();
    return lower.contains('twitter.com') ||
        lower.contains('//x.com') ||
        lower.contains('.x.com') ||
        (lower.contains('x.com') &&
            !lower.contains('yandex') &&
            !lower.contains('netflix') &&
            !lower.contains('box.com'));
  }

  static bool canUsePreviewImage({
    required String? url,
    required String? imageUrl,
  }) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return false;
    }

    if (imageUrl.toLowerCase().contains('.svg')) {
      return false;
    }

    if (isMapUrl(url)) {
      return false;
    }

    return true;
  }

  static bool shouldShowMissingPreviewLabel({
    required String? url,
    required bool hasImage,
    required bool isKnownBrandSite,
  }) {
    if (hasImage || isMapUrl(url) || isXUrl(url)) {
      return false;
    }

    return !isKnownBrandSite;
  }

  static OGMetadata? sanitizeMetadataForUrl(String? url, OGMetadata? metadata) {
    if (metadata == null || !isMapUrl(url)) {
      return metadata;
    }

    if (metadata.imageUrl == null || metadata.imageUrl!.isEmpty) {
      return metadata;
    }

    return metadata.copyWith(imageUrl: null);
  }
}
