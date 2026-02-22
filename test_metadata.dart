import 'package:html/parser.dart' as parser;
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

/// Fallback for TikTok using oEmbed API
Future<Map<String, String?>> _fetchTikTokOembed(String url) async {
  try {
    final response = await http.get(Uri.parse('https://www.tiktok.com/oembed?url=$url'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return {
        'title': json['title'],
        'image': json['thumbnail_url'],
      };
    }
  } catch (e) {
    print('TikTok Oembed Error: $e');
  }
  return {'title': null, 'image': null};
}

/// Fallback for Reddit JSON API
Future<Map<String, String?>> _fetchRedditJson(String url) async {
  try {
     final response = await http.get(
        Uri.parse('$url.json'),
        headers: {'User-Agent': 'Mozilla/5.0'}
     );
     if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json is List && json.isNotEmpty && json[0]['data']['children'].isNotEmpty) {
           final post = json[0]['data']['children'][0]['data'];
           String? image;
           if (post['preview'] != null && post['preview']['images'] != null && post['preview']['images'].isNotEmpty) {
             image = post['preview']['images'][0]['source']['url']?.replaceAll('&amp;', '&');
           }
           return {
             'title': post['title'],
             'image': image ?? post['thumbnail'],
           };
        }
     }
  } catch (e) {
     print('Reddit JSON Error: $e');
  }
  return {'title': null, 'image': null};
}


Future<void> main() async {
  final links = [
    'https://www.linkedin.com/posts/at%C4%B1l-samanc%C4%B1o%C4%9Flu-96028871_github-atilsamancioglushakespeareplusgpt-activity-7430999033923387393-8xKO?utm_medium=ios_app&rcm=ACoAADvM7B0B4Hnmue4gxtKTx-e_B72LA5XBAJg&utm_source=social_share_send&utm_campaign=share_via',
    'https://vt.tiktok.com/ZSm9BCN1e/',
    'https://open.spotify.com/track/1aFuXmfz6bYOvUDOLZiqys?si=7-N7WeyzQounlCQk08HfNg',
    'https://pin.it/3vuB4o6Ve',
    'https://www.reddit.com/r/SacmaBirSub/s/TAX9E9wEs1',
    'https://code.likeagirl.io/why-reading-more-books-wasnt-making-me-smarter-5fad5a2cad03',
    'https://dribbble.com/shots/27112584-Supra-Future-of-Web3-Brand-Identity',
    'https://www.zara.com/tr/tr/kapri-pantolon-p03152427.html?v1=507744704&v2=2546081&utm_campaign=productShare&utm_medium=mobile_sharing_iOS&utm_source=red_social_movil',
    'https://www.zara.com/tr/tr/volanli-bel-bermuda-p05427413.html?v1=524544485&v2=2546081',
    'https://www2.hm.com/tr_tr/productpage.1310165007.html'
  ];

  for (String url in links) {
    print('\n=======================================');
    print('Testing: $url');
    try {
      
      String? title, image;
      
      // Special extractors
      if (url.contains('tiktok.com')) {
         final data = await _fetchTikTokOembed(url);
         if (data['title'] != null) {
           print('RESULT -> Title: ${data['title']} | Image: ${data['image']}');
           continue; 
         }
      }
      
      // Fetch Content
      // Use a strict desktop Safari User agent to bypass some mobile constraints
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'en-US,en;q=0.5',
        },
      ).timeout(Duration(seconds: 15));

      print('Status: ${response.statusCode}');
      
      // If 403 or 401 on Reddit -> try JSON
      if (url.contains('reddit.com') && response.statusCode != 200) {
        final data = await _fetchRedditJson(url);
        if (data['title'] != null) {
           print('RESULT -> Title: ${data['title']} | Image: ${data['image']}');
           continue;
        }
      }
      
      if (response.statusCode != 200) {
         // Fallback logic for Zara, HM, Dribbble using Google Site proxy or open graph API proxies
         // For a native app, we can use https://api.dub.co/metatags?url=...
         print('Trying dub.co proxy for $url');
         final proxyRes = await http.get(Uri.parse('https://api.dub.co/metatags?url=$url'));
         if (proxyRes.statusCode == 200) {
            final json = jsonDecode(proxyRes.body);
            print('RESULT -> Title: ${json['title']} | Image: ${json['image']}');
            continue;
         }
      }
      
      final document = parser.parse(response.body);
      final metaTags = document.getElementsByTagName('meta');

      for (var tag in metaTags) {
        final property = tag.attributes['property'];
        final name = tag.attributes['name'];
        final content = tag.attributes['content'];

        if (content == null || content.isEmpty) continue;

        if (property == 'og:title' || name == 'title' || name == 'twitter:title') {
           title ??= content; 
        }
        if (property == 'og:image' || name == 'image' || name == 'twitter:image' || name == 'twitter:image:src') {
           image ??= content;
        }
      }
      
      if (image == null) {
        // Find JSON-LD First
        final scripts = document.getElementsByTagName('script');
        for (var script in scripts) {
          if (script.attributes['type'] == 'application/ld+json') {
             try {
                final json = jsonDecode(script.text);
                if (json is Map && json['image'] != null) {
                   if (json['image'] is String) image = json['image'];
                   if (json['image'] is List && json['image'].isNotEmpty) image = json['image'][0];
                }
             } catch (e) {
                // Ignore parse errors
             }
          }
        }
      }

      print('RESULT -> Title: $title | Image: $image');

    } catch (e) {
      print('Error parsing $url: $e');
    }
  }
}
