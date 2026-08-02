import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:somine_app/core/utils/exponential_backoff.dart';

void main() {
  group('ExponentialBackoff', () {
    ExponentialBackoff withoutJitter({
      Duration baseDelay = const Duration(seconds: 5),
      Duration maxDelay = const Duration(minutes: 2),
    }) {
      return ExponentialBackoff(
        baseDelay: baseDelay,
        jitterFactor: 0,
        maxDelay: maxDelay,
      );
    }

    test('delays grow exponentially with the multiplier', () {
      final backoff = withoutJitter();

      expect(backoff.nextDelay(), const Duration(seconds: 5));
      expect(backoff.nextDelay(), const Duration(seconds: 10));
      expect(backoff.nextDelay(), const Duration(seconds: 20));
      expect(backoff.nextDelay(), const Duration(seconds: 40));
      expect(backoff.attempt, 4);
    });

    test('delay is capped at maxDelay', () {
      final backoff = withoutJitter();

      Duration last = Duration.zero;
      for (var i = 0; i < 12; i++) {
        last = backoff.nextDelay();
      }

      expect(last, const Duration(minutes: 2));
    });

    test('jitter stays within the configured band and below maxDelay', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 5),
        jitterFactor: 0.2,
        maxDelay: const Duration(minutes: 2),
        random: Random(42),
      );

      for (var i = 0; i < 200; i++) {
        final delay = backoff.nextDelay().inMilliseconds;
        expect(delay, greaterThanOrEqualTo((5000 * 0.8).round()));
        expect(delay, lessThanOrEqualTo((5000 * 1.2).round()));
        backoff.reset();
      }
    });

    test('jitter produces varying delays', () {
      final backoff = ExponentialBackoff(random: Random(7));

      final samples = <int>{};
      for (var i = 0; i < 20; i++) {
        samples.add(backoff.nextDelay().inMilliseconds);
        backoff.reset();
      }

      expect(samples.length, greaterThan(1));
    });

    test('reset restarts the sequence from the base delay', () {
      final backoff = withoutJitter();

      backoff.nextDelay();
      backoff.nextDelay();
      backoff.nextDelay();
      expect(backoff.attempt, 3);

      backoff.reset();

      expect(backoff.attempt, 0);
      expect(backoff.nextDelay(), const Duration(seconds: 5));
    });

    test('custom parameters are honored', () {
      final backoff = ExponentialBackoff(
        baseDelay: const Duration(seconds: 10),
        multiplier: 3,
        jitterFactor: 0,
        maxDelay: const Duration(seconds: 45),
      );

      expect(backoff.nextDelay(), const Duration(seconds: 10));
      expect(backoff.nextDelay(), const Duration(seconds: 30));
      expect(backoff.nextDelay(), const Duration(seconds: 45));
    });
  });
}
