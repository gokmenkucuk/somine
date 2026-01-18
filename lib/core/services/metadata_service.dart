import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:somine_app/core/models/item_model.dart';

/// Service to fetch Open Graph metadata from URLs
class MetadataService {
  /// Fetch OG metadata from a URL
  static Future<OGMetadata?> fetchMetadata(String url) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(
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

          if (content == null) continue;

          if (property == 'og:title' || name == 'title') title = content;
          if (property == 'og:description' || name == 'description') {
            description = content;
          }
          if (property == 'og:image' || name == 'image') image = content;
          if (property == 'og:site_name') siteName = content;
        }
        
        // Fallback to <title> tag if og:title not found
        if (title == null) {
          final titleTag = document.getElementsByTagName('title').firstOrNull;
          title = titleTag?.text;
        }

        return OGMetadata(
          title: title,
          description: description,
          imageUrl: image,
          siteName: siteName,
        );
      }
    } catch (e) {
      debugPrint('🔴 [MetadataService] Error fetching metadata: $e');
    }
    return null;
  }
}
