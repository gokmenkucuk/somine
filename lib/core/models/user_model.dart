class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? username; // Benzersiz kullanıcı adı (@kullaniciadi)
  final String? photoURL;
  final String? photoBase64; // Base64 encoded low-res profile image (for when Storage fails)
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.username,
    this.photoURL,
    this.photoBase64,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? username,
    String? photoURL,
    String? photoBase64,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      photoURL: photoURL ?? this.photoURL,
      photoBase64: photoBase64 ?? this.photoBase64,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, username: $username)';
  }
}


