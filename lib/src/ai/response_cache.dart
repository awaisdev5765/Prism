import 'dart:convert';

import 'package:crypto/crypto.dart' as crypto;

/// Caches AI responses by prompt hash so repeated calls don't re-bill.
///
/// Keyed by SHA-256 of the prompt + model + temperature. Stores the raw
/// response string and an optional expiry.
///
/// ```dart
/// final cache = PrismResponseCache();
/// final key = cache.keyFor(prompt, model: 'gpt-4o-mini');
/// final cached = cache.get(key);
/// if (cached != null) return cached;
/// // …otherwise call the AI and store the response
/// cache.put(key, response);
/// ```
class PrismResponseCache {
  /// Creates a response cache.
  PrismResponseCache({this.maxEntries = 100});

  /// Maximum number of cached responses. Oldest entries are evicted first.
  final int maxEntries;

  final Map<String, _CacheEntry> _entries = {};

  /// Returns the cached response for [key], or null if expired or absent.
  String? get(String key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (entry.isExpired) {
      _entries.remove(key);
      return null;
    }
    // Move to end for LRU semantics.
    _entries.remove(key);
    _entries[key] = entry;
    return entry.response;
  }

  /// Stores [response] under [key].
  void put(String key, String response, {Duration? ttl}) {
    if (_entries.length >= maxEntries) {
      // Evict the oldest entry (first inserted, since Dart Maps are insertion
      // ordered).
      if (_entries.isNotEmpty) _entries.remove(_entries.keys.first);
    }
    _entries[key] = _CacheEntry(
      response,
      ttl == null ? null : DateTime.now().add(ttl),
    );
  }

  /// Computes a cache key from the prompt, model and temperature.
  static String keyFor(
    String prompt, {
    required String model,
    double? temperature,
  }) {
    return crypto.sha256
        .convert(utf8.encode('$model|${temperature ?? 0}|$prompt'))
        .toString();
  }

  /// Clears the cache.
  void clear() => _entries.clear();

  /// Number of cached entries.
  int get length => _entries.length;
}

class _CacheEntry {
  const _CacheEntry(this.response, this.expiresAt);

  final String response;
  final DateTime? expiresAt;

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
}
