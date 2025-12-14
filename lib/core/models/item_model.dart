import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of saved item
enum ItemType {
  link,
  note,
  image,
}

/// Open Graph metadata for links
class OGMetadata {
  final String? title;
  final String? description;
  final String? imageUrl;
  final String? siteName;
  final String? faviconUrl;

  const OGMetadata({
    this.title,
    this.description,
    this.imageUrl,
    this.siteName,
    this.faviconUrl,
  });

  factory OGMetadata.fromMap(Map<String, dynamic>? data) {
    if (data == null) return const OGMetadata();
    return OGMetadata(
      title: data['title'] as String?,
      description: data['description'] as String?,
      imageUrl: data['imageUrl'] as String?,
      siteName: data['siteName'] as String?,
      faviconUrl: data['faviconUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'siteName': siteName,
      'faviconUrl': faviconUrl,
    };
  }

  bool get isEmpty =>
      title == null &&
      description == null &&
      imageUrl == null &&
      siteName == null;

  @override
  String toString() {
    return 'OGMetadata(title: $title, siteName: $siteName)';
  }
}

class ItemModel {
  final String id;
  final String userId;
  final String? categoryId;
  final ItemType type;
  final String? url;
  final String? note;
  final String? imageUrl;
  final OGMetadata? ogMetadata;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ItemModel({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.type,
    this.url,
    this.note,
    this.imageUrl,
    this.ogMetadata,
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory ItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return ItemModel(
      id: doc.id,
      userId: data['userId'] as String,
      categoryId: data['categoryId'] as String?,
      type: ItemType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => ItemType.link,
      ),
      url: data['url'] as String?,
      note: data['note'] as String?,
      imageUrl: data['imageUrl'] as String?,
      ogMetadata: OGMetadata.fromMap(data['ogMetadata'] as Map<String, dynamic>?),
      isFavorite: data['isFavorite'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'categoryId': categoryId,
      'type': type.name,
      'url': url,
      'note': note,
      'imageUrl': imageUrl,
      'ogMetadata': ogMetadata?.toMap(),
      'isFavorite': isFavorite,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a copy with updated fields
  ItemModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    ItemType? type,
    String? url,
    String? note,
    String? imageUrl,
    OGMetadata? ogMetadata,
    bool? isFavorite,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ItemModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      type: type ?? this.type,
      url: url ?? this.url,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
      ogMetadata: ogMetadata ?? this.ogMetadata,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get display title (from OG metadata or URL)
  String get displayTitle {
    if (ogMetadata?.title != null && ogMetadata!.title!.isNotEmpty) {
      return ogMetadata!.title!;
    }
    if (url != null) {
      final uri = Uri.tryParse(url!);
      return uri?.host ?? url!;
    }
    if (note != null && note!.isNotEmpty) {
      return note!.length > 50 ? '${note!.substring(0, 50)}...' : note!;
    }
    return 'Untitled';
  }

  /// Get display image (from OG metadata or item imageUrl)
  String? get displayImage {
    return ogMetadata?.imageUrl ?? imageUrl;
  }

  @override
  String toString() {
    return 'ItemModel(id: $id, type: $type, url: $url)';
  }
}


