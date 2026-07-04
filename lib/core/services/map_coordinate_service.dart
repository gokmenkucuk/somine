import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/map_coordinate.dart';

/// Service for extracting coordinates and place names from various map service URLs
class MapCoordinateService {
  // Timeouts
  static const Duration _resolveTimeout = Duration(seconds: 5);
  static const Duration _geocodeTimeout = Duration(seconds: 5);

  // Cache settings
  static const String _cachePrefix = 'geocache_';
  static const Duration _cacheExpiration = Duration(days: 30);
  static const int _maxCacheEntries = 100;

  // Regex patterns for coordinates
  static final RegExp _googleAtPattern =
      RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)');
  static final RegExp _googleQPattern =
      RegExp(r'[?&]q=(-?\d+\.?\d*),(-?\d+\.?\d*)');
  static final RegExp _googlePlacePattern =
      RegExp(r'@(-?\d+\.?\d*),(-?\d+\.?\d*)');

  static final RegExp _yandexPtPattern =
      RegExp(r'[?&]pt=(-?\d+\.?\d*),(-?\d+\.?\d*)');
  static final RegExp _yandexLlPattern =
      RegExp(r'[?&]ll=(-?\d+\.?\d*),(-?\d+\.?\d*)');

  // Regex patterns for place names in URLs
  static final RegExp _googlePlacePathPattern =
      RegExp(r'/place/([^/@]+)');
  static final RegExp _googleQueryPattern = RegExp(r'[?&]q=([^&]+)');
  static final RegExp _yandexOrgPattern = RegExp(r'orgpage/([^/]+)');
  static final RegExp _yandexTextPattern = RegExp(r'[?&]text=([^&]+)');
  static final RegExp _yandexGeoPattern = RegExp(r'/geo/([^/]+)');
  static final RegExp _appleQueryPattern = RegExp(r'[?&]q=([^&]+)');
  static final RegExp _appleAddressPattern = RegExp(r'[?&]address=([^&]+)');

  /// Extracts coordinates and place name from a map URL
  ///
  /// Returns [MapCoordinate] if coordinates are found, null otherwise.
  /// Handles short links by resolving redirects first.
  /// Attempts to extract place name from URL patterns or via reverse geocoding.
  static Future<MapCoordinate?> extract(String url) async {
    try {
      debugPrint('🔍 [MapCoordinate] Extracting from: $url');

      // Determine provider
      final provider = _detectProvider(url);
      if (provider == MapProvider.unknown) {
        debugPrint('⚠️ [MapCoordinate] Unknown provider');
        return null;
      }
      debugPrint('✅ [MapCoordinate] Provider: $provider');

      // Resolve short links if needed
      String finalUrl = url;
      if (_isShortLink(url)) {
        debugPrint('🔄 [MapCoordinate] Resolving short link...');
        finalUrl = await _resolveShortLink(url) ?? url;
        debugPrint('🔄 [MapCoordinate] Resolved to: $finalUrl');
      }

      // Extract coordinates based on provider
      MapCoordinate? coordinate;
      if (provider == MapProvider.googleMaps) {
        coordinate = _extractGoogleMaps(finalUrl);
      } else if (provider == MapProvider.yandexMaps) {
        coordinate = _extractYandexMaps(finalUrl);
      } else {
        // Apple Maps - try to extract coordinates
        coordinate = _extractAppleMaps(finalUrl);
      }

      // LAYER 2: Try extracting from HTML page content if URL parsing failed
      if ((coordinate == null || !coordinate.isValid) && _isShortLink(url)) {
        debugPrint('🌐 [MapCoordinate] URL parsing failed, trying HTML extraction');
        coordinate = await _extractFromHtmlPage(finalUrl, provider);
      }

      if (coordinate == null) {
        debugPrint('⚠️ [MapCoordinate] No coordinates found');
        return null;
      }

      if (!coordinate.isValid) {
        debugPrint('⚠️ [MapCoordinate] Invalid coordinates: ${coordinate.latitude}, ${coordinate.longitude}');
        return null;
      }

      debugPrint('✅ [MapCoordinate] Found coordinates: ${coordinate.latitude}, ${coordinate.longitude}');

      // Try to extract place name from URL patterns first (fast, local)
      String? placeName = _extractPlaceNameFromUrl(finalUrl, provider);

      // If no place name found, try reverse geocoding (slower, API call)
      if (placeName == null || placeName.isEmpty) {
        debugPrint('🌐 [MapCoordinate] No place name in URL, trying reverse geocoding...');
        placeName = await _reverseGeocode(
          coordinate.latitude,
          coordinate.longitude,
        );
        if (placeName != null) {
          debugPrint('✅ [MapCoordinate] Reverse geocoded: $placeName');
        }
      }

      // Return coordinate with place name
      return MapCoordinate(
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        originalUrl: url,
        provider: provider,
        placeName: placeName,
      );
    } catch (e) {
      debugPrint('🔴 [MapCoordinate] Extraction error: $e');
      return null;
    }
  }

  /// Extracts place name from URL path/query parameters
  static String? _extractPlaceNameFromUrl(String url, MapProvider provider) {
    try {
      String? rawName;

      switch (provider) {
        case MapProvider.googleMaps:
          // Try /place/ path first
          Match? match = _googlePlacePathPattern.firstMatch(url);
          if (match != null) {
            rawName = match.group(1);
          }
          // Fallback to ?q= parameter
          if (rawName == null) {
            match = _googleQueryPattern.firstMatch(url);
            if (match != null) {
              final qValue = match.group(1);
              // Only use if not coordinates (contains comma and numbers)
              if (qValue != null && !RegExp(r'^-?\d+\.?\d*,-?\d+\.?\d*$').hasMatch(qValue)) {
                rawName = qValue;
              }
            }
          }
          break;

        case MapProvider.yandexMaps:
          // Try orgpage pattern first
          Match? match = _yandexOrgPattern.firstMatch(url);
          if (match != null) {
            rawName = match.group(1);
          }
          // Try ?text= parameter
          if (rawName == null) {
            match = _yandexTextPattern.firstMatch(url);
            if (match != null) {
              rawName = match.group(1);
            }
          }
          // Try /geo/ pattern
          if (rawName == null) {
            match = _yandexGeoPattern.firstMatch(url);
            if (match != null) {
              rawName = match.group(1);
            }
          }
          break;

        case MapProvider.appleMaps:
          // Try ?q= parameter
          Match? match = _appleQueryPattern.firstMatch(url);
          if (match != null) {
            final qValue = match.group(1);
            // Only use if not coordinates
            if (qValue != null && !RegExp(r'^-?\d+\.?\d*,-?\d+\.?\d*$').hasMatch(qValue)) {
              rawName = qValue;
            }
          }
          // Try ?address= parameter
          if (rawName == null) {
            match = _appleAddressPattern.firstMatch(url);
            if (match != null) {
              rawName = match.group(1);
            }
          }
          break;

        default:
          break;
      }

      if (rawName != null) {
        final cleanedName = _cleanExtractedName(rawName);
        if (!_isGenericPlaceName(cleanedName)) {
          return cleanedName;
        }
      }
    } catch (e) {
      // Silently fail on extraction errors
    }
    return null;
  }

  /// Performs reverse geocoding using Nominatim API
  static Future<String?> _reverseGeocode(double lat, double lng) async {
    try {
      // Check cache first
      final cached = await _getCachedPlaceName(lat, lng);
      if (cached != null) {
        return cached;
      }

      // Build Nominatim API URL
      final url = 'https://nominatim.openstreetmap.org/reverse?'
          'format=json&'
          'lat=$lat&'
          'lon=$lng&'
          'zoom=18&'
          'addressdetails=0';

      // Make request with proper User-Agent (required by Nominatim policy)
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SoMine App (iOS - contact for API issues)',
          'Accept': 'application/json',
        },
      ).timeout(_geocodeTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        String? placeName = data['display_name'] as String?;

        if (placeName != null) {
          placeName = _simplifyPlaceName(placeName);
          if (placeName.isNotEmpty) {
            await _cachePlaceName(lat, lng, placeName);
            return placeName;
          }
        }
      } else if (response.statusCode == 429) {
        // Rate limited
        debugPrint('⚠️ [MapCoordinate] Nominatim rate limit exceeded');
      }
    } catch (e) {
      debugPrint('⚠️ [MapCoordinate] Reverse geocoding failed: $e');
    }

    return null;
  }

  /// Simplifies Nominatim's verbose display_name
  /// "Starbucks Coffee, 123 Market St, San Francisco, CA, USA"
  /// → "Starbucks Coffee"
  static String _simplifyPlaceName(String fullName) {
    // Split by comma, take first meaningful part
    final parts = fullName.split(',');
    if (parts.isNotEmpty) {
      var name = parts[0].trim();
      // Filter out house numbers (starts with digits)
      if (RegExp(r'^\d+\s').hasMatch(name)) {
        name = parts.length > 1 ? parts[1].trim() : name;
      }
      return name;
    }
    return fullName;
  }

  /// Cleans extracted name from URL
  /// Replaces + and _ with spaces, URL decodes, trims
  static String _cleanExtractedName(String name) {
    return name
        .replaceAll('+', ' ')
        .replaceAll('_', ' ')
        .replaceAll('%20', ' ')
        .replaceAll('%2B', ' ')
        .trim();
  }

  /// Checks if place name is too generic to be useful
  static bool _isGenericPlaceName(String name) {
    final genericTerms = [
      'place',
      'map',
      'maps',
      'google',
      'yandex',
      'apple',
      'location',
      'coordinate',
      'poi',
      'point',
    ];

    final lowerName = name.toLowerCase();
    return genericTerms.any((term) => lowerName == term) ||
        name.length < 3 ||
        RegExp(r'^\d+$').hasMatch(name);
  }

  /// Gets cached place name for coordinates
  static Future<String?> _getCachedPlaceName(double lat, double lng) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKey(lat, lng);
      final cached = prefs.getString(key);

      if (cached != null) {
        // Check expiration
        final timestampKey = '${key}_ts';
        final timestamp = prefs.getInt(timestampKey);
        if (timestamp != null) {
          final age = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (age < _cacheExpiration.inMilliseconds) {
            return cached;
          } else {
            // Expired, remove
            await prefs.remove(key);
            await prefs.remove(timestampKey);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MapCoordinate] Cache read error: $e');
    }
    return null;
  }

  /// Caches place name for coordinates
  static Future<void> _cachePlaceName(
    double lat,
    double lng,
    String name,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _cacheKey(lat, lng);
      final timestampKey = '${key}_ts';

      await prefs.setString(key, name);
      await prefs.setInt(
        timestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      // Cleanup old entries
      await _cleanupCache(prefs);
    } catch (e) {
      debugPrint('⚠️ [MapCoordinate] Cache write error: $e');
    }
  }

  /// Generates cache key for coordinates
  /// Rounds to 6 decimal places (~100m precision)
  static String _cacheKey(double lat, double lng) {
    final roundedLat = (lat * 1e6).round() / 1e6;
    final roundedLng = (lng * 1e6).round() / 1e6;
    return '$_cachePrefix${roundedLat}_$roundedLng';
  }

  /// Cleans up old cache entries, keeping only _maxCacheEntries
  static Future<void> _cleanupCache(SharedPreferences prefs) async {
    try {
      final keys = prefs.getKeys()
          .where((k) => k.startsWith(_cachePrefix))
          .toList();

      if (keys.length > _maxCacheEntries) {
        // Get timestamps
        final entries = keys.map((k) {
          final timestampKey = '${k}_ts';
          final timestamp = prefs.getInt(timestampKey) ?? 0;
          return MapEntry(k, timestamp);
        }).toList();

        // Sort by timestamp (oldest first)
        entries.sort((a, b) => a.value.compareTo(b.value));

        // Remove oldest 20 entries
        for (int i = 0;
            i < 20 && i < entries.length;
            i++) {
          await prefs.remove(entries[i].key);
          await prefs.remove('${entries[i].key}_ts');
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MapCoordinate] Cache cleanup error: $e');
    }
  }

  /// Detects which map service the URL belongs to
  static MapProvider _detectProvider(String url) {
    final lowerUrl = url.toLowerCase();

    if (lowerUrl.contains('google.com/maps') ||
        lowerUrl.contains('maps.google.com') ||
        lowerUrl.contains('maps.app.goo.gl') ||
        lowerUrl.contains('goo.gl/maps') ||
        lowerUrl.contains('share.google')) {
      return MapProvider.googleMaps;
    }

    if (lowerUrl.contains('yandex.com/maps') ||
        lowerUrl.contains('yandex.ru/maps') ||
        (lowerUrl.contains('yandex.') && lowerUrl.contains('/maps/'))) {
      return MapProvider.yandexMaps;
    }

    if (lowerUrl.contains('maps.apple.com')) {
      return MapProvider.appleMaps;
    }

    return MapProvider.unknown;
  }

  /// Checks if URL is a short link
  static bool _isShortLink(String url) {
    return url.contains('maps.app.goo.gl') ||
        url.contains('goo.gl/maps') ||
        url.contains('yandex.com/maps/-/');
  }

  /// Resolves short link by following HTTP redirects
  /// Enhanced with GET fallback and better redirect handling
  static Future<String?> _resolveShortLink(String url) async {
    String? finalUrl;

    try {
      // Try HEAD first (faster, less data)
      finalUrl = await _resolveWithMethod(url, 'HEAD');

      // If HEAD didn't work, try GET (more reliable)
      if (finalUrl == null || finalUrl == url) {
        debugPrint('🔄 [MapCoordinate] HEAD failed, trying GET');
        finalUrl = await _resolveWithMethod(url, 'GET');
      }

      if (finalUrl != null && finalUrl != url) {
        debugPrint('✅ [MapCoordinate] Resolved: $url -> $finalUrl');
      }

      return finalUrl ?? url;
    } catch (e) {
      debugPrint('⚠️ [MapCoordinate] Short link resolution error: $e');
      return url;
    }
  }

  /// Helper to resolve with specific HTTP method
  static Future<String?> _resolveWithMethod(String url, String method) async {
    try {
      final client = http.Client();
      final request = http.Request(method, Uri.parse(url))
        ..followRedirects = false
        ..headers.addAll({
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        });

      final response = await client.send(request).timeout(_resolveTimeout);

      String? finalUrl = response.headers['location'];

      // Follow up to 5 redirects (increased from 3)
      int redirectCount = 0;
      while (finalUrl != null &&
          (response.statusCode == 301 ||
              response.statusCode == 302 ||
              response.statusCode == 303 ||
              response.statusCode == 307 ||
              response.statusCode == 308) &&
          redirectCount < 5) {
        final redirectRequest = http.Request(method, Uri.parse(finalUrl))
          ..followRedirects = false
          ..headers.addAll({
            'User-Agent':
                'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15',
            'Accept':
                'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          });

        final redirectResponse =
            await client.send(redirectRequest).timeout(_resolveTimeout);

        final nextUrl = redirectResponse.headers['location'];
        if (nextUrl == null || nextUrl == finalUrl) break;

        finalUrl = nextUrl;
        redirectCount++;
        debugPrint('  ↪ [MapCoordinate] Redirect $redirectCount: $finalUrl');
      }

      client.close();
      return finalUrl;
    } catch (e) {
      debugPrint('⚠️ [MapCoordinate] $method resolution failed: $e');
      return null;
    }
  }

  /// Extracts coordinates from Google Maps URL
  static MapCoordinate? _extractGoogleMaps(String url) {
    // Try @format first: google.com/maps/@37.7749,-122.4194,15z
    Match? match = _googleAtPattern.firstMatch(url);
    if (match != null) {
      final lat = double.tryParse(match.group(1) ?? '');
      final lng = double.tryParse(match.group(2) ?? '');
      if (lat != null && lng != null) {
        return MapCoordinate(
          latitude: lat,
          longitude: lng,
          originalUrl: url,
          provider: MapProvider.googleMaps,
        );
      }
    }

    // Try ?q= format: google.com/maps?q=37.7749,-122.4194
    match = _googleQPattern.firstMatch(url);
    if (match != null) {
      final lat = double.tryParse(match.group(1) ?? '');
      final lng = double.tryParse(match.group(2) ?? '');
      if (lat != null && lng != null) {
        debugPrint('✅ [MapCoordinate] Found ?q=lat,lng pattern');
        return MapCoordinate(
          latitude: lat,
          longitude: lng,
          originalUrl: url,
          provider: MapProvider.googleMaps,
        );
      }
    }

    // Try place format
    match = _googlePlacePattern.firstMatch(url);
    if (match != null) {
      final lat = double.tryParse(match.group(1) ?? '');
      final lng = double.tryParse(match.group(2) ?? '');
      if (lat != null && lng != null) {
        debugPrint('✅ [MapCoordinate] Found @lat,lng pattern');
        return MapCoordinate(
          latitude: lat,
          longitude: lng,
          originalUrl: url,
          provider: MapProvider.googleMaps,
        );
      }
    }

    // NEW: Try !1d!2d format: !1d-122.4194!2d37.7749 (note: reversed order - lng,lat)
    final revPattern = RegExp(r'!1d(-?\d+\.?\d*)!2d(-?\d+\.?\d*)');
    match = revPattern.firstMatch(url);
    if (match != null) {
      final lng = double.tryParse(match.group(1) ?? ''); // Longitude first
      final lat = double.tryParse(match.group(2) ?? ''); // Latitude second
      if (lat != null && lng != null) {
        debugPrint('✅ [MapCoordinate] Found !1d!2d pattern (reversed)');
        return MapCoordinate(
          latitude: lat,
          longitude: lng,
          originalUrl: url,
          provider: MapProvider.googleMaps,
        );
      }
    }

    // NEW: Try ll= format (some variants)
    final llPattern = RegExp(r'[?&]ll=(-?\d+\.?\d*),(-?\d+\.?\d*)');
    match = llPattern.firstMatch(url);
    if (match != null) {
      final lat = double.tryParse(match.group(1) ?? '');
      final lng = double.tryParse(match.group(2) ?? '');
      if (lat != null && lng != null) {
        debugPrint('✅ [MapCoordinate] Found ll=lat,lng pattern');
        return MapCoordinate(
          latitude: lat,
          longitude: lng,
          originalUrl: url,
          provider: MapProvider.googleMaps,
        );
      }
    }

    debugPrint('⚠️ [MapCoordinate] No coordinate patterns matched in URL');
    return null;
  }

  /// Extracts coordinates from Yandex Maps URL
  ///
  /// IMPORTANT: Yandex uses lng,lat order (longitude, latitude)
  static MapCoordinate? _extractYandexMaps(String url) {
    // Try ?pt= format: yandex.com/maps/?pt=37.6173,55.7558
    // Note: pt=lng,lat (longitude FIRST, latitude SECOND)
    Match? match = _yandexPtPattern.firstMatch(url);
    if (match != null) {
      final lng = double.tryParse(match.group(1) ?? ''); // Longitude first
      final lat = double.tryParse(match.group(2) ?? ''); // Latitude second
      if (lat != null && lng != null) {
        return MapCoordinate(
          latitude: lat,
          longitude: lng,
          originalUrl: url,
          provider: MapProvider.yandexMaps,
        );
      }
    }

    // Try ?ll= format: yandex.com/maps/?ll=37.6173,55.7558&z=12
    // Note: ll=lng,lat (longitude FIRST, latitude SECOND)
    match = _yandexLlPattern.firstMatch(url);
    if (match != null) {
      final lng = double.tryParse(match.group(1) ?? ''); // Longitude first
      final lat = double.tryParse(match.group(2) ?? ''); // Latitude second
      if (lat != null && lng != null) {
        return MapCoordinate(
          latitude: lat,
          longitude: lng,
          originalUrl: url,
          provider: MapProvider.yandexMaps,
        );
      }
    }

    return null;
  }

  /// Extracts coordinates from Apple Maps URL
  static MapCoordinate? _extractAppleMaps(String url) {
    // Apple Maps URLs often don't have coordinates in standard format
    // Try ?ll= or similar patterns
    final llPattern = RegExp(r'[?&]ll=(-?\d+\.?\d*),(-?\d+\.?\d*)');
    final match = llPattern.firstMatch(url);

    if (match != null) {
      final lat = double.tryParse(match.group(1) ?? '');
      final lng = double.tryParse(match.group(2) ?? '');
      if (lat != null && lng != null) {
        return MapCoordinate(
          latitude: lat,
          longitude: lng,
          originalUrl: url,
          provider: MapProvider.appleMaps,
        );
      }
    }

    return null;
  }

  /// Extract coordinates from HTML page content (for short links)
  /// Google Maps embeds coordinates in the page as JSON/JavaScript
  static Future<MapCoordinate?> _extractFromHtmlPage(
    String url,
    MapProvider provider,
  ) async {
    try {
      debugPrint('🌐 [MapCoordinate] Fetching HTML page...');
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint('⚠️ [MapCoordinate] HTML fetch failed: ${response.statusCode}');
        return null;
      }

      final html = response.body;

      if (provider == MapProvider.googleMaps) {
        return _extractFromGoogleMapsHtml(html, url);
      } else if (provider == MapProvider.yandexMaps) {
        return _extractFromYandexMapsHtml(html, url);
      }

      return null;
    } catch (e) {
      debugPrint('⚠️ [MapCoordinate] HTML extraction error: $e');
      return null;
    }
  }

  /// Extract coordinates from Google Maps HTML page
  static MapCoordinate? _extractFromGoogleMapsHtml(
    String html,
    String originalUrl,
  ) {
    try {
      // Pattern 1: Look for coordinates in meta tags
      // <meta itemprop="latitude" content="41.0082">
      final latMetaPattern =
          RegExp(r'meta\s+itemprop="latitude"\s+content="(-?\d+\.?\d*)"');
      final lngMetaPattern =
          RegExp(r'meta\s+itemprop="longitude"\s+content="(-?\d+\.?\d*)"');

      final latMatch = latMetaPattern.firstMatch(html);
      final lngMatch = lngMetaPattern.firstMatch(html);

      if (latMatch != null && lngMatch != null) {
        final lat = double.tryParse(latMatch.group(1) ?? '');
        final lng = double.tryParse(lngMatch.group(1) ?? '');
        if (lat != null && lng != null) {
          debugPrint('✅ [MapCoordinate] Found coordinates in meta tags');
          return MapCoordinate(
            latitude: lat,
            longitude: lng,
            originalUrl: originalUrl,
            provider: MapProvider.googleMaps,
          );
        }
      }

      // Pattern 2: Look for !1d(lat)!2d(lng) format in URLs within the page
      final coordPattern = RegExp(r'!1d(-?\d+\.?\d*)!2d(-?\d+\.?\d*)');
      final coordMatch = coordPattern.firstMatch(html);

      if (coordMatch != null) {
        final lng = double.tryParse(coordMatch.group(1) ?? '');
        final lat = double.tryParse(coordMatch.group(2) ?? '');
        if (lat != null && lng != null) {
          debugPrint('✅ [MapCoordinate] Found coordinates in !1d!2d format');
          return MapCoordinate(
            latitude: lat,
            longitude: lng,
            originalUrl: originalUrl,
            provider: MapProvider.googleMaps,
          );
        }
      }

      // Pattern 3: Look for @lat,lng format in data attributes
      final dataPattern =
          RegExp(r'data-url="[^"]*@(-?\d+\.?\d*),(-?\d+\.?\d*)');
      final dataMatch = dataPattern.firstMatch(html);

      if (dataMatch != null) {
        final lat = double.tryParse(dataMatch.group(1) ?? '');
        final lng = double.tryParse(dataMatch.group(2) ?? '');
        if (lat != null && lng != null) {
          debugPrint('✅ [MapCoordinate] Found coordinates in data-url');
          return MapCoordinate(
            latitude: lat,
            longitude: lng,
            originalUrl: originalUrl,
            provider: MapProvider.googleMaps,
          );
        }
      }

      // Pattern 4: NEW - Look for [lat, lng] patterns in JavaScript arrays
      // This catches coordinates in window.APP, window.MS, and other JS objects
      final jsArrayPattern = RegExp(r'\[\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)\s*\]');
      final jsMatches = jsArrayPattern.allMatches(html);

      for (final match in jsMatches) {
        final lat = double.tryParse(match.group(1) ?? '');
        final lng = double.tryParse(match.group(2) ?? '');

        if (lat != null && lng != null) {
          // Validate coordinate ranges to avoid false positives
          if (lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
            debugPrint('✅ [MapCoordinate] Found coordinates in JS array: $lat, $lng');
            return MapCoordinate(
              latitude: lat,
              longitude: lng,
              originalUrl: originalUrl,
              provider: MapProvider.googleMaps,
            );
          }
        }
      }

      // Pattern 5: NEW - Look for google.maps.LatLng(lat, lng) patterns
      final latLngPattern = RegExp(r'google\.maps\.LatLng\s*\(\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)\s*\)');
      final latLngMatch = latLngPattern.firstMatch(html);

      if (latLngMatch != null) {
        final lat = double.tryParse(latLngMatch.group(1) ?? '');
        final lng = double.tryParse(latLngMatch.group(2) ?? '');

        if (lat != null && lng != null) {
          debugPrint('✅ [MapCoordinate] Found coordinates in LatLng: $lat, $lng');
          return MapCoordinate(
            latitude: lat,
            longitude: lng,
            originalUrl: originalUrl,
            provider: MapProvider.googleMaps,
          );
        }
      }

      // Pattern 6: NEW - Look for "center": [lat, lng] in JSON
      final centerPattern = RegExp(r'"center"\s*:\s*\[\s*(-?\d+\.?\d*)\s*,\s*(-?\d+\.?\d*)\s*\]');
      final centerMatch = centerPattern.firstMatch(html);

      if (centerMatch != null) {
        final lat = double.tryParse(centerMatch.group(1) ?? '');
        final lng = double.tryParse(centerMatch.group(2) ?? '');

        if (lat != null && lng != null) {
          debugPrint('✅ [MapCoordinate] Found coordinates in center JSON: $lat, $lng');
          return MapCoordinate(
            latitude: lat,
            longitude: lng,
            originalUrl: originalUrl,
            provider: MapProvider.googleMaps,
          );
        }
      }

      debugPrint('⚠️ [MapCoordinate] No coordinates found in HTML');
      return null;
    } catch (e) {
      debugPrint('⚠️ [MapCoordinate] HTML parsing error: $e');
      return null;
    }
  }

  /// Extract coordinates from Yandex Maps HTML page (placeholder)
  static MapCoordinate? _extractFromYandexMapsHtml(
    String html,
    String originalUrl,
  ) {
    // TODO: Implement Yandex-specific HTML extraction
    debugPrint('⚠️ [MapCoordinate] Yandex HTML extraction not yet implemented');
    return null;
  }

  /// Checks if URL is a map URL
  static bool isMapUrl(String url) {
    return _detectProvider(url) != MapProvider.unknown;
  }

  /// Forward geocoding: place name → coordinates
  /// Uses Nominatim API (free, no API key)
  static Future<MapCoordinate?> forwardGeocode(String placeName) async {
    try {
      debugPrint('🔍 [MapCoordinate] Forward geocoding: $placeName');

      // Check cache first
      final cached = await _getCachedCoordinatesForPlace(placeName);
      if (cached != null) {
        final parts = cached.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0]);
          final lng = double.tryParse(parts[1]);
          if (lat != null && lng != null) {
            debugPrint('✅ [MapCoordinate] Found in cache: $lat, $lng');
            return MapCoordinate(
              latitude: lat,
              longitude: lng,
              originalUrl: placeName,
              provider: MapProvider.unknown,
              placeName: placeName,
            );
          }
        }
      }

      // Build Nominatim search API URL
      final url = 'https://nominatim.openstreetmap.org/search?'
          'q=${Uri.encodeComponent(placeName)}&'
          'format=json&'
          'limit=1&'
          'addressdetails=0';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'SoMine App (iOS)',
          'Accept': 'application/json',
        },
      ).timeout(_geocodeTimeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          final lat = double.tryParse(data[0]['lat'] as String? ?? '');
          final lng = double.tryParse(data[0]['lon'] as String? ?? '');

          if (lat != null && lng != null) {
            debugPrint('✅ [MapCoordinate] Forward geocoded: $lat, $lng');

            // Cache result
            await _cacheCoordinatesForPlace(placeName, lat, lng);

            return MapCoordinate(
              latitude: lat,
              longitude: lng,
              originalUrl: placeName,
              provider: MapProvider.unknown,
              placeName: placeName,
            );
          }
        }
      } else if (response.statusCode == 429) {
        debugPrint('⚠️ [MapCoordinate] Nominatim rate limit exceeded');
      }
    } catch (e) {
      debugPrint('⚠️ [MapCoordinate] Forward geocoding failed: $e');
    }

    return null;
  }

  /// Gets cached coordinates for a place name
  static Future<String?> _getCachedCoordinatesForPlace(String placeName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'geocode_${placeName.toLowerCase().replaceAll(' ', '_')}';

      final cached = prefs.getString(key);
      if (cached != null) {
        final timestampKey = '${key}_ts';
        final timestamp = prefs.getInt(timestampKey);
        if (timestamp != null) {
          final age = DateTime.now().millisecondsSinceEpoch - timestamp;
          if (age < _cacheExpiration.inMilliseconds) {
            return cached;
          } else {
            // Expired, remove
            await prefs.remove(key);
            await prefs.remove(timestampKey);
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MapCoordinate] Geocode cache read error: $e');
    }
    return null;
  }

  /// Caches coordinates for a place name
  static Future<void> _cacheCoordinatesForPlace(
    String placeName,
    double lat,
    double lng,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'geocode_${placeName.toLowerCase().replaceAll(' ', '_')}';
      final timestampKey = '${key}_ts';

      await prefs.setString(key, '$lat,$lng');
      await prefs.setInt(
        timestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      // Cleanup old entries
      await _cleanupCache(prefs);
    } catch (e) {
      debugPrint('⚠️ [MapCoordinate] Geocode cache write error: $e');
    }
  }
}
