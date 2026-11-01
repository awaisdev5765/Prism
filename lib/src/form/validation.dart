/// A single validation rule for a [PrismFormController] field.
///
/// Return an error message when invalid, or null when valid.
typedef PrismValidator = String? Function(String? value);

/// Commonly used [PrismValidator]s, composable via [Validators.all].
abstract final class Validators {
  /// Fails when the value is null or blank.
  static PrismValidator required([String message = 'This field is required']) =>
      (value) => value == null || value.trim().isEmpty ? message : null;

  /// Fails when the value is not a plausible email address.
  static PrismValidator email([
    String message = 'Enter a valid email address',
  ]) => (value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // let `required` handle emptiness
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(v) ? null : message;
  };

  /// Fails when the value is shorter than [min] characters.
  static PrismValidator minLength(int min, [String? message]) =>
      (value) => (value ?? '').length < min
      ? (message ?? 'Must be at least $min characters')
      : null;

  /// Fails when the value is longer than [max] characters.
  static PrismValidator maxLength(int max, [String? message]) =>
      (value) => (value ?? '').length > max
      ? (message ?? 'Must be at most $max characters')
      : null;

  /// Fails when the value does not match [pattern].
  static PrismValidator pattern(RegExp pattern, [String? message]) => (value) {
    final v = value ?? '';
    if (v.isEmpty) return null; // let `required` handle emptiness
    return pattern.hasMatch(v) ? null : (message ?? 'Invalid format');
  };

  /// Fails when the value is not a number.
  static PrismValidator number([String message = 'Enter a valid number']) =>
      (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return null;
        return double.tryParse(v) != null ? null : message;
      };

  /// Combines [validators]; the first failing message wins.
  static PrismValidator all(List<PrismValidator> validators) => (value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  };
}

/// Thrown from a submit handler to surface per-field errors after a
/// server-side rejection (e.g. "email already taken").
class PrismSubmissionException implements Exception {
  /// Creates a submission exception.
  const PrismSubmissionException({
    this.fieldErrors = const {},
    this.message = 'Submission failed',
  });

  /// Field name → error message, surfaced inline under each field.
  final Map<String, String> fieldErrors;

  /// Form-level message shown above the submit button.
  final String message;

  @override
  String toString() => 'PrismSubmissionException: $message';
}
