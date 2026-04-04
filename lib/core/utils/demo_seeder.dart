import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:uuid/uuid.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:somine_app/core/utils/demo_mock_data.dart';

class DemoSeeder {
  
  static Future<void> seed(WidgetRef ref) async {
    debugPrint('DemoSeeder: Starting...');
    final user = ref.read(currentUserProvider);
    if (user == null) {
      debugPrint('DemoSeeder Error: User is null!');
      return;
    }
    
    debugPrint('DemoSeeder: Active User UID: ${user.uid}');
    final firestore = FirebaseFirestore.instance;
    final uuid = const Uuid();
    final random = Random();

    // 0. FORCE DELETE EVERYTHING
    debugPrint('DemoSeeder: Deleting old data...');
    await Future.wait([
      _deleteCollection(firestore, 'items', user.uid),
      _deleteCollection(firestore, 'categories', user.uid),
      _deleteSubCollection(firestore, 'users/${user.uid}/items'),
      _deleteSubCollection(firestore, 'users/${user.uid}/categories'),
    ]);
    
    // 1. Create Categories (Updated list - only what we have content for)
    debugPrint('DemoSeeder: Creating categories...');
    final writeBatch = firestore.batch();
    
    final catIds = {
      'muzik': uuid.v4(),
      'seyahat': uuid.v4(),
      'restaurant': uuid.v4(),
      'tasarim': uuid.v4(),
      'dogumgunu': uuid.v4(),
      'yazilim': uuid.v4(),
    };

    final categories = [
      _createCategory(user.uid, catIds['muzik']!, 'Müzik', '🎵', 1),
      _createCategory(user.uid, catIds['seyahat']!, 'Seyahat', '✈️', 2),
      _createCategory(user.uid, catIds['restaurant']!, 'Restaurant', '🍽️', 3),
      _createCategory(user.uid, catIds['tasarim']!, 'Tasarım', '🎨', 4),
      _createCategory(user.uid, catIds['dogumgunu']!, 'Doğum Günü', '🎂', 5),
      _createCategory(user.uid, catIds['yazilim']!, 'Yazılım', '🖥️', 6),
    ];

    for (var cat in categories) {
      writeBatch.set(firestore.collection('categories').doc(cat.id), cat.toFirestore());
    }

    // 2. Prepare Items Data
    debugPrint('DemoSeeder: Processing ${demoMockData.length} items...');

    final futures = demoMockData.map((raw) async {
       return _processSingleItem(raw, user.uid, catIds, random);
    }).toList();

    final items = await Future.wait(futures);

    for (var item in items) {
      if (item != null) {
        writeBatch.set(firestore.collection('items').doc(item.id), item.toFirestore());
      }
    }

    await writeBatch.commit();
    debugPrint('DemoSeeder: Batch committed successfully!');
  }

  // --- Helpers ---

  static Future<void> _deleteCollection(FirebaseFirestore fs, String collection, String userId) async {
    final snapshot = await fs.collection(collection).where('userId', isEqualTo: userId).get();
    if (snapshot.docs.isEmpty) return;
    await Future.wait(snapshot.docs.map((doc) => doc.reference.delete()));
  }

  static Future<void> _deleteSubCollection(FirebaseFirestore fs, String path) async {
    final snapshot = await fs.collection(path).get();
    if (snapshot.docs.isEmpty) return;
    await Future.wait(snapshot.docs.map((doc) => doc.reference.delete()));
  }

  static Future<ItemModel?> _processSingleItem(
    Map<String, dynamic> raw, 
    String userId, 
    Map<String, String> catIds, 
    Random random
  ) async {
    final String title = raw['title'] ?? 'İçerik';
    final String url = raw['url']!;
    final String cat = raw['cat']!;
    final String imageType = raw['imageType']!;
    final String imageId = raw['imageId'] ?? '';
    
    final catId = catIds[cat];
    if (catId == null) {
      debugPrint('DemoSeeder: Unknown category: $cat');
      return null;
    }

    String? imageUrl;

    // Resolve image based on type
    switch (imageType) {
      case 'youtube':
        // YouTube thumbnail URL
        imageUrl = 'https://img.youtube.com/vi/$imageId/hqdefault.jpg';
        break;
        
      case 'local':
        // Local asset path
        imageUrl = 'src/img/$imageId';
        break;
        
      case 'pinterest':
        // Try to scrape og:image from Pinterest
        imageUrl = await _scrapePinterestImage(url);
        break;
        
      case 'clean':
        // No image - UI will show clean card with logo
        imageUrl = null;
        break;
    }

    DateTime createdAt = DateTime.now().subtract(Duration(
       days: random.nextInt(15), 
       minutes: random.nextInt(60),
    ));

    return ItemModel(
       id: const Uuid().v4(),
       userId: userId,
       categoryId: catId,
       type: ItemType.link,
       url: url,
       imageUrl: imageUrl, 
       ogMetadata: OGMetadata(
         title: title,
         imageUrl: imageUrl, 
         description: 'Demo content',
       ),
       createdAt: createdAt,
       updatedAt: DateTime.now(),
     );
  }

  static Future<String?> _scrapePinterestImage(String url) async {
    try {
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
      };
      
      final response = await http.get(Uri.parse(url), headers: headers)
        .timeout(const Duration(seconds: 4));
      
      if (response.statusCode == 200) {
        final document = parser.parse(response.body);
        final metaTags = document.getElementsByTagName('meta');
        
        for (var tag in metaTags) {
          final property = tag.attributes['property'];
          final content = tag.attributes['content'];
          
          if (property == 'og:image' && content != null && content.isNotEmpty) {
            return content;
          }
        }
      }
    } catch (e) {
      debugPrint('DemoSeeder: Pinterest scrape failed for $url: $e');
    }
    return null;
  }

  static CategoryModel _createCategory(String userId, String id, String name, String icon, int order) {
    return CategoryModel(
      id: id,
      userId: userId,
      name: name,
      icon: icon, 
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
