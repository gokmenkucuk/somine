import 'package:cloud_firestore/cloud_firestore.dart';

class CategoryModel {
  final String id;
  final String userId;
  final String name;
  final String? icon; // emoji or icon name
  final String? color; // hex color
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryModel({
    required this.id,
    required this.userId,
    required this.name,
    this.icon,
    this.color,
    this.order = 0,
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
        name: 'Genel',
        icon: '📌',
        color: '#6366F1',
        order: 0,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Okumak İstediğim',
        icon: '📚',
        color: '#EC4899',
        order: 1,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'İzlemek İstediğim',
        icon: '🎬',
        color: '#F59E0B',
        order: 2,
        createdAt: now,
        updatedAt: now,
      ),
      CategoryModel(
        id: '',
        userId: userId,
        name: 'Satın Almak İstediğim',
        icon: '🛒',
        color: '#10B981',
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


