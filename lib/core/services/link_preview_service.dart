import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:somine_app/core/models/link_preview_model.dart';

class LinkPreviewService {
  Future<LinkPreviewModel> fetchPreview(String url) async {
    try {
      // 1. Validate URL
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }

      // 2. Fetch HTML
      // Instagram and some others require User-Agent to look like a browser
      final response = await http.get(Uri.parse(url), headers: {
        'User-Agent':
            'Mozilla/5.0 (iPhone; CPU iPhone OS 15_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Mobile/15E148 Safari/604.1',
      });

      if (response.statusCode != 200) {
        throw Exception('Failed to load page: ${response.statusCode}');
      }

      // 3. Parse Metadata
      final document = parse(response.body);
      
      String? title = _getMetaContent(document, [
        'og:title', 'twitter:title', 'title'
      ]);
      
      String? description = _getMetaContent(document, [
        'og:description', 'twitter:description', 'description'
      ]);
      
      String? imageUrl = _getMetaContent(document, [
        'og:image', 'twitter:image', 'image'
      ]);
      
      String? siteName = _getMetaContent(document, [
        'og:site_name', 'application-name'
      ]);

      // Fallbacks if OG tags missed
      title ??= document.querySelector('title')?.text.trim();
      
      return LinkPreviewModel(
        url: url,
        title: title,
        description: description,
        imageUrl: imageUrl,
        siteName: siteName ?? _extractDomain(url),
      );

    } catch (e) {
      // Return basic data on failure
      return LinkPreviewModel(
        url: url,
        title: _extractDomain(url), 
      );
    }
  }

  String? _getMetaContent(document, List<String> properties) {
    for (final prop in properties) {
      final meta = document.querySelector('meta[property="$prop"]') ?? 
                   document.querySelector('meta[name="$prop"]');
      
      if (meta != null) {
        final content = meta.attributes['content'];
        if (content != null && content.isNotEmpty) {
          return content;
        }
      }
    }
    return null;
  }
  
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return 'Link';
    }
  }
}
