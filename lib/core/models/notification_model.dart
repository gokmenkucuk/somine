enum NotificationType {
  shareRequest, // Paylaşım isteği geldi
  shareAccepted, // Paylaşımım kabul edildi
  shareRejected, // Paylaşımım reddedildi
}

class NotificationModel {
  final String? id;
  final String userId;
  final NotificationType type;
  final String title;
  final String message;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.message,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromApi(
    Map<String, dynamic> json, {
    required String userId,
  }) {
    final rawData = json['data'];
    return NotificationModel(
      id: json['id'] as String?,
      userId: userId,
      type: NotificationType.values.firstWhere(
        (t) =>
            t.name.toLowerCase() ==
            (json['type'] as String? ?? '').toLowerCase(),
        orElse: () => NotificationType.shareRequest,
      ),
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: rawData is Map<String, dynamic> ? rawData : const {},
      isRead: json['isRead'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? title,
    String? message,
    Map<String, dynamic>? data,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      message: message ?? this.message,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
