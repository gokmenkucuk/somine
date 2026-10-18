import 'dart:math';

/// General-purpose exponential backoff with jitter.
///
/// Each [nextDelay] call returns the current delay and advances the attempt
/// counter: base * multiplier^attempt, capped at [maxDelay], with a random
/// jitter of ±[jitterFactor] applied. The final delay never exceeds
/// [maxDelay]. Call [reset] after a successful operation.
class ExponentialBackoff {
  ExponentialBackoff({
    this.baseDelay = const Duration(seconds: 5),
    this.multiplier = 2.0,
    this.jitterFactor = 0.2,
    this.maxDelay = const Duration(minutes: 2),
    Random? random,
  })  : assert(multiplier >= 1),
        assert(jitterFactor >= 0 && jitterFactor < 1),
        _random = random ?? Random();

  final Duration baseDelay;
  final double multiplier;
  final double jitterFactor;
  final Duration maxDelay;
  final Random _random;

  int _attempt = 0;

  /// Number of [nextDelay] calls since the last [reset].
  int get attempt => _attempt;

  Duration nextDelay() {
    final rawMs = baseDelay.inMilliseconds * pow(multiplier, _attempt);
    final cappedMs = min(rawMs.toDouble(), maxDelay.inMilliseconds.toDouble());
    _attempt++;

    final jitter = 1 + (_random.nextDouble() * 2 - 1) * jitterFactor;
    final jitteredMs = min(cappedMs * jitter, maxDelay.inMilliseconds.toDouble());
    return Duration(milliseconds: jitteredMs.round());
  }

  void reset() {
    _attempt = 0;
  }
}
