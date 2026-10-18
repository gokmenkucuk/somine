import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:somine_app/core/models/backend_auth_session.dart';

void main() {
  group('BackendAuthSession', () {
    test('tryDecode returns null when stored issuedAt is invalid', () {
      final raw = jsonEncode({
        'accessToken': 'access',
        'refreshToken': 'refresh',
        'tokenType': 'Bearer',
        'expiresInSeconds': 3600,
        'issuedAt': 'not-a-date',
        'user': {
          'id': 'user-1',
          'email': 'user@example.com',
          'displayName': 'User',
          'username': 'user',
          'photoUrl': null,
        },
      });

      expect(BackendAuthSession.tryDecode(raw), isNull);
    });
  });
}
