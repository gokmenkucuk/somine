import 'package:somine_app/core/config/api_config.dart';
import 'package:somine_app/core/utils/content_preview_policy.dart';

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

  /// Sunucuda saklanan og:image piksel boyutu (varsa).
  ///
  /// Masonry kutusunun oranını ilk karede bilmek için gerekir. Yerel önbellek
  /// (`ImageAspectRatioCache`) yalnız ölçümü yapan cihazda geçerlidir; yeni bir
  /// telefonda veya yeniden kurulumda ilk görüntülemede kutu sıçrar. Boyut
  /// kaydetme anında istemcide ölçülüp item ile birlikte gönderildiği için her
  /// cihaz oranı ilk saniyeden bilir. Eski kayıtlarda `null`'dır.
  final int? ogImageWidth;
  final int? ogImageHeight;

  final bool isFavorite;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final String? reminderId;
  final bool hasReminder;
  final DateTime? lastOpenedAt;

  const ItemModel({
    required this.id,
    required this.userId,
    this.categoryId,
    required this.type,
    this.url,
    this.note,
    this.imageUrl,
    this.ogMetadata,
    this.ogImageWidth,
    this.ogImageHeight,
    this.isFavorite = false,
    this.order = 0,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.reminderId,
    this.hasReminder = false,
    this.lastOpenedAt,
  });

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
      ogImageWidth: _positiveIntOrNull(json['ogImageWidth']),
      ogImageHeight: _positiveIntOrNull(json['ogImageHeight']),
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
      lastOpenedAt: DateTime.tryParse(json['lastOpenedAt'] as String? ?? ''),
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
      'ogImageWidth': ogImageWidth,
      'ogImageHeight': ogImageHeight,
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
      'ogImageWidth': ogImageWidth,
      'ogImageHeight': ogImageHeight,
      'isFavorite': isFavorite,
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
    int? ogImageWidth,
    int? ogImageHeight,
    bool? isFavorite,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    String? reminderId,
    bool? hasReminder,
    DateTime? lastOpenedAt,
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
      ogImageWidth: ogImageWidth ?? this.ogImageWidth,
      ogImageHeight: ogImageHeight ?? this.ogImageHeight,
      isFavorite: isFavorite ?? this.isFavorite,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      reminderId: reminderId ?? this.reminderId,
      hasReminder: hasReminder ?? this.hasReminder,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
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
    final img =
        ContentPreviewPolicy.canUsePreviewImage(
              url: url,
              imageUrl: ogMetadata?.imageUrl,
            )
            ? ogMetadata?.imageUrl
            : imageUrl;
    if (img != null) {
      String correctedImg = img
          .trim()
          .replaceAll('\n', '')
          .replaceAll('\r', '');
      // Fix old IP address
      if (correctedImg.contains('46.224.146.102')) {
        correctedImg = correctedImg.replaceAll(
          'http://46.224.146.102',
          ApiConfig.baseUrl,
        );
      }
      // Migrate old public /storage/ path to authenticated /api/storage/ path
      if (correctedImg.contains(ApiConfig.baseUrl) &&
          correctedImg.contains('/storage/') &&
          !correctedImg.contains('/api/storage/')) {
        correctedImg = correctedImg.replaceAll('/storage/', '/api/storage/');
      }
      return correctedImg;
    }
    return null;
  }

  /// [displayImage] için sunucudan gelen en-boy oranı (genişlik / yükseklik).
  ///
  /// Masonry kutusu bu oranı ilk karede bilirse hiç sıçramaz — yerel ölçüm veya
  /// önbellek beklemeye gerek kalmaz. `null` dönerse çağıran yerel önbelleğe,
  /// o da boşsa varsayılan orana düşer.
  ///
  /// Boyut yalnızca og:image'a aittir. [displayImage] og:image yerine öğenin
  /// kendi [imageUrl]'ine düştüğünde (ör. harita bağlantıları, SVG) oran
  /// kullanılmaz; aksi halde başka bir görselin oranı uygulanırdı.
  double? get serverImageAspectRatio {
    final width = ogImageWidth;
    final height = ogImageHeight;
    if (width == null || height == null || width <= 0 || height <= 0) {
      return null;
    }
    if (!ContentPreviewPolicy.canUsePreviewImage(
      url: url,
      imageUrl: ogMetadata?.imageUrl,
    )) {
      return null;
    }
    return width / height;
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

  /// API'den gelen boyut alanlarını okur.
  ///
  /// Eski kayıtlarda alan hiç yoktur, bozuk kayıtlarda 0/negatif olabilir;
  /// her iki durumda da `null` döner ve çağıran yerel önbelleğe düşer.
  static int? _positiveIntOrNull(dynamic value) {
    final parsed =
        value is int
            ? value
            : value is num
            ? value.toInt()
            : null;
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  static String? _normalizedOptionalString(String? value) {
    if (value == null) {
      return null;
    }

    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}
