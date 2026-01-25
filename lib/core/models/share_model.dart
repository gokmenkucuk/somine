import 'package:cloud_firestore/cloud_firestore.dart';

enum ShareStatus { pending, accepted, rejected }

class ShareModel {
  final String? id;
  final String fromUserId;
  final String fromUserName;
  final String fromUserEmail;
  final String toUserId;
  final String toUserEmail;
  final String categoryId;
  final String categoryName;
  final ShareStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? rejectedAt;

  ShareModel({
    this.id,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserEmail,
    required this.toUserId,
    required this.toUserEmail,
    required this.categoryId,
    required this.categoryName,
    this.status = ShareStatus.pending,
    required this.createdAt,
    this.acceptedAt,
    this.rejectedAt,
  });

  factory ShareModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ShareModel(
      id: doc.id,
      fromUserId: data['fromUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      fromUserEmail: data['fromUserEmail'] ?? '',
      toUserId: data['toUserId'] ?? '',
      toUserEmail: data['toUserEmail'] ?? '',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      status: ShareStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ShareStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      rejectedAt: (data['rejectedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'fromUserName': fromUserName,
      'fromUserEmail': fromUserEmail,
      'toUserId': toUserId,
      'toUserEmail': toUserEmail,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      if (acceptedAt != null) 'acceptedAt': Timestamp.fromDate(acceptedAt!),
      if (rejectedAt != null) 'rejectedAt': Timestamp.fromDate(rejectedAt!),
    };
  }

  ShareModel copyWith({
    String? id,
    String? fromUserId,
    String? fromUserName,
    String? fromUserEmail,
    String? toUserId,
    String? toUserEmail,
    String? categoryId,
    String? categoryName,
    ShareStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? rejectedAt,
  }) {
    return ShareModel(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      fromUserEmail: fromUserEmail ?? this.fromUserEmail,
      toUserId: toUserId ?? this.toUserId,
      toUserEmail: toUserEmail ?? this.toUserEmail,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      rejectedAt: rejectedAt ?? this.rejectedAt,
    );
  }
}
