import 'package:flutter/foundation.dart';

/// Change-notifying value store for settings tiles.
///
/// One controller backs a whole settings page: tiles read their value by
/// [key] and write through [set]. Pass [onChanged] to persist (e.g. to
/// `shared_preferences`).
///
/// ```dart
/// final controller = PrismSettingsController(
///   initialValues: {'darkMode': true, 'volume': 0.8},
///   onChanged: (key, value) => prefs.set(key, value),
/// );
/// ```
class PrismSettingsController extends ChangeNotifier {
  /// Creates a controller with optional [initialValues].
  PrismSettingsController({
    Map<String, Object?> initialValues = const {},
    this.onChanged,
  }) {
    _values.addAll(initialValues);
  }

  /// Invoked after every user-driven change.
  final void Function(String key, Object? value)? onChanged;

  final Map<String, Object?> _values = {};

  /// Current values (unmodifiable view).
  Map<String, Object?> get values => Map.unmodifiable(_values);

  /// Reads the value for [key], or [fallback] when unset.
  T get<T>(String key, T fallback) {
    final value = _values[key];
    return value is T ? value : fallback;
  }

  /// Writes [value] for [key] and notifies listeners.
  void set(String key, Object? value) {
    if (identical(_values[key], value) || _values[key] == value) {
      return;
    }
    _values[key] = value;
    onChanged?.call(key, value);
    notifyListeners();
  }

  /// Removes [key] and notifies.
  void remove(String key) {
    if (_values.remove(key) != null) notifyListeners();
  }

  /// Bulk-writes [values] and notifies once (e.g. restoring a backup).
  void setAll(Map<String, Object?> values) {
    _values.addAll(values);
    notifyListeners();
  }
}
