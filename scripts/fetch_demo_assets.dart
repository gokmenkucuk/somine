import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

// User's Provided List
final rawItems = [
  {'cat': 'muzik', 'url': 'https://www.youtube.com/watch?v=LniRqZ0P5cQ'},
  {'cat': 'muzik', 'url': 'https://www.youtube.com/watch?v=eKQuwAmIVKA'},
  {'cat': 'muzik', 'url': 'https://www.youtube.com/watch?v=a1kAW7UaRXM'},
  {'cat': 'muzik', 'url': 'https://www.youtube.com/watch?v=hhw90xpY7MI&t=5s'},
  {'cat': 'muzik', 'url': 'https://www.youtube.com/watch?v=L3cFRU-piHU'},
  {'cat': 'muzik', 'url': 'https://www.instagram.com/p/CqDArZ3jrXm/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA=='},

  {'cat': 'seyahat', 'url': 'https://www.youtube.com/watch?v=XBOv2tFE5gw'},
  {'cat': 'seyahat', 'url': 'https://www.instagram.com/reel/DSNs_bUDjwx/?utm_source=ig_web_copy_link&igsh=NTc4MTIwNjQ2YQ=='},
  {'cat': 'seyahat', 'url': 'https://www.youtube.com/watch?v=UZphSM4u29k&t=3s'},
  {'cat': 'seyahat', 'url': 'https://www.youtube.com/watch?v=B0YhBfHk7lg'},
  {'cat': 'seyahat', 'url': 'https://www.instagram.com/reel/DO6oTuxCmqc/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA=='},
  {'cat': 'seyahat', 'url': 'https://www.instagram.com/reel/DPlXtvrDCzw/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA=='},
  {'cat': 'seyahat', 'url': 'https://www.youtube.com/shorts/UzCTazYfS0c'},

  {'cat': 'teknoloji', 'url': 'https://www.instagram.com/reel/DByz-XOIww9/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA=='},

  {'cat': 'komik', 'url': 'https://www.instagram.com/reel/DFuU84vNr4Y/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA=='},
  {'cat': 'komik', 'url': 'https://www.instagram.com/reel/DGNasReN8oO/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA=='},
  {'cat': 'komik', 'url': 'https://www.instagram.com/reel/DFNbTG_MWVe/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA=='},
  {'cat': 'komik', 'url': 'https://www.instagram.com/reels/DNtAjoBUB-g/'},
  {'cat': 'komik', 'url': 'https://www.instagram.com/p/DRkNjDaDl5o/'},

  {'cat': 'gelisim', 'url': 'https://www.instagram.com/reel/DFw2E8VND0J/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA=='},

  {'cat': 'restaurant', 'url': 'https://www.instagram.com/reel/DLdDWS6CMj4/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA=='},
  {'cat': 'restaurant', 'url': 'https://www.instagram.com/reel/DFqJQCBIlM5/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA=='},
  {'cat': 'restaurant', 'url': 'https://www.instagram.com/reel/DOmAnXSABOu/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA=='},

  {'cat': 'tasarim', 'url': 'https://tr.pinterest.com/pin/703756188753159/'},
  {'cat': 'tasarim', 'url': 'https://tr.pinterest.com/pin/2814818512354724/'},
  {'cat': 'tasarim', 'url': 'https://tr.pinterest.com/pin/85990674130764531/'},
  {'cat': 'tasarim', 'url': 'https://tr.pinterest.com/pin/4503668373824349/'},

  {'cat': 'dogumgunu', 'url': 'https://tr.pinterest.com/pin/68749089272/'},
  {'cat': 'dogumgunu', 'url': 'https://tr.pinterest.com/pin/703756186595154/'},
  {'cat': 'dogumgunu', 'url': 'https://tr.pinterest.com/pin/140806234300039/'},

  {'cat': 'gs', 'url': 'https://www.instagram.com/reels/DCHKLfoi6vL/'},
  {'cat': 'gs', 'url': 'https://www.instagram.com/p/DNwCGiUwIdP/?igsh=MTV5NDQ0b3ZydW45aw%3D%3D'},
  {'cat': 'gs', 'url': 'https://www.instagram.com/p/DR2LwwXCMSg/'},
  {'cat': 'gs', 'url': 'https://www.instagram.com/p/DSNvgllCD1L/'},
  {'cat': 'gs', 'url': 'https://www.instagram.com/p/DRXuAL7ALjn/'},

  {'cat': 'yazilim', 'url': 'https://x.com/acerionsjournal/status/1991481023717154898?s=48', 'title': 'Acerion Yazılım Günlüğü'},
  {'cat': 'yazilim', 'url': 'https://x.com/pelingpt/status/1991798835664810405?s=48', 'title': 'PelinGPT AI Gelişmeleri'},
  {'cat': 'yazilim', 'url': 'https://x.com/eddyikd2/status/1994912658987127073?s=48', 'title': 'Yazılım İpuçları'},
];

