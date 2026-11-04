import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A determinate or indeterminate linear progress bar with Prism tokens.
///
/// Wraps `LinearProgressIndicator` and adds an accessible label and a value
/// display, which the default does not expose.
///
/// ```dart
/// PrismLinearProgress(
///   value: 0.35,
///   label: 'Uploading',
/// )
/// ```
class PrismLinearProgress extends StatelessWidget {
  /// Creates a linear progress bar.
  const PrismLinearProgress({
    super.key,
    this.value,
    this.label,
    this.showValue = false,
    this.color,
    this.backgroundColor,
    this.height = 8,
    this.borderRadius,
  });

  /// Progress in 0..1, or null for an indeterminate bar.
  final double? value;

  /// Accessibility label. Required when the value is set, so the user knows
  /// what is progressing.
  final String? label;

  /// Whether to display the percentage as text.
  final bool showValue;

  /// Bar colour. Defaults to the theme's primary.
  final Color? color;

  /// Track colour. Defaults to the surface container highest.
  final Color? backgroundColor;

  /// Bar height. Defaults to 8.
  final double height;

  /// Corner radius of the bar. Defaults to half the height, giving a pill.
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.prismTokens;
    final resolvedRadius = borderRadius ?? height / 2;

    final bar = ClipRRect(
      borderRadius: BorderRadius.circular(resolvedRadius),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value,
          color: color ?? scheme.primary,
          backgroundColor: backgroundColor ?? scheme.surfaceContainerHighest,
          minHeight: height,
        ),
      ),
    );

    final indicator = Semantics(
      label: label,
      liveRegion: true,
      value: value != null ? '${(value! * 100).round()}%' : null,
      child: bar,
    );

    if (!showValue || value == null) return indicator;

    return Row(
      children: [
        Expanded(child: indicator),
        SizedBox(width: tokens.spaceSm),
        Text(
          '${(value! * 100).round()}%',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color ?? scheme.primary,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// A circular progress indicator with a value in the middle.
///
/// Wraps `CircularProgressIndicator` and renders a percentage, which the
/// default does not do.
///
/// ```dart
/// PrismCircularProgress(value: 0.75, label: 'Downloading')
/// ```
class PrismCircularProgress extends StatelessWidget {
  /// Creates a circular progress indicator.
  const PrismCircularProgress({
    super.key,
    required this.value,
    this.size = 64,
    this.strokeWidth = 4,
    this.label,
    this.color,
  });

  /// Progress in 0..1.
  final double value;

  /// Diameter of the circle.
  final double size;

  /// Stroke width.
  final double strokeWidth;

  /// Accessibility label.
  final String? label;

  /// Bar colour. Defaults to the theme's primary.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      label: label,
      value: '${(value * 100).round()}%',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: value.clamp(0.0, 1.0),
                strokeWidth: strokeWidth,
                color: color ?? scheme.primary,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              textScaler: TextScaler.noScaling,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
