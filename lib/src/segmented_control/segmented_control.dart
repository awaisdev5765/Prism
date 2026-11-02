import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// One option in a [PrismSegmentedControl].
@immutable
class PrismSegment<T> {
  /// Creates a segment.
  const PrismSegment({
    required this.value,
    required this.label,
    this.icon,
    this.enabled = true,
    this.tooltip,
  });

  /// The value this segment selects.
  final T value;

  /// Visible label.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether the segment can be picked.
  final bool enabled;

  /// Tooltip text; also used as the accessibility hint when the label is short.
  final String? tooltip;
}

/// A single-choice segmented control that stays usable on a phone.
///
/// Flutter's `SegmentedButton` is excellent until the labels do not fit, at
/// which point it overflows. This adapts instead: on a narrow window it becomes
/// a scrollable row so every option stays reachable, and it always exposes the
/// selection as a radio group to assistive tech.
///
/// ```dart
/// PrismSegmentedControl<ExerciseMode>(
///   value: mode,
///   onChanged: (next) => setState(() => mode = next),
///   segments: const [
///     PrismSegment(value: ExerciseMode.office, label: 'Office'),
///     PrismSegment(value: ExerciseMode.home, label: 'Home', icon: Icons.home),
///   ],
/// )
/// ```
class PrismSegmentedControl<T> extends StatelessWidget {
  /// Creates a segmented control.
  const PrismSegmentedControl({
    super.key,
    required this.value,
    required this.segments,
    required this.onChanged,
    this.scrollThreshold,
    this.semanticLabel,
    this.showCheckmark = true,
  });

  /// The currently selected value.
  final T value;

  /// The available options. Must not be empty.
  final List<PrismSegment<T>> segments;

  /// Called with the newly selected value. Null makes the control read-only.
  final ValueChanged<T>? onChanged;

  /// Width below which the control scrolls instead of compressing. Defaults to
  /// `PrismTokens.breakpointCompact`.
  final double? scrollThreshold;

  /// Accessible name for the group.
  final String? semanticLabel;

  /// Whether the selected segment shows a checkmark.
  final bool showCheckmark;

  @override
  Widget build(BuildContext context) {
    assert(
      segments.isNotEmpty,
      'A segmented control needs at least one segment',
    );
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;
    final threshold = scrollThreshold ?? tokens.breakpointCompact;
    final width = MediaQuery.sizeOf(context).width;
    final scrolls = width < threshold;

    final row = Row(
      mainAxisSize: scrolls ? MainAxisSize.min : MainAxisSize.max,
      children: [
        for (final segment in segments)
          if (scrolls)
            _Segment<T>(
              segment: segment,
              selected: segment.value == value,
              onChanged: onChanged,
              showCheckmark: showCheckmark,
              colors: colors,
              scheme: scheme,
              tokens: tokens,
            )
          else
            Expanded(
              child: _Segment<T>(
                segment: segment,
                selected: segment.value == value,
                onChanged: onChanged,
                showCheckmark: showCheckmark,
                colors: colors,
                scheme: scheme,
                tokens: tokens,
              ),
            ),
      ],
    );

    return Semantics(
      // A radio group, so a screen reader announces "2 of 3" and the arrow keys
      // move between options.
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceSunken,
          borderRadius: BorderRadius.circular(tokens.radiusXl),
          border: Border.all(color: colors.outline, width: tokens.borderWidth),
        ),
        padding: EdgeInsets.all(tokens.borderWidth * 2),
        child: scrolls
            ? SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: row,
              )
            : row,
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.segment,
    required this.selected,
    required this.onChanged,
    required this.showCheckmark,
    required this.colors,
    required this.scheme,
    required this.tokens,
  });

  final PrismSegment<T> segment;
  final bool selected;
  final ValueChanged<T>? onChanged;
  final bool showCheckmark;
  final PrismColors colors;
  final ColorScheme scheme;
  final PrismTokens tokens;

  @override
  Widget build(BuildContext context) {
    final enabled = segment.enabled && onChanged != null;
    final foreground = !enabled
        ? colors.outline
        : selected
        ? scheme.onSecondaryContainer
        : scheme.onSurfaceVariant;

    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      enabled: enabled,
      button: true,
      label: segment.label,
      tooltip: segment.tooltip,
      child: ExcludeSemantics(
        child: Material(
          color: selected ? scheme.secondaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(tokens.radiusXl),
          child: InkWell(
            onTap: enabled ? () => onChanged!(segment.value) : null,
            borderRadius: BorderRadius.circular(tokens.radiusXl),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceMd,
                vertical: tokens.spaceSm + tokens.spaceXs,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (showCheckmark && selected) ...[
                    Icon(Icons.check, size: 16, color: foreground),
                    SizedBox(width: tokens.spaceXs),
                  ],
                  if (segment.icon != null) ...[
                    Icon(segment.icon, size: 18, color: foreground),
                    SizedBox(width: tokens.spaceXs),
                  ],
                  Text(
                    segment.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
