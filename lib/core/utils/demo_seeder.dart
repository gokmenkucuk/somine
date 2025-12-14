import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:somine_app/core/models/category_model.dart';
import 'package:somine_app/core/models/item_model.dart';
import 'package:somine_app/core/providers/auth_providers.dart';
import 'package:uuid/uuid.dart';

class DemoSeeder {
  
  static Future<void> seed(WidgetRef ref) async {
    print('DemoSeeder: Starting...');
    final user = ref.read(currentUserProvider);
    if (user == null) {
      print('DemoSeeder Error: User is null!');
      return;
    }
    print('DemoSeeder: User found ${user.uid}');
    
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    
    // 1. Create Categories
    print('DemoSeeder: Creating categories...');
    final categories = [
      _createCategory(user.uid, 'Baby 🍼', 'pattern:0', 1),
      _createCategory(user.uid, 'Ev Tasarım 🏠', 'pattern:2', 2),
      _createCategory(user.uid, 'Sonradan Dinle 🎵', 'pattern:1', 3), // Red/Pinkish
      _createCategory(user.uid, 'Insta ✨', 'pattern:4', 4), // Purple
    ];

    for (var cat in categories) {
      final docRef = firestore.collection('users').doc(user.uid).collection('categories').doc(cat.id);
      batch.set(docRef, cat.toFirestore());
    }

    // 2. Create Items
    final items = [
      // Baby (Pinterest)
      _createItem(user.uid, categories[0].id, 'https://tr.pinterest.com/pin/365987907239857984/', 
          'Cute Baby Outfit', 'https://images.unsplash.com/photo-1522771930-78848d9293e8?auto=format&fit=crop&w=800&q=80'),
      _createItem(user.uid, categories[0].id, 'https://tr.pinterest.com/pin/492649954549331/', 
          'Nursery Decor Ideas', 'https://images.unsplash.com/photo-1519689680058-324335c77eba?auto=format&fit=crop&w=800&q=80'),
      _createItem(user.uid, categories[0].id, 'https://tr.pinterest.com/pin/70437490574431/', 
          'Baby Toys Wishlist', 'https://images.unsplash.com/photo-1596464716127-f9a0639b936f?auto=format&fit=crop&w=800&q=80'),

      // Ev Tasarım (Pinterest)
      _createItem(user.uid, categories[1].id, 'https://tr.pinterest.com/pin/54746951714653717/', 
          'Minimalist Living Room', 'https://images.unsplash.com/photo-1616486338812-3dadae4b4f9d?auto=format&fit=crop&w=800&q=80'),
      _createItem(user.uid, categories[1].id, 'https://tr.pinterest.com/pin/68749202794/', 
          'Cozy Bedroom Inspiration', 'https://images.unsplash.com/photo-1616594039964-40891a91295f?auto=format&fit=crop&w=800&q=80'),

      // Sonradan Dinle (YouTube)
      _createItem(user.uid, categories[2].id, 'https://www.youtube.com/watch?v=eKQuwAmIVKA&list=RDMMeKQuwAmIVKA&index=1&pp=8AUB', 
          'Favorite Mix 1', 'https://img.youtube.com/vi/eKQuwAmIVKA/maxresdefault.jpg'),
      _createItem(user.uid, categories[2].id, 'https://www.youtube.com/watch?v=0cKV8_MKsMw&list=RDMMeKQuwAmIVKA&index=4', 
          'Chill Vibes Music', 'https://img.youtube.com/vi/0cKV8_MKsMw/maxresdefault.jpg'),

      // Insta (Stories)
      _createItem(user.uid, categories[3].id, 'https://www.instagram.com/stories/highlights/18381099406074908/', 
          'Travel Highlights', 'https://images.unsplash.com/photo-1527631746610-bca00a040d60?auto=format&fit=crop&w=800&q=80'), // Travel vibe
      _createItem(user.uid, categories[3].id, 'https://www.instagram.com/stories/highlights/18020007035017202/', 
          'Food & Coffee', 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?auto=format&fit=crop&w=800&q=80'),
    ];

    for (var item in items) {
      final docRef = firestore.collection('items').doc(item.id);
      batch.set(docRef, item.toFirestore());
    }

    await batch.commit();
    print('DemoSeeder: Batch committed successfully!');
  }

  static CategoryModel _createCategory(String userId, String name, String coverStyle, int order) {
    return CategoryModel(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      color: coverStyle,
      order: order,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static ItemModel _createItem(String userId, String categoryId, String url, String title, String imageUrl) {
    return ItemModel(
      id: const Uuid().v4(),
      userId: userId,
      categoryId: categoryId,
      type: url.contains('youtu') ? ItemType.link : (url.contains('inst') ? ItemType.image : ItemType.link), // Simple logic
      url: url,
      imageUrl: imageUrl, 
      ogMetadata: OGMetadata(
        title: title,
        imageUrl: imageUrl,
        description: 'Demo content added for visual testing.',
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