// Manual Fallback Map
final fallbackImages = {
    // Muzik (Insta)
    'https://www.instagram.com/p/CqDArZ3jrXm/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==': 'https://images.unsplash.com/photo-1470225620780-dba8ba36b745?auto=format&fit=crop&w=800',

    // Seyahat
    'https://www.instagram.com/reel/DSNs_bUDjwx/?utm_source=ig_web_copy_link&igsh=NTc4MTIwNjQ2YQ==': 'https://images.unsplash.com/photo-1476514525535-07fb3b4ae5f1?auto=format&fit=crop&w=800',
    'https://www.instagram.com/reel/DO6oTuxCmqc/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==': 'https://images.unsplash.com/photo-1469854523086-cc02fe5d8800?auto=format&fit=crop&w=800',
    'https://www.instagram.com/reel/DPlXtvrDCzw/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800',

    // Teknoloji
    'https://www.instagram.com/reel/DByz-XOIww9/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==': 'https://images.unsplash.com/photo-1519389950473-47ba0277781c?auto=format&fit=crop&w=800',

    // Komik
    'https://www.instagram.com/reel/DFuU84vNr4Y/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==': 'https://images.unsplash.com/photo-1533738363-b7f9aef128ce?auto=format&fit=crop&w=800',
    'https://www.instagram.com/reel/DGNasReN8oO/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==': 'https://images.unsplash.com/photo-1515536765-9b2a740fa685?auto=format&fit=crop&w=800',
    'https://www.instagram.com/reel/DFNbTG_MWVe/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==': 'https://images.unsplash.com/photo-1574158622682-e40e69881006?auto=format&fit=crop&w=800',
    'https://www.instagram.com/reels/DNtAjoBUB-g/': 'https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?auto=format&fit=crop&w=800',
    'https://www.instagram.com/p/DRkNjDaDl5o/': 'https://images.unsplash.com/photo-1541364983171-a8ba01e95cfc?auto=format&fit=crop&w=800',

    // Gelisim
    'https://www.instagram.com/reel/DFw2E8VND0J/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==': 'https://images.unsplash.com/photo-1552508744-1696d4464960?auto=format&fit=crop&w=800',

    // Restaurant
    'https://www.instagram.com/reel/DLdDWS6CMj4/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800',
    'https://www.instagram.com/reel/DFqJQCBIlM5/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==': 'https://images.unsplash.com/photo-1559339352-11d035aa65de?auto=format&fit=crop&w=800',
    'https://www.instagram.com/reel/DOmAnXSABOu/?utm_source=ig_web_copy_link&igsh=MzRlODBiNWFlZA==': 'https://images.unsplash.com/photo-1552566626-52f8b828add9?auto=format&fit=crop&w=800',
    
    // Tasarim
    'https://tr.pinterest.com/pin/703756188753159/': 'https://images.unsplash.com/photo-1561070791-2526d30994b5?auto=format&fit=crop&w=800',
    'https://tr.pinterest.com/pin/2814818512354724/': 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?auto=format&fit=crop&w=800',
    'https://tr.pinterest.com/pin/85990674130764531/': 'https://images.unsplash.com/photo-1513519245088-0e12902e5a38?auto=format&fit=crop&w=800',
    'https://tr.pinterest.com/pin/4503668373824349/': 'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=800',

    // Dogumgunu
    'https://tr.pinterest.com/pin/68749089272/': 'https://images.unsplash.com/photo-1513151233558-d860c5398176?auto=format&fit=crop&w=800',
    'https://tr.pinterest.com/pin/703756186595154/': 'https://images.unsplash.com/photo-1530103862676-de3c9da59af7?auto=format&fit=crop&w=800',
    'https://tr.pinterest.com/pin/140806234300039/': 'https://images.unsplash.com/photo-1464349153735-7db50ed83c84?auto=format&fit=crop&w=800',

    // GS
    'https://www.instagram.com/reels/DCHKLfoi6vL/': 'https://images.unsplash.com/photo-1510051640316-cee39563ddab?auto=format&fit=crop&w=800',
    'https://www.instagram.com/p/DNwCGiUwIdP/?igsh=MTV5NDQ0b3ZydW45aw%3D%3D': 'https://images.unsplash.com/photo-1508264560946-8a032dd29d81?auto=format&fit=crop&w=800',
    'https://www.instagram.com/p/DR2LwwXCMSg/': 'https://images.unsplash.com/photo-1518091043644-c1d4457512c6?auto=format&fit=crop&w=800',
    'https://www.instagram.com/p/DSNvgllCD1L/': 'https://images.unsplash.com/photo-1563861826-5b6509f69747?auto=format&fit=crop&w=800',
    'https://www.instagram.com/p/DRXuAL7ALjn/': 'https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?auto=format&fit=crop&w=800',

    // Yazilim (X)
    'https://x.com/acerionsjournal/status/1991481023717154898?s=48': 'https://images.unsplash.com/photo-1515879218367-8466d910aaa4?auto=format&fit=crop&w=800',
    'https://x.com/pelingpt/status/1991798835664810405?s=48': 'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?auto=format&fit=crop&w=800',
    'https://x.com/eddyikd2/status/1994912658987127073?s=48': 'https://images.unsplash.com/photo-1461749280684-dccba630e2f6?auto=format&fit=crop&w=800',
};

