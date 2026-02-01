import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:somine_app/core/models/item_model.dart';

/// Service to fetch Open Graph metadata from URLs
class MetadataService {
  /// Fetch OG metadata from a URL
  static Future<OGMetadata?> fetchMetadata(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent':
              'Mozilla/5.0 (iPhone; CPU iPhone OS 16_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.6 Mobile/15E148 Safari/604.1',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
        },
      ).timeout(
        const Duration(seconds: 10),
      );
      
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final metaTags = document.getElementsByTagName('meta');

        String? title, description, image, siteName;

        for (var tag in metaTags) {
          final property = tag.attributes['property'];
          final name = tag.attributes['name'];
          final content = tag.attributes['content'];

          if (content == null || content.isEmpty) continue;

          // Title
          if (property == 'og:title' || name == 'title' || name == 'twitter:title') {
             title ??= content; // Keep first found
          }
          
          // Description
          if (property == 'og:description' || name == 'description' || name == 'twitter:description') {
            description ??= content;
          }
          
          // Image
          if (property == 'og:image' || name == 'image' || name == 'twitter:image' || name == 'twitter:image:src') {
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
               final imageMatch = RegExp(r'"image"\s*:\s*(?:\[\s*)?"([^"]+)"').firstMatch(jsonContent);
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
             String? src = img.attributes['src'] ?? img.attributes['data-src'] ?? img.attributes['data-original'];
             
             if (src == null || src.isEmpty) continue;
             
             // Filter out likely icons/trackers/logos in first pass
             if (src.endsWith('.svg') || src.contains('logo') || src.contains('icon') || src.length < 50) {
               continue;
             }
             
             image = src;
             break;
           }
           
           // Pass 2: Loose (Allow Request Logic: "logo.png arayalım" - If nothing found, take whatever we have)
           if (image == null) {
              for (var img in imgs) {
                 String? src = img.attributes['src'] ?? img.attributes['data-src'] ?? img.attributes['data-original'];
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

        // NO MORE FALLBACK - if no image found, return null and let UI show placeholder
        // This prevents small/pixelated favicons from being displayed
        
        // Fallback to <title> tag if og:title not found
        if (title == null) {
          final titleTag = document.getElementsByTagName('title').firstOrNull;
          title = titleTag?.text;
        }
        
        // X.com (Twitter) Fallback: Extract username from URL if title still null
        // X.com uses CSR so meta tags are often missing
        if (title == null && (url.contains('x.com') || url.contains('twitter.com'))) {
          final twitterRegex = RegExp(r'(?:x\.com|twitter\.com)/([A-Za-z0-9_]+)');
          final match = twitterRegex.firstMatch(url);
          if (match != null && match.group(1) != null) {
            final username = match.group(1)!;
            // Filter out system paths
            if (!['i', 'intent', 'share', 'search', 'explore', 'home', 'notifications', 'messages'].contains(username.toLowerCase())) {
              title = '@$username adlı kullanıcının gönderisi';
            }
          }
        }

        // Filter out generic titles for Maps URLs
        // These short links redirect to pages with generic titles like "Google" or "Google Maps"
        if (_isMapUrl(url) && title != null) {
          final genericTitles = ['google', 'google maps', 'google haritalar', 'apple maps', 'yandex', 'yandex maps', 'yandex haritalar', 'maps', 'haritalar'];
          if (genericTitles.contains(title.toLowerCase().trim())) {
            debugPrint('⚠️ [MetadataService] Filtering generic Maps title: $title');
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
    }

    // If request failed completely, return null
    // UI will show placeholder with icon based on URL
    return null;
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
}
