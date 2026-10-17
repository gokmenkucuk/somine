import 'package:flutter_test/flutter_test.dart';
import 'package:somine_app/core/models/blocked_user_model.dart';
import 'package:somine_app/core/models/share_model.dart';

void main() {
  group('ShareReportReason', () {
    test('api values match the server contract', () {
      expect(
        ShareReportReason.values.map((r) => r.apiValue).toList(),
        ['spam', 'inappropriate', 'harassment', 'other'],
      );
    });
  });

  group('BlockedUserModel', () {
    test('parses GET /api/users/blocked row', () {
      final model = BlockedUserModel.fromApi({
        'userId': 'b6f1c0de-0000-0000-0000-000000000001',
        'displayName': 'Ada',
        'username': 'ada',
        'photoUrl': null,
        'blockedAt': '2026-10-17T10:00:00Z',
      });

      expect(model.userId, 'b6f1c0de-0000-0000-0000-000000000001');
      expect(model.label, 'Ada');
      expect(model.blockedAt, DateTime.utc(2026, 10, 17, 10));
    });

    test('label falls back to @username, then null', () {
      final withHandle = BlockedUserModel.fromApi({
        'userId': 'x',
        'displayName': '  ',
        'username': 'ada',
      });
      final anonymous = BlockedUserModel.fromApi({'userId': 'y'});

      expect(withHandle.label, '@ada');
      expect(anonymous.label, isNull);
    });
  });
}
