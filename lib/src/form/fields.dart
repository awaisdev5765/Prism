import 'package:flutter/material.dart';

import 'controller.dart';
import 'validation.dart';

/// Provides the active [PrismFormController] to field widgets via an
/// [InheritedNotifier]; dependents rebuild on every controller change.
class PrismFormScope extends InheritedNotifier<PrismFormController> {
  /// Creates a scope exposing [notifier].
  const PrismFormScope({
    super.key,
    required PrismFormController super.notifier,
    required super.child,
  });

  /// The nearest controller; asserts when no [PrismForm] is above.
  static PrismFormController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PrismFormScope>();
    assert(scope != null, 'PrismForm fields must be inside a PrismForm.');
    return scope!.notifier!;
  }
}

/// Declarative form container.
///
/// Owns a [PrismFormController] (or adopts [controller]) and exposes it to
/// child field widgets. Wrap submit buttons with an [ListenableBuilder] on
/// the controller to react to the sealed [PrismFormStatus].
///
/// ```dart
/// final controller = PrismFormController();
///
/// PrismForm(
///   controller: controller,
///   child: Column(
///     children: [
///       PrismTextField(name: 'email', label: 'Email', validators: [Validators.required(), Validators.email()]),
///       PrismPasswordField(name: 'password'),
///       // submit button…
///     ],
///   ),
/// )
/// ```
class PrismForm extends StatefulWidget {
  /// Creates a form.
  const PrismForm({super.key, this.controller, required this.child});

  /// Optional externally-owned controller. When null, the form creates and
  /// disposes its own.
  final PrismFormController? controller;

  /// The form fields and any other content.
  final Widget child;

  @override
  State<PrismForm> createState() => _PrismFormState();
}

class _PrismFormState extends State<PrismForm> {
  PrismFormController? _internal;

  PrismFormController get _effective =>
      widget.controller ?? (_internal ??= PrismFormController());

  @override
  void dispose() {
    _internal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PrismFormScope(notifier: _effective, child: widget.child);
  }
}

/// Base configuration shared by all fields.
@immutable
class PrismFieldCommon {
  /// Creates shared field configuration.
  const PrismFieldCommon({
    required this.name,
    this.label,
    this.hint,
    this.validators = const [],
    this.enabled = true,
  });

  /// Value key inside the controller's [PrismFormController.values].
  final String name;

  /// Label rendered above the field.
  final String? label;

  /// Hint text inside the field.
  final String? hint;

  /// Validation rules; first failing message wins.
  final List<PrismValidator> validators;

  /// Whether the field accepts input.
  final bool enabled;
}

/// Single-line text field with type presets.
///
/// ```dart
/// PrismTextField(
///   name: 'email',
///   label: 'Email',
///   validators: [Validators.required(), Validators.email()],
/// )
/// ```
class PrismTextField extends StatefulWidget {
  /// Creates a text field.
  const PrismTextField({
    super.key,
    required this.common,
    this.keyboardType = TextInputType.text,
    this.obscure = false,
    this.maxLines = 1,
    this.textInputAction,
    this.suffix,
  });

  /// Convenience email field.
  factory PrismTextField.email({required String name, String? label}) =>
      PrismTextField(
        common: PrismFieldCommon(
          name: name,
          label: label,
          validators: [Validators.email()],
        ),
        keyboardType: TextInputType.emailAddress,
      );

  /// Shared configuration.
  final PrismFieldCommon common;

  /// Keyboard type.
  final TextInputType keyboardType;

  /// Whether to obscure the text (passwords).
  final bool obscure;

  /// Multiline height for multiline fields.
  final int maxLines;

  /// Keyboard action button.
  final TextInputAction? textInputAction;

  /// Optional trailing widget.
  final Widget? suffix;

  @override
  State<PrismTextField> createState() => _PrismTextFieldState();
}

class _PrismTextFieldState extends State<PrismTextField> {
  late final TextEditingController _text = TextEditingController();
  final _focusNode = FocusNode();
  bool _touchedHooked = false;

  @override
  void dispose() {
    _focusNode.dispose();
    _text.dispose();
    super.dispose();
  }

