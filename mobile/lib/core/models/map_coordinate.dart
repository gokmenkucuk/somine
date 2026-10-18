/// Model for representing map coordinates extracted from various map service URLs
class MapCoordinate {
  final double latitude;
  final double longitude;
  final String originalUrl;
  final MapProvider provider;
  final String? placeName;

  const MapCoordinate({
    required this.latitude,
    required this.longitude,
    required this.originalUrl,
    required this.provider,
    this.placeName,
  });

  /// Validates if coordinates are within valid ranges
  bool get isValid {
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Returns a formatted coordinate string
  String get coordinateString => '$latitude,$longitude';

  @override
  String toString() {
    return 'MapCoordinate(lat: $latitude, lng: $longitude, provider: $provider)';
  }

  /// Creates a copy with modified fields
  MapCoordinate copyWith({
    double? latitude,
    double? longitude,
    String? originalUrl,
    MapProvider? provider,
    String? placeName,
  }) {
    return MapCoordinate(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      originalUrl: originalUrl ?? this.originalUrl,
      provider: provider ?? this.provider,
      placeName: placeName ?? this.placeName,
    );
  }
}

/// Enum representing different map service providers
enum MapProvider {
  googleMaps,
  yandexMaps,
  appleMaps,
  unknown,
}

/// Extension to get display name for MapProvider
extension MapProviderExtension on MapProvider {
  String get displayName {
    switch (this) {
      case MapProvider.googleMaps:
        return 'Google Maps';
      case MapProvider.yandexMaps:
        return 'Yandex Maps';
      case MapProvider.appleMaps:
        return 'Apple Maps';
      case MapProvider.unknown:
        return 'Unknown';
    }
  }

  /// Returns the action text for opening in original app
  String get openActionText {
    switch (this) {
      case MapProvider.googleMaps:
        return 'Google\'da aç';
      case MapProvider.yandexMaps:
        return 'Yandex\'te aç';
      case MapProvider.appleMaps:
        return 'Apple Maps\'te aç';
      case MapProvider.unknown:
        return 'Haritada aç';
    }
  }
}
