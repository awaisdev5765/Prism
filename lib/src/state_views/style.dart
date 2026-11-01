import 'package:flutter/material.dart';

/// Visual configuration for [PrismStateView].
@immutable
class PrismStateViewStyle {
  /// Creates a style.
  const PrismStateViewStyle({
    this.messageStyle,
    this.errorColor,
    this.iconColor,
    this.accentColor,
    this.transitionDuration = const Duration(milliseconds: 250),
  });

  /// Text style for status messages. Defaults to `titleMedium`.
  final TextStyle? messageStyle;

  /// Color of the error icon. Defaults to the theme's `error` color.
  final Color? errorColor;

  /// Color of the empty-state icon. Defaults to the theme's outline color.
  final Color? iconColor;

  /// Color of the loading indicator. Defaults to the theme's primary color.
  final Color? accentColor;

  /// Duration of the cross-fade between states.
  final Duration transitionDuration;

  /// Returns a copy with unset fields resolved against [context].
  PrismStateViewStyle resolve(BuildContext context) {
    final theme = Theme.of(context);
    return PrismStateViewStyle(
      messageStyle: messageStyle ?? theme.textTheme.titleMedium,
      errorColor: errorColor ?? theme.colorScheme.error,
      iconColor: iconColor ?? theme.colorScheme.outline,
      accentColor: accentColor ?? theme.colorScheme.primary,
      transitionDuration: transitionDuration,
    );
  }
}
