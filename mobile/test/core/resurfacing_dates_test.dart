import 'package:flutter_test/flutter_test.dart';
import 'package:somine_app/core/utils/resurfacing_dates.dart';

void main() {
  group('ResurfacingDates.tomorrow', () {
    test('bir sonraki günü döner', () {
      final now = DateTime(2026, 8, 1, 14, 30); // Cumartesi
      final result = ResurfacingDates.tomorrow(now);
      expect(result.year, 2026);
      expect(result.month, 8);
      expect(result.day, 2);
    });

    test('ay sonunu doğru devirir', () {
      final now = DateTime(2026, 8, 31, 9, 0);
      final result = ResurfacingDates.tomorrow(now);
      expect(result.month, 9);
      expect(result.day, 1);
    });
  });

  group('ResurfacingDates.nextSaturday', () {
    test('hafta içinden sıradaki Cumartesi', () {
      final now = DateTime(2026, 8, 5, 10, 0); // Çarşamba
      final result = ResurfacingDates.nextSaturday(now);
      expect(result.weekday, DateTime.saturday);
      expect(result.day, 8);
    });

    test('Cumartesi gününden bir sonraki haftanın Cumartesisi', () {
      final now = DateTime(2026, 8, 1, 10, 0); // Cumartesi
      final result = ResurfacingDates.nextSaturday(now);
      expect(result.weekday, DateTime.saturday);
      expect(result.day, 8);
    });

    test('Pazar gününden ertesi Cumartesi', () {
      final now = DateTime(2026, 8, 2, 10, 0); // Pazar
      final result = ResurfacingDates.nextSaturday(now);
      expect(result.weekday, DateTime.saturday);
      expect(result.day, 8);
    });
  });

  group('ResurfacingDates.nextSundayAt', () {
    test('hafta içinden sıradaki Pazar 19:00', () {
      final now = DateTime(2026, 8, 5, 10, 0); // Çarşamba
      final result = ResurfacingDates.nextSundayAt(now);
      expect(result, DateTime(2026, 8, 9, 19, 0));
    });

    test('Pazar 19:00 öncesi ise aynı gün 19:00', () {
      final now = DateTime(2026, 8, 2, 12, 0); // Pazar öğlen
      final result = ResurfacingDates.nextSundayAt(now);
      expect(result, DateTime(2026, 8, 2, 19, 0));
    });

    test('Pazar 19:00 sonrası ise gelecek Pazar', () {
      final now = DateTime(2026, 8, 2, 20, 0); // Pazar akşam
      final result = ResurfacingDates.nextSundayAt(now);
      expect(result, DateTime(2026, 8, 9, 19, 0));
    });

    test('sonuç her zaman gelecektedir', () {
      final now = DateTime(2026, 8, 2, 19, 0); // Tam 19:00
      final result = ResurfacingDates.nextSundayAt(now);
      expect(result.isAfter(now), isTrue);
      expect(result, DateTime(2026, 8, 9, 19, 0));
    });

    test('ay sınırını doğru devirir', () {
      final now = DateTime(2026, 8, 31, 10, 0); // Pazartesi
      final result = ResurfacingDates.nextSundayAt(now);
      expect(result, DateTime(2026, 9, 6, 19, 0));
    });
  });
}
