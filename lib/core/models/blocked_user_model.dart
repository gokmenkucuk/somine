/// GET /api/users/blocked satırı.
class BlockedUserModel {
  final String userId;
  final String? displayName;
  final String? username;
  final String? photoUrl;
  final DateTime blockedAt;

  const BlockedUserModel({
    required this.userId,
    this.displayName,
    this.username,
    this.photoUrl,
    required this.blockedAt,
  });

  /// Görünen ad; yoksa @kullanıcıadı; o da yoksa null (çağıran yer
  /// yerelleştirilmiş bir yedek ad kullanır).
  String? get label {
    final name = displayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final handle = username?.trim();
    if (handle != null && handle.isNotEmpty) return '@$handle';
    return null;
  }

  factory BlockedUserModel.fromApi(Map<String, dynamic> json) {
    return BlockedUserModel(
      userId: json['userId'] as String? ?? '',
      displayName: json['displayName'] as String?,
      username: json['username'] as String?,
      photoUrl: json['photoUrl'] as String?,
      blockedAt:
          DateTime.tryParse(json['blockedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
