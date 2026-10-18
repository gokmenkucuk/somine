class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final String? icon; // emoji or icon name
  final String? color; // hex color
  final int order;
  final bool isVault; // Locked with FaceID/TouchID
  final String? publicLinkToken; // Read-only web link token (null = no link)
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    this.icon,
    this.color,
    this.order = 0,
    this.isVault = false,
    this.publicLinkToken,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CategoryModel.fromApi(
    Map<String, dynamic> json, {
    required String userId,
  }) {
    return CategoryModel(
      id: json['id'] as String,
      userId: userId,
      name: json['name'] as String,
      icon: json['icon'] as String?,
      color: json['color'] as String?,
      order: json['sortOrder'] as int? ?? json['order'] as int? ?? 0,
      isVault: json['isVault'] as bool? ?? false,
      publicLinkToken: json['publicLinkToken'] as String?,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toApiCreateRequest() {
    return {'name': name, 'icon': icon, 'color': color, 'isVault': isVault};
  }

  Map<String, dynamic> toApiUpdateRequest() {
    return {'name': name, 'icon': icon, 'color': color, 'isVault': isVault};
  }

  /// Create a copy with updated fields
  CategoryModel copyWith({
    String? id,
    String? userId,
    String? name,
    String? icon,
    String? color,
    int? order,
    bool? isVault,
    String? publicLinkToken,
    bool clearPublicLinkToken = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      order: order ?? this.order,
      isVault: isVault ?? this.isVault,
      publicLinkToken:
          clearPublicLinkToken ? null : (publicLinkToken ?? this.publicLinkToken),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Yeni kullanıcı için varsayılan koleksiyonlar.
  ///
  /// Adlar veri olarak saklandığı için çağıran taraf onları kullanıcının
  /// dilinde vermeli; model kendi içinde sabit metin tutmaz.
  static List<CategoryModel> defaultCategories(
    String userId, {
    required String musicName,
    required String placesName,
    required String restaurantsName,
    required String inspirationName,
  }) {
    final now = DateTime.now();
    return [
      CategoryModel(
        id: '',
        userId: userId,
        name: musicName,
        icon: '🎵',
        color: '#8B5CF6',
        order: 0,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: placesName,
        icon: '✈️',
        color: '#0EA5E9',
        order: 1,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: restaurantsName,
        icon: '🍽️',
        color: '#EF4444',
        order: 2,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: inspirationName,
        icon: '💡',
        color: '#FBBF24',
        order: 3,
        createdAt: now,
        updatedAt: now,
      ),
    ];
  }

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, icon: $icon)';
  }
}
