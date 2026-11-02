import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The state of a single step in a [PrismStepper].
enum PrismStepState {
  /// Not yet started.
  pending,

  /// Currently being worked on.
  active,

  /// Finished successfully.
  complete,

  /// Finished with a problem the user must fix.
  error,
}

/// One step of a [PrismStepper].
@immutable
class PrismStep {
  /// Creates a step.
  const PrismStep({
    required this.title,
    this.subtitle,
    this.icon,
    this.isOptional = false,
    this.isEnabled = true,
  });

  /// Step label.
  final String title;

  /// Supporting description.
  final String? subtitle;

  /// Icon shown in the marker when the step is not complete or in error.
  final IconData? icon;

  /// Marks the step as optional in its label.
  final bool isOptional;

  /// When false, the step cannot be navigated to by tapping.
  final bool isEnabled;
}

/// A horizontal progress stepper for wizards and multi-step flows.
///
/// Shows every step with a marker, a label and a connector, colouring each by
/// its [PrismStepState]. On wide windows it lays out horizontally; on narrow
/// windows it collapses to a compact "Step 2 of 4 — Profile" header with a
/// progress bar, which stays readable where a row of labels would not.
///
/// ```dart
/// PrismStepper(
///   steps: const [
///     PrismStep(title: 'Account'),
///     PrismStep(title: 'Profile'),
///     PrismStep(title: 'Preferences', isOptional: true),
///   ],
///   currentIndex: 1,
///   onStepTapped: (i) => goTo(i),
/// )
/// ```
class PrismStepper extends StatelessWidget {
  /// Creates a stepper.
  const PrismStepper({
    super.key,
    required this.steps,
    required this.currentIndex,
    this.completedIndices = const {},
    this.erroredIndices = const {},
    this.onStepTapped,
    this.compactBreakpoint,
    this.markerSize = 32,
    this.horizontalLabels = true,
    this.semanticLabel,
  });

  /// The ordered steps.
  final List<PrismStep> steps;

  /// Index of the active step.
  final int currentIndex;

  /// Indices already completed. Any index below [currentIndex] is treated as
  /// complete unless it appears in [erroredIndices].
  final Set<int> completedIndices;

  /// Indices that finished with an error.
  final Set<int> erroredIndices;

  /// Called when a step marker or label is tapped.
  final ValueChanged<int>? onStepTapped;

  /// Overrides the token breakpoint below which the compact layout is used.
  final double? compactBreakpoint;

  /// Diameter of step markers.
  final double markerSize;

  /// Whether labels sit beside markers (true) or only on the active step.
  final bool horizontalLabels;

  /// Accessibility label for the whole stepper.
  final String? semanticLabel;

  /// Resolves the state of [index].
  PrismStepState stateOf(int index) {
    if (erroredIndices.contains(index)) return PrismStepState.error;
    if (index == currentIndex) return PrismStepState.active;
    if (completedIndices.contains(index) || index < currentIndex) {
      return PrismStepState.complete;
    }
    return PrismStepState.pending;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final breakpoint = compactBreakpoint ?? tokens.breakpointCompact;
    final isCompact = MediaQuery.sizeOf(context).width < breakpoint;

    if (steps.isEmpty) return const SizedBox.shrink();

    final label =
        semanticLabel ??
        'Step ${currentIndex + 1} of ${steps.length}: ${steps[currentIndex].title}';

    return Semantics(
      label: label,
      container: true,
      child: isCompact
          ? _CompactStepper(
              steps: steps,
              currentIndex: currentIndex,
              stateOf: stateOf,
            )
          : _WideStepper(
              steps: steps,
              currentIndex: currentIndex,
              stateOf: stateOf,
              onStepTapped: onStepTapped,
              markerSize: markerSize,
              horizontalLabels: horizontalLabels,
            ),
    );
  }
}

class _CompactStepper extends StatelessWidget {
  const _CompactStepper({
    required this.steps,
    required this.currentIndex,
    required this.stateOf,
  });