Future<void> main() async {
  print('Starting Demo Asset & Title Downloader...');
  final client = http.Client();
  final headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
  };

  final generatedItems = <Map<String, String>>[];
  int index = 0;

  for (var item in rawItems) {
    final filename = 'item_$index.jpg';
    index++;
    
    final url = item['url']!;
    final cat = item['cat']!;
    final filepath = 'assets/demo_images/$filename';

    String? imageUrl;
    
    // 1. Resolve Image URL
    if (fallbackImages.containsKey(url)) {
        imageUrl = fallbackImages[url];
    } else if (url.contains('youtu')) {
       String? videoId;
       if (url.contains('v=')) {
         videoId = url.split('v=')[1].split('&')[0];
       } else if (url.contains('youtu.be/')) videoId = url.split('youtu.be/')[1].split('?')[0];
       else if (url.contains('shorts/')) videoId = url.split('shorts/')[1].split('?')[0];
       
       if (videoId != null) {
         imageUrl = 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
       }
    } else {
      try {
        final response = await client.get(Uri.parse(url), headers: headers);
        if (response.statusCode == 200) {
           final document = parser.parse(response.body);
           final metas = document.getElementsByTagName('meta');
           for (var meta in metas) {
              if (meta.attributes['property'] == 'og:image' || meta.attributes['name'] == 'twitter:image') {
                 imageUrl = meta.attributes['content'];
                 break;
              }
           }
        }
      } catch (e) {}
    }

    // 2. Resolve Title
    String? title = item['title']; // Use manual title if exists
    if (title == null) {
        try {
             // Skip youtube scraping, use generic
             if (!url.contains('youtu')) {
                 final response = await client.get(Uri.parse(url), headers: headers);
                 if (response.statusCode == 200) {
                     final document = parser.parse(response.body);
                     // Try OG Title
                     final metas = document.getElementsByTagName('meta');
                     for (var meta in metas) {
                        if (meta.attributes['property'] == 'og:title' || meta.attributes['name'] == 'twitter:title') {
                           title = meta.attributes['content'];
                           break;
                        }
                     }
                     // Fallback to <title>
                     title ??= document.getElementsByTagName('title').firstOrNull?.text;
                 }
             }
        } catch (e) {}
    }
    
    title ??= 'Demo İçerik $index';
    
    // 3. Download Image
    if (imageUrl != null) {
      try {
        if (url.contains('youtu')) {
             final check = await client.head(Uri.parse(imageUrl));
             if (check.statusCode == 404) {
                imageUrl = 'https://img.youtube.com/vi/${imageUrl.split("/")[4]}/hqdefault.jpg';
             }
        }
        print('   -> Downloading: $imageUrl');
        final imgResponse = await client.get(Uri.parse(imageUrl));
        if (imgResponse.statusCode == 200) {
          await File(filepath).writeAsBytes(imgResponse.bodyBytes);
        }
      } catch (e) { print('Download Error: $e'); }
    }
    
    // 4. Add to List
    generatedItems.add({
        'cat': cat,
        'url': url,
        'title': title.replaceAll("'", "\\'").trim(),
        'image': 'assets/demo_images/$filename'
    });
    
    await Future.delayed(const Duration(milliseconds: 100));
  }
  
  // 5. Generate Dart File
  print('Writing generated data to lib/core/utils/demo_mock_data.dart...');
  final sb = StringBuffer();
  sb.writeln('// Generated by scripts/fetch_demo_assets.dart');
  sb.writeln('const demoMockData = [');
  for (var item in generatedItems) {
      sb.writeln("  {");
      sb.writeln("    'cat': '${item['cat']}',");
      sb.writeln("    'url': '${item['url']}',");
      sb.writeln("    'title': '${item['title']}',");
      sb.writeln("    'image': '${item['image']}',");
      sb.writeln("  },");
  }
  sb.writeln('];');
  
  await File('lib/core/utils/demo_mock_data.dart').writeAsString(sb.toString());
  print('Done!');
}
