import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:somine_app/core/models/item_model.dart';
import 'dart:io';
import 'dart:convert';

/// Service to fetch Open Graph metadata from URLs
class MetadataService {
  /// Fetch OG metadata from a URL
  static Future<OGMetadata?> fetchMetadata(String url) async {
    try {
      // FAST PATH: For Google Maps short links, try to extract title from URL FIRST
      // This avoids the slow redirect + HTML fetch process
      if (_isGoogleMapsShortLink(url)) {
        final urlTitle = _extractTitleFromGoogleMapsUrl(url);
        if (urlTitle != null && !_isGenericMapsTitle(urlTitle)) {
          debugPrint('⚡ [MetadataService] Fast URL extraction: $urlTitle');
          // Return early with just the title - no need for full metadata fetch
          return OGMetadata(
            title: urlTitle,
            description: null,
            imageUrl: null,
            siteName: 'Google Maps',
          );
        }
      }

      // First, resolve redirects using dart:io HttpClient
      String finalUrl = url;
      if (_isMapUrl(url) || url.contains('vt.tiktok.com')) {
        finalUrl = await _resolveRedirects(url) ?? url;
        debugPrint('🔗 [MetadataService] Original: $url -> Final: $finalUrl');
      }

      // Special Platform Extractors
      if (finalUrl.contains('tiktok.com')) {
        final data = await _fetchTikTokOembed(finalUrl);
        if (data['title'] != null) {
          debugPrint('🎵 [MetadataService] TikTok Oembed Success');
          return OGMetadata(
            title: data['title'],
            description: null,
            imageUrl: data['image'],
            siteName: 'TikTok',
          );
        }
      }

      // Then fetch the page content
      // Google Maps için daha kısa timeout (5 saniye, normal 10)
      final timeout =
          finalUrl.toLowerCase().contains('google')
              ? const Duration(seconds: 5)
              : const Duration(seconds: 10);

      // Set a generic Desktop Safari User-Agent to bypass mobile/bot blocks (Spotify, Dribbble, etc.)
      final response = await http
          .get(
            Uri.parse(finalUrl),
            headers: {
              'User-Agent':
                  'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',
              'Accept':
                  'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
              'Accept-Language': 'tr-TR,tr;q=0.9,en-US;q=0.8,en;q=0.7',
            },
          )
          .timeout(timeout);

      // Reddit Fallback: 403/401 is common, use their open JSON API
      if (response.statusCode != 200 &&
          (finalUrl.contains('reddit.com') || finalUrl.contains('redd.it'))) {
        final data = await _fetchRedditJson(finalUrl);
        if (data['title'] != null) {
          debugPrint('👽 [MetadataService] Reddit JSON API Success');
          return OGMetadata(
            title: data['title'],
            description: null,
            imageUrl: data['image'],
            siteName: 'Reddit',
          );
        }
      }

      if (response.statusCode != 200) {
        final fallbackMetadata =
            _buildBlockedSiteFallback(finalUrl) ??
            _buildBlockedSiteFallback(url);
        if (fallbackMetadata != null) {
          debugPrint(
            '🧩 [MetadataService] Blocked site fallback for ${response.statusCode}: ${fallbackMetadata.title}',
          );
          return fallbackMetadata;
        }
      }

      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final metaTags = document.getElementsByTagName('meta');

        String? title, description, image, siteName;

        // For Maps URLs, try to extract place name from final URL first
        if (_isMapUrl(url) || _isMapUrl(finalUrl)) {
          title = _extractPlaceNameFromMapUrl(finalUrl);
          if (title != null) {
            debugPrint('📍 [MetadataService] Extracted place name: $title');
          }
        }

        for (var tag in metaTags) {
          final property = tag.attributes['property'];
          final name = tag.attributes['name'];
          final content = tag.attributes['content'];

          if (content == null || content.isEmpty) continue;

          // Title
          if (property == 'og:title' ||
              name == 'title' ||
              name == 'twitter:title') {
            title ??= content; // Keep first found
          }

          // Description
          if (property == 'og:description' ||
              name == 'description' ||
              name == 'twitter:description') {
            description ??= content;
          }

          // Image
          if (property == 'og:image' ||
              name == 'image' ||
              name == 'twitter:image' ||
              name == 'twitter:image:src') {
            image ??= content;
          }

          // Site Name
          if (property == 'og:site_name') siteName = content;
        }

        // Fallback: Check <link rel="image_src"> (Common in some older CMS)
        if (image == null) {
          final linkTags = document.getElementsByTagName('link');
          for (var tag in linkTags) {
            if (tag.attributes['rel'] == 'image_src') {
              image = tag.attributes['href'];
              break;
            }
          }
        }

        // Fallback: JSON-LD (Common in E-commerce like Shopify)
        if (image == null) {
          final scripts = document.getElementsByTagName('script');
          for (var script in scripts) {
            if (script.attributes['type'] == 'application/ld+json') {
              final jsonContent = script.text;
              // Simple regex extract to avoid importing heavy JSON parser for just one field
              // Looks for "image": "url" or "image": ["url"]
              final imageMatch = RegExp(
                r'"image"\s*:\s*(?:\[\s*)?"([^"]+)"',
              ).firstMatch(jsonContent);
              if (imageMatch != null) {
                image = imageMatch.group(1);
                // Cleanup standard JSON-LD image arrays if needed, but regex usually catches first string
                break;
              }
            }
          }
        }

        // Fallback: Check first significant <img> tag
        if (image == null) {
          final imgs = document.getElementsByTagName('img');

          // Pass 1: Strict (No logos, High quality)
          for (var img in imgs) {
            String? src =
                img.attributes['src'] ??
                img.attributes['data-src'] ??
                img.attributes['data-original'];

            if (src == null || src.isEmpty) continue;

            // Filter out likely icons/trackers/logos in first pass
            if (src.endsWith('.svg') ||
                src.contains('logo') ||
                src.contains('icon') ||
                src.length < 50) {
              continue;
            }

            image = src;
            break;
          }

          // Pass 2: Loose (Allow Request Logic: "logo.png arayalım" - If nothing found, take whatever we have)
          if (image == null) {
            for (var img in imgs) {
              String? src =
                  img.attributes['src'] ??
                  img.attributes['data-src'] ??
                  img.attributes['data-original'];
              if (src == null || src.isEmpty) continue;

              // Minimal filter (just avoid 1x1 pixels or base64 tiny stuff)
              if (src.length < 20 && !src.startsWith('http')) continue;

              image = src;
              break;
            }
          }
        }

        // Final Fallback: Apple Touch Icon (Usually high res logo)
        if (image == null) {
          final links = document.getElementsByTagName('link');
          for (var link in links) {
            final rel = link.attributes['rel']?.toLowerCase() ?? '';
            if (rel.contains('icon') || rel == 'apple-touch-icon') {
              image = link.attributes['href'];
              // Prefer apple-touch-icon if multiple found
              if (rel == 'apple-touch-icon') break;
            }
          }
        }

        // Resolve relative URLs
        if (image != null && !image.startsWith('http')) {
          final uri = Uri.parse(url);
          if (image.startsWith('//')) {
            image = '${uri.scheme}:$image';
          } else if (image.startsWith('/')) {
            image = '${uri.scheme}://${uri.host}$image';
          } else {
            image = '${uri.scheme}://${uri.host}/$image';
          }
        }

        // ULTIMATE FALLBACK: Google Favicon Service
        // Guaranteed to return something for valid domains
        if (image == null) {
          final uri = Uri.parse(url);
          image =
              'https://www.google.com/s2/favicons?domain=${uri.host}&sz=128';
        }

        // Fallback to <title> tag if og:title not found
        if (title == null) {
          final titleTag = document.getElementsByTagName('title').firstOrNull;
          title = titleTag?.text;
        }

        // X.com (Twitter) often exposes generic shell metadata or SVG emoji assets.
        // Keep the record saveable by using a stable title and ignoring unsupported SVG images.
        if (_isTwitterUrl(url)) {
          if (title == null || _isGenericTwitterTitle(title)) {
            title = _twitterTitleFromUrl(url) ?? title;
          }

          if (_isUnsupportedTwitterImage(image)) {
            image = null;
          }
        }

        // Filter out generic titles for Maps URLs
        // These short links redirect to pages with generic titles like "Google" or "Google Maps"
        if (_isMapUrl(url) && title != null) {
          final genericTitles = [
            'google',
            'google maps',
            'google haritalar',
            'apple maps',
            'yandex',
            'yandex maps',
            'yandex haritalar',
            'maps',
            'haritalar',
          ];
          if (genericTitles.contains(title.toLowerCase().trim())) {
            debugPrint(
              '⚠️ [MetadataService] Filtering generic Maps title: $title',
            );
            title = null; // Let UI use placeholder or user input
          }
        }

        return OGMetadata(
          title: title,
          description: description,
          imageUrl: image, // Can be null - UI will show placeholder
          siteName: siteName,
        );
      }
    } catch (e) {
      debugPrint('🔴 [MetadataService] Error fetching metadata: $e');
      final fallbackMetadata = _buildBlockedSiteFallback(url);
      if (fallbackMetadata != null) {
        debugPrint(
          '🧩 [MetadataService] Blocked site fallback after error: ${fallbackMetadata.title}',
        );
        return fallbackMetadata;
      }
    }

