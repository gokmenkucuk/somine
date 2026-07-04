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

  factory ShareModel.fromApi(Map<String, dynamic> json) {
    return ShareModel(
      id: json['id'] as String?,
      fromUserId: json['fromUserId'] as String? ?? '',
      fromUserName: json['fromUserName'] as String? ?? '',
      fromUserEmail: json['fromUserEmail'] as String? ?? '',
      toUserId: json['toUserId'] as String? ?? '',
      toUserEmail: json['toUserEmail'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      status: ShareStatus.values.firstWhere(
        (s) =>
            s.name.toLowerCase() ==
            (json['status'] as String? ?? '').toLowerCase(),
        orElse: () => ShareStatus.pending,
      ),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      acceptedAt: DateTime.tryParse(json['acceptedAt'] as String? ?? ''),
      rejectedAt: DateTime.tryParse(json['rejectedAt'] as String? ?? ''),
    );
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
