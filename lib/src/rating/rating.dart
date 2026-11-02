import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// A star rating that is operable without sight and without a mouse.
///
/// Tapping the middle of a star picks the half value, so a 5-star control gives
/// ten possible scores without a fiddly drag. Each star is an individual
/// button-in-a-row with an explicit label, and the whole control is a slider to
/// a screen reader, so the score can be read and changed with a swipe.
///
/// ```dart
/// PrismRating(
///   value: rating,
///   onChanged: (next) => setState(() => rating = next),
///   label: 'How was the delivery?',
/// )
/// ```
class PrismRating extends StatelessWidget {
  /// Creates a rating control.
  const PrismRating({
    super.key,
    required this.value,
    this.onChanged,
    this.max = 5,
    this.allowHalf = false,
    this.size,
    this.color,
    this.label,
    this.readOnlyLabel,
    this.showValue = false,
    this.semantic = PrismSemantic.warning,
  });

  /// The current score. Clamped to `0..max`.
  final double value;

  /// Called with the new score. When null the control is read-only.
  final ValueChanged<double>? onChanged;

  /// Number of stars.
  final int max;

  /// Whether half-star precision is selectable by tapping the left half.
  final bool allowHalf;

  /// Star size. Defaults to `PrismTokens.spaceLg`.
  final double? size;

  /// Star colour. Defaults to the [semantic] accent.
  final Color? color;

  /// Accessible name for the control, e.g. "How was the delivery?".
  final String? label;

  /// Accessible label for a read-only rating. Defaults to
  /// `"Rated <value> out of <max>"`.
  final String? readOnlyLabel;

  /// Whether to show the numeric score beside the stars.
  final bool showValue;

  /// Which semantic role colours the filled stars.
  final PrismSemantic semantic;

  /// Whether the control can be changed.
  bool get isReadOnly => onChanged == null;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final starSize = size ?? tokens.spaceLg;
    final starColor = color ?? colors.accentForRole(semantic);
    final clamped = value.clamp(0.0, max.toDouble());
    final scheme = Theme.of(context).colorScheme;

    Widget starAt(int index) {
      // The fill of this star: 1 for full, 0.5 for half, 0 for empty.
      final filled = (clamped - index).clamp(0.0, 1.0);
      return SizedBox(
        width: starSize + tokens.spaceXs,
        height: starSize + tokens.spaceXs,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.star_border_rounded,
              size: starSize,
              color: colors.outline,
            ),
            if (filled > 0)
              ClipRect(
                clipper: _HalfClipper(fraction: filled),
                child: Icon(
                  Icons.star_rounded,
                  size: starSize,
                  color: starColor,
                ),
              ),
          ],
        ),
      );
    }

    // A read-only rating is a single piece of text, not a row of buttons.
    if (isReadOnly) {
      return Semantics(
        label: readOnlyLabel ?? 'Rated $clamped out of $max',
        readOnly: true,
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < max; i++) starAt(i),
              if (showValue) ...[
                SizedBox(width: tokens.spaceSm),
                Text(
                  clamped.toStringAsFixed(allowHalf ? 1 : 0),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Semantics(
      slider: true,
      label: label ?? 'Rating',
      value: _valueLabel(clamped),
      increasedValue: _valueLabel(
        (clamped + (allowHalf ? 0.5 : 1)).clamp(0, max).toDouble(),
      ),
      decreasedValue: _valueLabel(
        (clamped - (allowHalf ? 0.5 : 1)).clamp(0, max).toDouble(),
      ),
      onIncrease: _increment,
      onDecrease: _decrement,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < max; i++)
              _Star(
                index: i,
                allowHalf: allowHalf,
                onSelect: onChanged!,
                child: starAt(i),
              ),
            if (showValue) ...[
              SizedBox(width: tokens.spaceSm),
              Text(
                clamped.toStringAsFixed(allowHalf ? 1 : 0),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// A spoken description of a score, e.g. "3.5 out of 5".
  String _valueLabel(double score) =>
      '${score.toStringAsFixed(allowHalf ? 1 : 0)} out of $max';

  /// Increases the score by one step, for the accessibility action.
  void _increment() {
    final step = allowHalf ? 0.5 : 1.0;
    onChanged?.call((value + step).clamp(0, max.toDouble()));
  }

  /// Decreases the score by one step, for the accessibility action.
  void _decrement() {
    final step = allowHalf ? 0.5 : 1.0;
    onChanged?.call((value - step).clamp(0, max.toDouble()));
  }
}

class _Star extends StatelessWidget {
  const _Star({
    required this.index,
    required this.allowHalf,
    required this.child,
    required this.onSelect,
  });

  final int index;
  final bool allowHalf;
  final Widget child;
  final ValueChanged<double> onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) {
        // Left half picks a half value; right half picks the whole star. Only
        // meaningful with allowHalf, but harmless otherwise.
        final isLeftHalf =
            details.localPosition.dx <
            (context.findRenderObject()! as RenderBox).size.width / 2;
        final value = allowHalf
            ? (isLeftHalf ? index + 0.5 : index + 1.0)
            : index + 1.0;
        HapticFeedback.selectionClick();
        onSelect(value);
      },
      child: child,
    );
  }
}

/// Clips a star to a fraction of its width, for half-star display.
class _HalfClipper extends CustomClipper<Rect> {
  const _HalfClipper({required this.fraction});

  final double fraction;

  @override
  Rect getClip(Size size) =>
      Rect.fromLTWH(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_HalfClipper oldClipper) => oldClipper.fraction != fraction;
}
