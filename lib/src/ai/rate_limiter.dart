import 'dart:async';

/// A token-bucket rate limiter for AI API calls.
class PrismRateLimiter {
  PrismRateLimiter({required this.maxPerSecond, this.burst = 1});

  final int maxPerSecond;
  final int burst;
  final List<DateTime> _timestamps = [];

  Future<void> acquire() async {
    while (true) {
      final now = DateTime.now();
      _timestamps.removeWhere(
        (t) => now.difference(t).inMilliseconds >= 1000,
      );
      if (_timestamps.length < maxPerSecond + burst - 1) break;
      final oldest = _timestamps.first;
      final waitMs = 1000 - now.difference(oldest).inMilliseconds;
      if (waitMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: waitMs));
      }
    }
    _timestamps.add(DateTime.now());
  }
}