  final List<PrismStep> steps;
  final int currentIndex;
  final PrismStepState Function(int index) stateOf;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;
    final current = steps[currentIndex];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _Marker(
              state: stateOf(currentIndex),
              index: currentIndex,
              size: 28,
            ),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Step ${currentIndex + 1} of ${steps.length}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    current.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (current.isOptional)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.surfaceSunken,
                  borderRadius: BorderRadius.circular(tokens.radiusXl),
                ),
                child: Text(
                  'Optional',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
          ],
        ),
        SizedBox(height: tokens.spaceSm),
        ClipRRect(
          borderRadius: BorderRadius.circular(tokens.radiusXl),
          child: LinearProgressIndicator(
            value: (currentIndex + 1) / steps.length,
            minHeight: 6,
            backgroundColor: colors.surfaceSunken,
          ),
        ),
      ],
    );
  }
}

class _WideStepper extends StatelessWidget {
  const _WideStepper({
    required this.steps,
    required this.currentIndex,
    required this.stateOf,
    required this.onStepTapped,
    required this.markerSize,
    required this.horizontalLabels,
  });

  final List<PrismStep> steps;
  final int currentIndex;
  final PrismStepState Function(int index) stateOf;
  final ValueChanged<int>? onStepTapped;
  final double markerSize;
  final bool horizontalLabels;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < steps.length; i++)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: i == 0
                          ? const SizedBox.shrink()
                          : _Connector(
                              done: stateOf(i - 1) == PrismStepState.complete,
                            ),
                    ),
                    _Tappable(
                      enabled: onStepTapped != null && steps[i].isEnabled,
                      onTap: () => onStepTapped!(i),
                      child: _Marker(
                        state: stateOf(i),
                        index: i,
                        size: markerSize,
                        icon: steps[i].icon,
                      ),
                    ),
                    Expanded(
                      child: i == steps.length - 1
                          ? const SizedBox.shrink()
                          : _Connector(
                              done: stateOf(i) == PrismStepState.complete,
                            ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spaceSm),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceXs),
                  child: _Tappable(
                    enabled: onStepTapped != null && steps[i].isEnabled,
                    onTap: () => onStepTapped!(i),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (horizontalLabels || i == currentIndex)
                          Text(
                            steps[i].title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontWeight: i == currentIndex
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: stateOf(i) == PrismStepState.pending
                                      ? Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant
                                      : null,
                                ),
                          ),
                        if (steps[i].subtitle != null &&
                            (horizontalLabels || i == currentIndex)) ...[
                          const SizedBox(height: 2),
                          Text(
                            steps[i].subtitle!,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: colors.outline),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Tappable extends StatelessWidget {
  const _Tappable({
    required this.child,
    required this.enabled,
    required this.onTap,
  });

  final Widget child;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: child,
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.state,
    required this.index,
    required this.size,
    this.icon,
  });

  final PrismStepState state;
  final int index;
  final double size;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;

    late final Color background;
    late final Color foreground;
    IconData? glyph = icon;

    switch (state) {
      case PrismStepState.complete:
        background = colors.success;
        foreground = colors.onSuccess;
        glyph = Icons.check;
      case PrismStepState.active:
        background = scheme.primary;
        foreground = scheme.onPrimary;
      case PrismStepState.error:
        background = colors.error;
        foreground = colors.onError;
        glyph = Icons.priority_high;
      case PrismStepState.pending:
        background = colors.surfaceSunken;
        foreground = scheme.onSurfaceVariant;
    }

    return AnimatedContainer(
      duration: context.prismTokens.durationMedium,
      curve: context.prismTokens.curveStandard,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: state == PrismStepState.pending
            ? Border.all(
                color: colors.outline,
                width: context.prismTokens.borderWidth,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: glyph != null
          ? Icon(glyph, size: size * 0.5, color: foreground)
          : Text(
              '${index + 1}',
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.4,
                height: 1,
              ),
            ),
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    return AnimatedContainer(
      duration: tokens.durationMedium,
      height: 2,
      color: done ? colors.success : colors.outline,
    );
  }
}
