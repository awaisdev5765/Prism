import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A slider styled with Prism tokens and accessible to screen readers.
///
/// Wraps Flutter's `Slider` and adds a `Semantics` label, a value display and
/// a haptic response, so it is usable without sight and gives feedback you can
/// feel.
///
/// ```dart
/// PrismSlider(
///   value: volume,
///   min: 0,
///   max: 100,
///   label: 'Volume',
///   onChanged: (v) => setVolume(v),
/// )
/// ```
class PrismSlider extends StatelessWidget {
  /// Creates a slider.
  const PrismSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.label,
    this.showValue = false,
    this.color,
  });

  /// The current value. Must be between [min] and [max].
  final double value;

  /// Called when the value changes. Null makes the slider read-only.
  final ValueChanged<double>? onChanged;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Number of discrete divisions. Null makes it continuous.
  final int? divisions;

  /// Accessibility label. Defaults to no label.
  final String? label;

  /// Whether to show the current value as text.
  final bool showValue;

  /// Colour of the active track and thumb.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.prismTokens;

    return Semantics(
      label: label,
      slider: true,
      value: value.toStringAsFixed(divisions == null ? 1 : 0),
      child: Row(
        children: [
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
              activeColor: color ?? scheme.primary,
            ),
          ),
          if (showValue) ...[
            SizedBox(width: tokens.spaceSm),
            Text(
              value.toStringAsFixed(divisions == null ? 1 : 0),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color ?? scheme.primary,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A switch with a semantics label and a Prism colour scheme.
///
/// Wraps `SwitchListTile` with a title and subtitle, which is the shape most
/// settings screens need, and exposes the state as a toggle to assistive tech.
///
/// ```dart
/// PrismSwitch(
///   value: darkMode,
///   onChanged: (v) => setDarkMode(v),
///   title: 'Dark mode',
///   subtitle: 'Follow the system theme',
///   icon: Icons.dark_mode,
/// )
/// ```
class PrismSwitch extends StatelessWidget {
  /// Creates a switch.
  const PrismSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.icon,
    this.enabled = true,
  });

  /// Whether the switch is on.
  final bool value;

  /// Called with the new state. Null makes the switch read-only.
  final ValueChanged<bool>? onChanged;

  /// Primary label.
  final String title;

  /// Secondary description under the title.
  final String? subtitle;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether the switch can be toggled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.prismColors;
    final foreground = enabled ? scheme.onSurface : colors.outline;

    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: scheme.primary,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
      secondary: icon == null ? null : Icon(icon, color: foreground),
    );
  }
}

/// A checkbox with a title and semantics, in the same shape as [PrismSwitch].
class PrismCheckbox extends StatelessWidget {
  /// Creates a checkbox.
  const PrismCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.title,
    this.subtitle,
    this.enabled = true,
    this.tristate = false,
  });

  /// Whether the checkbox is ticked.
  final bool value;

  /// Called with the new state. Null makes it read-only.
  final ValueChanged<bool>? onChanged;

  /// Primary label.
  final String title;

  /// Secondary description.
  final String? subtitle;

  /// Whether the checkbox can be toggled.
  final bool enabled;

  /// Whether it cycles through checked, unchecked and null.
  final bool tristate;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = context.prismColors;
    final foreground = enabled ? scheme.onSurface : colors.outline;

    return CheckboxListTile(
      value: value,
      // CheckboxListTile takes a ValueChanged<bool?> because tristate allows
      // three states. Convert to a plain bool callback.
      onChanged: enabled ? (v) => onChanged!(v ?? false) : null,
      tristate: tristate,
      activeColor: scheme.primary,
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
    );
  }
}

/// A dropdown field with a label, an optional icon, and validation.
///
/// Wraps `DropdownButtonFormField` and adds a [Semantics] label, which the
/// default does not have.
///
/// ```dart
/// PrismDropdown<String>(
///   value: 'pro',
///   items: const [
///     PrismDropdownItem(value: 'free', label: 'Free'),
///     PrismDropdownItem(value: 'pro', label: 'Pro'),
///   ],
///   onChanged: (v) => setState(() => plan = v),
///   label: 'Plan',
///   icon: Icons.card_membership,
///   validator: (v) => v == null ? 'Pick a plan' : null,
/// )
/// ```
class PrismDropdown<T> extends StatelessWidget {
  /// Creates a dropdown field.
  const PrismDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.label,
    this.hint,
    this.icon,
    this.validator,
    this.enabled = true,
  });

  /// The currently selected value, or null.
  final T? value;

  /// The options.
  final List<PrismDropdownItem<T>> items;

  /// Called with the newly selected value. Null makes it read-only.
  final ValueChanged<T?>? onChanged;

  /// Label above the field.
  final String? label;

  /// Hint text inside the field.
  final String? hint;

  /// Optional leading icon.
  final IconData? icon;

  /// Validation function. Returns an error message, or null if valid.
  final String? Function(T?)? validator;

  /// Whether the field can be changed.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.prismTokens;
    final colors = context.prismColors;

    return Semantics(
      label: label,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: [
          for (final item in items)
            DropdownMenuItem<T>(
              value: item.value,
              enabled: item.enabled,
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon, size: 18, color: scheme.onSurfaceVariant),
                    SizedBox(width: tokens.spaceSm),
                  ],
                  Text(item.label),
                ],
              ),
            ),
        ],
        onChanged: enabled ? onChanged : null,
        hint: hint == null ? null : Text(hint!),
        validator: validator,
        disabledHint: enabled ? null : (hint == null ? null : Text(hint!)),
        icon: Icon(
          Icons.expand_more,
          color: enabled ? scheme.primary : colors.outline,
        ),
        decoration: InputDecoration(
          labelText: label,
          enabled: enabled,
          prefixIcon: icon == null ? null : Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
          ),
        ),
      ),
    );
  }
}

/// One option in a [PrismDropdown].
@immutable
class PrismDropdownItem<T> {
  /// Creates a dropdown item.
  const PrismDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
  });

  /// The value this option selects.
  final T value;

  /// The visible label.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether this option can be picked.
  final bool enabled;
}
