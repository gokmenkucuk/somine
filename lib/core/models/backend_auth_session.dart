import 'dart:convert';

class BackendAuthUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? username;
  final String? photoUrl;

  const BackendAuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.username,
    this.photoUrl,
  });

  factory BackendAuthUser.fromJson(Map<String, dynamic> json) {
    return BackendAuthUser(
      id: json['id'] as String,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      username: json['username'] as String?,
      photoUrl: json['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'username': username,
      'photoUrl': photoUrl,
    };
  }
}

class BackendAuthSession {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresInSeconds;
  final DateTime issuedAt;
  final BackendAuthUser user;

  const BackendAuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresInSeconds,
    required this.issuedAt,
    required this.user,
  });

  DateTime get expiresAt => issuedAt.add(Duration(seconds: expiresInSeconds));

  bool get isExpired {
    final refreshThreshold = expiresAt.subtract(const Duration(seconds: 30));
    return DateTime.now().isAfter(refreshThreshold);
  }

  factory BackendAuthSession.fromAuthResponse(Map<String, dynamic> json) {
    return BackendAuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresInSeconds: json['expiresIn'] as int? ?? 3600,
      issuedAt: DateTime.now().toUtc(),
      user: BackendAuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  factory BackendAuthSession.fromStoredJson(Map<String, dynamic> json) {
    return BackendAuthSession(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      tokenType: json['tokenType'] as String? ?? 'Bearer',
      expiresInSeconds: json['expiresInSeconds'] as int? ?? 3600,
      issuedAt: DateTime.parse(json['issuedAt'] as String).toUtc(),
      user: BackendAuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'expiresInSeconds': expiresInSeconds,
      'issuedAt': issuedAt.toIso8601String(),
      'user': user.toJson(),
    };
  }

  String encode() => jsonEncode(toJson());

  static BackendAuthSession? tryDecode(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return BackendAuthSession.fromStoredJson(decoded);
    } catch (_) {
      return null;
    }
  }
}
