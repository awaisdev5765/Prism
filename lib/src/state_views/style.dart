import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Visual configuration for [PrismStateView].
///
/// Every field is optional. Unset fields resolve against the ambient theme and
/// [PrismTokens], so a `PrismStateView` picks up your spacing scale, corner
/// radii, motion language and semantic colours without any configuration.
@immutable
class PrismStateViewStyle {
  /// Creates a style.
  const PrismStateViewStyle({
    this.messageStyle,
    this.errorColor,
    this.iconColor,
    this.accentColor,
    this.transitionDuration,
    this.iconSize,
    this.padding,
    this.gap,
    this.retryLabel,
  });

  /// Text style for status messages. Defaults to `titleMedium`.
  final TextStyle? messageStyle;

  /// Color of the error icon. Defaults to [PrismColors.error].
  final Color? errorColor;

  /// Color of the empty-state icon. Defaults to the theme's outline colour.
  final Color? iconColor;

  /// Color of the loading indicator. Defaults to the theme's primary colour.
  final Color? accentColor;

  /// Duration of the cross-fade between states. Defaults to
  /// [PrismTokens.durationMedium].
  final Duration? transitionDuration;

  /// Size of the status icon. Defaults to `PrismTokens.spaceXxl`.
  final double? iconSize;

  /// Padding around the state. Defaults to `PrismTokens.spaceLg`.
  final EdgeInsetsGeometry? padding;

  /// Gap between the icon, message and action. Defaults to
  /// `PrismTokens.spaceSm`.
  final double? gap;

  /// Label for the retry button. Defaults to `Retry`.
  final String? retryLabel;

  /// Returns a copy with unset fields resolved against [context].
  PrismStateViewStyle resolve(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = PrismTokens.of(context);
    final colors = PrismColors.of(context);
    return PrismStateViewStyle(
      messageStyle: messageStyle ?? theme.textTheme.titleMedium,
      errorColor: errorColor ?? colors.error,
      iconColor: iconColor ?? theme.colorScheme.outline,
      accentColor: accentColor ?? theme.colorScheme.primary,
      transitionDuration: transitionDuration ?? tokens.durationMedium,
      iconSize: iconSize ?? tokens.spaceXxl,
      padding: padding ?? EdgeInsets.all(tokens.spaceLg),
      gap: gap ?? tokens.spaceSm,
      retryLabel: retryLabel ?? 'Retry',
    );
  }
}