  void _hookTouch(PrismFormController controller, String name) {
    if (_touchedHooked) return;
    _touchedHooked = true;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) controller.setTouched(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = PrismFormScope.of(context);
    final common = widget.common;
    return _FieldShell(
      common: common,
      controller: controller,
      builder: (context, errorText) {
        _hookTouch(controller, common.name);
        return TextField(
          controller: _text,
          focusNode: _focusNode,
          keyboardType: widget.keyboardType,
          obscureText: widget.obscure,
          maxLines: widget.maxLines,
          enabled: common.enabled,
          textInputAction: widget.textInputAction,
          decoration: InputDecoration(
            labelText: common.label,
            hintText: common.hint,
            errorText: errorText,
            suffixIcon: widget.suffix,
            border: const OutlineInputBorder(),
          ),
          onChanged: (value) => controller.setValue(common.name, value),
        );
      },
    );
  }
}

/// Password field with visibility toggle.
class PrismPasswordField extends StatefulWidget {
  /// Creates a password field.
  const PrismPasswordField({
    super.key,
    required this.common,
    this.minLength = 8,
  });

  /// Shared configuration.
  final PrismFieldCommon common;

  /// Minimum accepted length.
  final int minLength;

  @override
  State<PrismPasswordField> createState() => _PrismPasswordFieldState();
}

class _PrismPasswordFieldState extends State<PrismPasswordField> {
  bool _visible = false;
  final _focusNode = FocusNode();
  bool _touchedHooked = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _hookTouch(PrismFormController controller, String name) {
    if (_touchedHooked) return;
    _touchedHooked = true;
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) controller.setTouched(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = PrismFormScope.of(context);
    final common = widget.common;
    return _FieldShell(
      common: common,
      controller: controller,
      builder: (context, errorText) {
        _hookTouch(controller, common.name);
        return TextField(
          focusNode: _focusNode,
          obscureText: !_visible,
          enabled: common.enabled,
          decoration: InputDecoration(
            labelText: common.label,
            hintText: common.hint,
            errorText: errorText,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _visible = !_visible),
            ),
          ),
          onChanged: (value) => controller.setValue(common.name, value),
        );
      },
    );
  }
}

/// Dropdown selection field.
class PrismDropdownField<T> extends StatelessWidget {
  /// Creates a dropdown field.
  const PrismDropdownField({
    super.key,
    required this.common,
    required this.items,
    required this.itemLabel,
  });

  /// Shared configuration.
  final PrismFieldCommon common;

  /// Selectable options.
  final List<T> items;

  /// Renders the display label for an option.
  final String Function(T item) itemLabel;

  @override
  Widget build(BuildContext context) {
    final controller = PrismFormScope.of(context);
    return _FieldShell(
      common: common,
      controller: controller,
      builder: (context, errorText) {
        final current = controller.values[common.name] as T?;
        return DropdownButtonFormField<T>(
          initialValue: current,
          decoration: InputDecoration(
            labelText: common.label,
            hintText: common.hint,
            errorText: errorText,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final item in items)
              DropdownMenuItem<T>(value: item, child: Text(itemLabel(item))),
          ],
          onChanged: common.enabled
              ? (value) => controller.setValue(common.name, value)
              : null,
        );
      },
    );
  }
}

/// Boolean checkbox field.
class PrismCheckboxField extends StatelessWidget {
  /// Creates a checkbox field.
  const PrismCheckboxField({super.key, required this.common, this.title});

  /// Shared configuration.
  final PrismFieldCommon common;

  /// Trailing label.
  final String? title;

  @override
  Widget build(BuildContext context) {
    final controller = PrismFormScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final value = (controller.values[common.name] as bool?) ?? false;
        final errorText = controller.errorOf(common.name);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              value: value,
              title: title != null ? Text(title!) : null,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              enabled: common.enabled,
              onChanged: (v) {
                controller.setTouched(common.name);
                controller.setValue(common.name, v ?? false);
              },
            ),
            if (errorText != null)
              Text(
                errorText,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Shared shell: registers validators, rebuilds on controller changes, and
/// provides the current inline error to the field builder.
class _FieldShell extends StatelessWidget {
  const _FieldShell({
    required this.common,
    required this.controller,
    required this.builder,
  });

  final PrismFieldCommon common;
  final PrismFormController controller;
  final Widget Function(BuildContext context, String? errorText) builder;

  @override
  Widget build(BuildContext context) {
    // (Re)register on every build so validator lists can change.
    controller.registerValidator(
      common.name,
      Validators.all(common.validators),
    );
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) =>
          builder(context, controller.errorOf(common.name)),
    );
  }
}