    // If request failed completely, return null
    // UI will show placeholder with icon based on URL
    return null;
  }

  /// Fallback for TikTok using oEmbed API
  static Future<Map<String, String?>> _fetchTikTokOembed(String url) async {
    try {
      final response = await http
          .get(Uri.parse('https://www.tiktok.com/oembed?url=$url'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return {'title': json['title'], 'image': json['thumbnail_url']};
      }
    } catch (e) {
      debugPrint('⚠️ [MetadataService] TikTok Oembed Error: $e');
    }
    return {'title': null, 'image': null};
  }

  /// Fallback for Reddit JSON API
  static Future<Map<String, String?>> _fetchRedditJson(String url) async {
    try {
      // Remove trailing slash if exists, then append .json
      final cleanUrl =
          url.endsWith('/') ? url.substring(0, url.length - 1) : url;
      final response = await http
          .get(
            Uri.parse('$cleanUrl.json'),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is List &&
            json.isNotEmpty &&
            json[0]['data']['children'].isNotEmpty) {
          final post = json[0]['data']['children'][0]['data'];
          String? image;
          if (post['preview'] != null &&
              post['preview']['images'] != null &&
              post['preview']['images'].isNotEmpty) {
            image = post['preview']['images'][0]['source']['url']?.replaceAll(
              '&amp;',
              '&',
            );
          }
          return {'title': post['title'], 'image': image ?? post['thumbnail']};
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MetadataService] Reddit JSON Error: $e');
    }
    return {'title': null, 'image': null};
  }

  static bool _isTwitterUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    return host == 'x.com' ||
        host.endsWith('.x.com') ||
        host == 'twitter.com' ||
        host.endsWith('.twitter.com');
  }

  static bool _isGenericTwitterTitle(String? title) {
    final normalized = title?.toLowerCase().trim();
    return normalized == null ||
        normalized.isEmpty ||
        normalized == 'x' ||
        normalized == 'twitter';
  }

  static String? _twitterTitleFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final username =
        uri.pathSegments
            .where((segment) => segment.trim().isNotEmpty)
            .cast<String?>()
            .firstOrNull;

    if (username == null) return null;

    const systemPaths = {
      'i',
      'intent',
      'share',
      'search',
      'explore',
      'home',
      'notifications',
      'messages',
    };

    if (systemPaths.contains(username.toLowerCase())) {
      return null;
    }

    return '@$username adlı kullanıcının gönderisi';
  }

  static bool _isUnsupportedTwitterImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) return false;

    final lower = imageUrl.toLowerCase();
    return lower.endsWith('.svg') ||
        lower.contains('/emoji/') ||
        lower.contains('twemoji') ||
        lower.contains('abs-0.twimg.com/emoji');
  }

  static OGMetadata? _buildBlockedSiteFallback(String url) {
    return _buildAdidasFallback(url);
  }

  static OGMetadata? _buildAdidasFallback(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !_isAdidasHost(uri.host)) return null;

    final productIndex = uri.pathSegments.indexWhere(
      (segment) => _adidasProductCodeFromSegment(segment) != null,
    );
    if (productIndex <= 0) return null;

    final slug = Uri.decodeComponent(uri.pathSegments[productIndex - 1]);
    final title = _titleFromSlug(slug);
    if (title == null || title.isEmpty) return null;

    return OGMetadata(
      title: title,
      description: null,
      imageUrl: null,
      siteName:
          uri.host.toLowerCase().endsWith('adidas.com.tr')
              ? 'adidas Türkiye'
              : 'adidas',
    );
  }

  static bool _isAdidasHost(String host) {
    final lowerHost = host.toLowerCase();
    return lowerHost == 'adidas.com.tr' ||
        lowerHost.endsWith('.adidas.com.tr') ||
        lowerHost == 'adidas.com' ||
        lowerHost.endsWith('.adidas.com');
  }

  static String? _adidasProductCodeFromSegment(String segment) {
    final match = RegExp(
      r'^([a-z0-9]{6})\.html$',
      caseSensitive: false,
    ).firstMatch(segment);
    return match?.group(1)?.toUpperCase();
  }

  static String? _titleFromSlug(String slug) {
    final tokens =
        slug
            .replaceAll(RegExp(r'[-_]+'), ' ')
            .split(RegExp(r'\s+'))
            .where((token) => token.trim().isNotEmpty)
            .map(_titleCaseSlugToken)
            .toList();

    if (tokens.isEmpty) return null;
    return tokens.join(' ');
  }

  static String _titleCaseSlugToken(String token) {
    const trReplacements = {
      'ayakkabi': 'Ayakkabı',
      'cocuk': 'Çocuk',
      'kadin': 'Kadın',
      'sirt': 'Sırt',
      'canta': 'Çanta',
      'cantasi': 'Çantası',
      'tisort': 'Tişört',
      'sort': 'Şort',
      'sapka': 'Şapka',
      'esofman': 'Eşofman',
      'kosu': 'Koşu',
    };

    final lower = token.toLowerCase();
    final replacement = trReplacements[lower];
    if (replacement != null) return replacement;

    if (RegExp(r'^\d+(?:\.\d+)?$').hasMatch(token)) return token;
    if (token.isEmpty) return token;

    return token[0].toUpperCase() + token.substring(1).toLowerCase();
  }

  /// Check if URL is a maps service
  static bool _isMapUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('maps.app.goo.gl') ||
        lower.contains('goo.gl/maps') ||
        lower.contains('google.com/maps') ||
        lower.contains('maps.google') ||
        lower.contains('yandex.com/maps') ||
        lower.contains('yandex.ru/maps') ||
        lower.contains('maps.apple.com');
  }

  /// Check if URL is a Google Maps short link (maps.app.goo.gl or goo.gl/maps)
  static bool _isGoogleMapsShortLink(String url) {
    final lower = url.toLowerCase();
    return lower.contains('maps.app.goo.gl') || lower.contains('goo.gl/maps');
  }

  /// Extract title from Google Maps short link URL directly
  /// This avoids slow redirect + HTML fetch for URLs like:
  /// https://maps.app.goo.gl/?q=Place+Name
  /// https://maps.app.goo.gl/ABC123?d=Place+Name
  static String? _extractTitleFromGoogleMapsUrl(String url) {
    try {
      final decoded = Uri.decodeComponent(url);

      // Try ?q= parameter (place name)
      final qMatch = RegExp(r'[?&]q=([^&]+)').firstMatch(decoded);
      if (qMatch != null) {
        String name = qMatch.group(1)!;
        name = name.replaceAll('+', ' ').replaceAll('_', ' ').trim();
        if (name.isNotEmpty) {
          return name;
        }
      }

      // Try ?d= parameter (destination)
      final dMatch = RegExp(r'[?&]d=([^&]+)').firstMatch(decoded);
      if (dMatch != null) {
        String name = dMatch.group(1)!;
        name = name.replaceAll('+', ' ').replaceAll('_', ' ').trim();
        if (name.isNotEmpty) {
          return name;
        }
      }

      // Try /place/Place+Name/ pattern (works even with short links that have path)
      final placeMatch = RegExp(r'/place/([^/@?]+)').firstMatch(decoded);
      if (placeMatch != null) {
        String name = placeMatch.group(1)!;
        name = name.replaceAll('+', ' ').replaceAll('_', ' ').trim();
        if (name.isNotEmpty && name.toLowerCase() != 'place') {
          return name;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MetadataService] Error extracting title from URL: $e');
    }
    return null;
  }

  /// Check if title is a generic Maps title that should be filtered out
  static bool _isGenericMapsTitle(String title) {
    final genericTitles = [
      'google',
      'google maps',
      'google haritalar',
      'apple maps',
      'yandex',
      'yandex maps',
      'yandex haritalar',
      'maps',
      'haritalar',
      'map',
      'konum',
      'location',
      'yer',
      'place',
    ];
    return genericTitles.contains(title.toLowerCase().trim());
  }

  /// Extract place name from Maps URL
  /// Google Maps: /place/Place+Name/ or /place/Place%20Name/
  /// Yandex: orgpage/Place+Name/ or ?text=Place
  /// Apple: ?q=Place or place?...
  static String? _extractPlaceNameFromMapUrl(String url) {
    try {
      final decoded = Uri.decodeComponent(url);

      // Google Maps: /place/Place+Name/@coordinates
      final googlePlaceMatch = RegExp(r'/place/([^/@]+)').firstMatch(decoded);
      if (googlePlaceMatch != null) {
        String name = googlePlaceMatch.group(1)!;
        // Replace + and _ with spaces
        name = name.replaceAll('+', ' ').replaceAll('_', ' ').trim();
        if (name.isNotEmpty && name.toLowerCase() != 'place') {
          return name;
        }
      }

      // Yandex Maps: orgpage/Place+Name/ or /geo/Place+Name/
      final yandexMatch = RegExp(
        r'(?:orgpage|geo)/([^/]+)',
      ).firstMatch(decoded);
      if (yandexMatch != null) {
        String name = yandexMatch.group(1)!;
        name = name.replaceAll('+', ' ').replaceAll('_', ' ').trim();
        if (name.isNotEmpty) {
          return name;
        }
      }

      // Yandex text param: ?text=Place
      final yandexTextMatch = RegExp(r'[?&]text=([^&]+)').firstMatch(decoded);
      if (yandexTextMatch != null) {
        String name = yandexTextMatch.group(1)!;
        name = name.replaceAll('+', ' ').trim();
        if (name.isNotEmpty) {
          return name;
        }
      }

      // Apple Maps: ?q=Place or ?address=Place
      final appleMatch = RegExp(
        r'[?&](?:q|address)=([^&]+)',
      ).firstMatch(decoded);
      if (appleMatch != null) {
        String name = appleMatch.group(1)!;
        name = name.replaceAll('+', ' ').trim();
        if (name.isNotEmpty) {
          return name;
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MetadataService] Error extracting place name: $e');
    }
    return null;
  }

  /// Resolve redirects for short URLs (like maps.app.goo.gl)
  /// Uses dart:io HttpClient to follow redirects and get final URL
  static Future<String?> _resolveRedirects(String url) async {
    try {
      final client = HttpClient();
      client.userAgent =
          'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15';

      final request = await client.getUrl(Uri.parse(url));
      request.followRedirects = true;
      request.maxRedirects = 10;

      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      final finalUri =
          response.redirects.isNotEmpty
              ? response.redirects.last.location
              : request.uri;

      client.close();

      return finalUri.toString();
    } catch (e) {
      debugPrint('⚠️ [MetadataService] Error resolving redirects: $e');
      return null;
    }
  }
}
