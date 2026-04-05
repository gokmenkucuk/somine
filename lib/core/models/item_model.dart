import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:somine_app/core/config/api_config.dart';

/// Type of saved item
enum ItemType { link, note, image }

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

  OGMetadata copyWith({
    String? title,
    String? description,
    String? imageUrl,
    String? siteName,
    String? faviconUrl,
  }) {
    return OGMetadata(
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      siteName: siteName ?? this.siteName,
      faviconUrl: faviconUrl ?? this.faviconUrl,
    );
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
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? reminderId;
  final bool hasReminder;

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
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.reminderId,
    this.hasReminder = false,
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
      ogMetadata: OGMetadata.fromMap(
        data['ogMetadata'] as Map<String, dynamic>?,
      ),
      isFavorite: data['isFavorite'] as bool? ?? false,
      order: data['order'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: data['isDeleted'] as bool? ?? false,
      deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
      reminderId: data['reminderId'] as String?,
      hasReminder: data['hasReminder'] as bool? ?? false,
    );
  }

  factory ItemModel.fromApi(
    Map<String, dynamic> json, {
    required String userId,
    bool isDeleted = false,
  }) {
    return ItemModel(
      id: json['id'] as String,
      userId: userId,
      categoryId: json['categoryId'] as String?,
      type: _itemTypeFromApi(json['type']),
      url: json['url'] as String?,
      note: json['note'] as String?,
      imageUrl: json['imageUrl'] as String?,
      ogMetadata: OGMetadata(
        title: json['ogTitle'] as String?,
        description: json['ogDescription'] as String?,
        imageUrl: json['ogImageUrl'] as String?,
        siteName: json['ogSiteName'] as String?,
        faviconUrl: json['ogFaviconUrl'] as String?,
      ),
      isFavorite: json['isFavorite'] as bool? ?? false,
      order: json['sortOrder'] as int? ?? json['order'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      isDeleted: isDeleted,
      deletedAt:
          isDeleted
              ? DateTime.tryParse(json['updatedAt'] as String? ?? '')
              : null,
      reminderId: null,
      hasReminder: json['hasReminder'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toApiCreateRequest() {
    return {
      'url': _normalizedOptionalString(url),
      'note': _normalizedOptionalString(note),
      'imageUrl': _normalizedOptionalString(imageUrl),
      'type': type.index,
      'categoryId': _normalizedOptionalString(categoryId),
      'ogTitle': _normalizedOptionalString(ogMetadata?.title),
      'ogDescription': _normalizedOptionalString(ogMetadata?.description),
      'ogImageUrl': _normalizedOptionalString(ogMetadata?.imageUrl),
      'ogSiteName': _normalizedOptionalString(ogMetadata?.siteName),
      'ogFaviconUrl': _normalizedOptionalString(ogMetadata?.faviconUrl),
    };
  }

  Map<String, dynamic> toApiUpdateRequest() {
    final normalizedCategoryId = _normalizedOptionalString(categoryId);
    return {
      'url': _normalizedOptionalString(url),
      'note': _normalizedOptionalString(note),
      'imageUrl': _normalizedOptionalString(imageUrl),
      'categoryId': normalizedCategoryId,
      'clearCategory': normalizedCategoryId == null,
      'ogTitle': _normalizedOptionalString(ogMetadata?.title),
      'ogDescription': _normalizedOptionalString(ogMetadata?.description),
      'ogImageUrl': _normalizedOptionalString(ogMetadata?.imageUrl),
      'ogSiteName': _normalizedOptionalString(ogMetadata?.siteName),
      'ogFaviconUrl': _normalizedOptionalString(ogMetadata?.faviconUrl),
      'isFavorite': isFavorite,
    };
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
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isDeleted': isDeleted,
      'deletedAt': deletedAt != null ? Timestamp.fromDate(deletedAt!) : null,
      'reminderId': reminderId,
      'hasReminder': hasReminder,
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
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    String? reminderId,
    bool? hasReminder,
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
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      reminderId: reminderId ?? this.reminderId,
      hasReminder: hasReminder ?? this.hasReminder,
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
    final img = ogMetadata?.imageUrl ?? imageUrl;
    if (img != null) {
      String correctedImg = img.trim().replaceAll('\n', '').replaceAll('\r', '');
      if (correctedImg.contains('46.224.146.102')) {
        correctedImg = correctedImg.replaceAll('http://46.224.146.102', ApiConfig.baseUrl);
      }
      return correctedImg;
    }
    return null;
  }

  /// Get platform name based on URL
  String get platform {
    if (url == null) return 'Web';
    final lowerUrl = url!.toLowerCase();

    if (lowerUrl.contains('instagram.com')) return 'Instagram';
    if (lowerUrl.contains('youtube.com') || lowerUrl.contains('youtu.be')) {
      return 'YouTube';
    }
    if (lowerUrl.contains('twitter.com') || lowerUrl.contains('x.com')) {
      return 'X';
    }
    if (lowerUrl.contains('tiktok.com')) return 'TikTok';
    if (lowerUrl.contains('linkedin.com')) return 'LinkedIn';
    if (lowerUrl.contains('spotify.com')) return 'Spotify';
    if (lowerUrl.contains('pinterest.com')) return 'Pinterest';
    if (lowerUrl.contains('reddit.com')) return 'Reddit';
    if (lowerUrl.contains('medium.com')) return 'Medium';
    if (lowerUrl.contains('behance.net')) return 'Behance';
    if (lowerUrl.contains('dribbble.com')) return 'Dribbble';

    // Explicitly check for generic web
    return 'Web';
  }

  @override
  String toString() {
    return 'ItemModel(id: $id, type: $type, url: $url)';
  }

  static ItemType _itemTypeFromApi(dynamic rawType) {
    if (rawType is int && rawType >= 0 && rawType < ItemType.values.length) {
      return ItemType.values[rawType];
    }

    if (rawType is String) {
      final normalized = rawType.toLowerCase();
      return ItemType.values.firstWhere(
        (itemType) => itemType.name.toLowerCase() == normalized,
        orElse: () => ItemType.link,
      );
    }

    return ItemType.link;
  }

  static String? _normalizedOptionalString(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
