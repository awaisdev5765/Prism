import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists which announcements (and versions) the user has dismissed.
///
/// Swap in your own implementation to use any storage backend — the widget
/// only needs this tiny interface.
abstract class BannerDismissStore {
  /// Returns the dismissed version for [announcementId], or null if the
  /// banner was never dismissed.
  Future<int?> dismissedVersion(String announcementId);

  /// Records that the user dismissed [announcementId] at [version].
  Future<void> dismiss(String announcementId, int version);
}

/// [SharedPreferences]-backed store used by default.
class SharedPrefsDismissStore implements BannerDismissStore {
  /// Creates a store persisting under [storageKey].
  const SharedPrefsDismissStore({this.storageKey = 'prism_banner.dismissed'});

  /// SharedPreferences key holding the JSON dismiss map.
  final String storageKey;

  @override
  Future<int?> dismissedVersion(String announcementId) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _decode(prefs.getString(storageKey));
    return map[announcementId];
  }

  @override
  Future<void> dismiss(String announcementId, int version) async {
    final prefs = await SharedPreferences.getInstance();
    final map = _decode(prefs.getString(storageKey));
    map[announcementId] = version;
    await prefs.setString(storageKey, jsonEncode(map));
  }

  Map<String, int> _decode(String? raw) {
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return {
          for (final e in decoded.entries)
            if (e.value is int) e.key: e.value as int,
        };
      }
    } on FormatException {
      // Corrupt payload — start fresh.
    }
    return {};
  }
}

/// In-memory store for tests and previews.
class InMemoryDismissStore implements BannerDismissStore {
  /// Creates an empty store.
  InMemoryDismissStore();

  final Map<String, int> _data = {};

  @override
  Future<int?> dismissedVersion(String announcementId) async =>
      _data[announcementId];

  @override
  Future<void> dismiss(String announcementId, int version) async =>
      _data[announcementId] = version;
}
