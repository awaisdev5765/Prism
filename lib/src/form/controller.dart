import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'validation.dart';

/// Sealed lifecycle of a form submission.
///
/// Dart 3 exhaustive switching means every consumer must handle all states:
///
/// ```dart
/// final text = switch (controller.status) {
///   PrismFormStatus.pristine => 'Fill me in',
///   PrismFormStatus.editing => 'Editing…',
///   PrismFormStatus.submitting => 'Sending…',
///   PrismFormStatus.success => 'Done!',
///   PrismFormStatus.failure(:final message) => message,
/// };
/// ```
sealed class PrismFormStatus {
  const PrismFormStatus();

  /// True while a submission request is in flight.
  bool get isSubmitting => this is PrismFormSubmitting;
}

/// The form has not been edited yet.
class PrismFormPristine extends PrismFormStatus {
  /// Creates the pristine status.
  const PrismFormPristine();
}

/// The user has edited at least one field.
class PrismFormEditing extends PrismFormStatus {
  /// Creates the editing status.
  const PrismFormEditing();
}

/// A submission is in flight.
class PrismFormSubmitting extends PrismFormStatus {
  /// Creates the submitting status.
  const PrismFormSubmitting();
}

/// The last submission succeeded.
class PrismFormSuccess extends PrismFormStatus {
  /// Creates the success status.
  const PrismFormSuccess();
}

/// The last submission failed.
class PrismFormFailure extends PrismFormStatus {
  /// Creates a failure status.
  const PrismFormFailure({this.message = 'Submission failed'});

  /// Human-readable failure reason.
  final String message;
}

/// Headless form state manager.
///
/// Holds values, validation errors, and touched fields for a form; drives
/// submission lifecycle via the sealed [PrismFormStatus]. Usable inside
/// [PrismForm] (widget-managed) or standalone for custom UIs.
///
/// ```dart
/// final controller = PrismFormController();
///
/// // From any listener (e.g. ValueListenableBuilder):
/// controller.setValue('email', 'a@b.co');
/// controller.setTouched('email');
///
/// if (await controller.submit(
///   (values) => api.register(values),
/// )) {
///   // success
/// }
/// ```
class PrismFormController extends ChangeNotifier {
  /// Creates a controller with optional [initialValues].
  PrismFormController({Map<String, Object?> initialValues = const {}}) {
    _values.addAll(initialValues);
  }

  final Map<String, Object?> _values = {};
  final Map<String, String> _errors = {};
  final Set<String> _touched = {};
  final Map<String, PrismValidator> _validators = {};

  PrismFormStatus _status = const PrismFormPristine();
  bool _submitAttempted = false;

  /// Current submission lifecycle.
  PrismFormStatus get status => _status;

  /// Whether the user has attempted a submit (error display gate).
  bool get submitAttempted => _submitAttempted;

  /// Current field values (unmodifiable view).
  Map<String, Object?> get values => Map.unmodifiable(_values);

  /// Current validation errors (unmodifiable view).
  Map<String, String> get errors => Map.unmodifiable(_errors);

  /// Fields the user has interacted with.
  Set<String> get touched => Set.unmodifiable(_touched);

  /// Registers the validator for [name]. Called by field widgets.
  void registerValidator(String name, PrismValidator validator) {
    _validators[name] = validator;
  }

  /// Removes the validator for [name] (field unmounted).
  void unregisterValidator(String name) {
    _validators.remove(name);
    _errors.remove(name);
    _touched.remove(name);
  }

  /// Sets [value] for [name], marks the form as edited, and revalidates the
  /// field once the user has touched it or attempted a submit.
  void setValue(String name, Object? value) {
    _values[name] = value;
    if (_status is! PrismFormSubmitting) {
      _status = const PrismFormEditing();
    }
    if (_touched.contains(name) || _submitAttempted) {
      _validateField(name);
    }
    notifyListeners();
  }

  /// Marks [name] as touched (typically on focus/blur) and validates it.
  void setTouched(String name) {
    _touched.add(name);
    _validateField(name);
    notifyListeners();
  }

  /// Whether an error should currently be displayed for [name].
  bool showError(String name) =>
      _errors.containsKey(name) &&
      (_touched.contains(name) || _submitAttempted);

  /// The current error message for [name], if any.
  String? errorOf(String name) => showError(name) ? _errors[name] : null;

  void _validateField(String name) {
    final validator = _validators[name];
    if (validator == null) return;
    final error = validator(_values[name] as String?);
    if (error == null) {
      _errors.remove(name);
    } else {
      _errors[name] = error;
    }
  }

  /// Validates every registered field. Returns true when all pass.
  bool validate() {
    for (final name in _validators.keys) {
      _validateField(name);
    }
    notifyListeners();
    return _errors.isEmpty;
  }

  /// Validates and, when clean, runs [onSubmit] with the current values.
  ///
  /// Returns true on success. While [onSubmit] runs, [status] is
  /// [PrismFormSubmitting]; a thrown [PrismSubmissionException] maps its
  /// [PrismSubmissionException.fieldErrors] inline and sets a
  /// [PrismFormFailure] with its message; any other error sets a generic
  /// [PrismFormFailure].
  Future<bool> submit(
    Future<void> Function(Map<String, Object?> values) onSubmit,
  ) async {
    if (_status.isSubmitting) return false;
    _submitAttempted = true;
    if (!validate()) {
      _status = const PrismFormEditing();
      notifyListeners();
      return false;
    }
    _status = const PrismFormSubmitting();
    notifyListeners();
    try {
      await onSubmit(values);
      _status = const PrismFormSuccess();
      notifyListeners();
      return true;
    } on PrismSubmissionException catch (e) {
      _errors.addAll(e.fieldErrors);
      _status = PrismFormFailure(message: e.message);
      notifyListeners();
      return false;
    } catch (_) {
      _status = const PrismFormFailure();
      notifyListeners();
      return false;
    }
  }

  /// Clears values, errors, touched state, and returns to pristine.
  void reset() {
    _values.clear();
    _errors.clear();
    _touched.clear();
    _submitAttempted = false;
    _status = const PrismFormPristine();
    notifyListeners();
  }

  @override
  void dispose() {
    _validators.clear();
    super.dispose();
  }
}
