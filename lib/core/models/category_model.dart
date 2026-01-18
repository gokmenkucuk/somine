import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final String? icon; // emoji or icon name
  final String? color; // hex color
  final int order;
  final bool isVault; // Locked with FaceID/TouchID
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
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create from Firestore document
  factory CategoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return CategoryModel(
      id: doc.id,
      userId: data['userId'] as String,
      name: data['name'] as String,
      icon: data['icon'] as String?,
      color: data['color'] as String?,
      order: data['order'] as int? ?? 0,
      isVault: data['isVault'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'name': name,
      'icon': icon,
      'color': color,
      'order': order,
      'isVault': isVault,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Default categories for new users
  static List<CategoryModel> defaultCategories(String userId) {
    final now = DateTime.now();
    return [
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Dinlemek İstediğim',
        icon: '🎵',
        color: '#8B5CF6',
        order: 0,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Gitmek İstediğim Yerler',
        icon: '✈️',
        color: '#0EA5E9',
        order: 1,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Denemek İstediğim Tarifler',
        icon: '🍴',
        color: '#EF4444',
        order: 2,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'İlham',
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


