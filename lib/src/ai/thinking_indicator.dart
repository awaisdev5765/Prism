import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Animated indicator shown while an assistant is producing a reply.
///
/// Three pulsing dots plus an optional reasoning label. The animation honours
/// the platform's reduced-motion setting — with reduced motion the dots stay
/// static and the widget becomes a plain, announced status label.
///
/// ```dart
/// PrismAiThinkingIndicator(label: 'Searching documents…')
/// ```
class PrismAiThinkingIndicator extends StatefulWidget {
  /// Creates a thinking indicator.
  const PrismAiThinkingIndicator({
    super.key,
    this.label,
    this.dotColor,
    this.size = 8,
  });

  /// Optional status text shown beside the dots, e.g. "Using tool: search".
  final String? label;

  /// Dot colour; defaults to the ambient primary colour.
  final Color? dotColor;

  /// Diameter of each dot.
  final double size;

  @override
  State<PrismAiThinkingIndicator> createState() =>
      _PrismAiThinkingIndicatorState();
}

class _PrismAiThinkingIndicatorState extends State<PrismAiThinkingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMotion());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  void _syncMotion() {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _timer?.cancel();
      _timer = null;
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.prismTokens;
    final color = widget.dotColor ?? theme.colorScheme.primary;
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    return Semantics(
      liveRegion: true,
      label: widget.label ?? 'Assistant is thinking',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: widget.size * 4,
            height: widget.size,
            child: reduced
                ? Row(
                    children: [
                      _dot(context, color, 1),
                      const Spacer(),
                      _dot(context, color, 0.5),
                      const Spacer(),
                      _dot(context, color, 0.5),
                    ],
                  )
                : AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t = _controller.value;
                      return Row(
                        children: [
                          _dot(context, color, _phase(t, 0)),
                          const Spacer(),
                          _dot(context, color, _phase(t, 0.33)),
                          const Spacer(),
                          _dot(context, color, _phase(t, 0.66)),
                        ],
                      );
                    },
                  ),
          ),
          if (widget.label != null) ...[
            SizedBox(width: tokens.spaceSm),
            Flexible(
              child: Text(
                widget.label!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Sine pulse offset by [offset] within the animation cycle.
  double _phase(double t, double offset) {
    final v = (t + offset) % 1;
    return 0.4 + 0.6 * (0.5 + 0.5 * (v * 2 * 3.14159).abs() - 0.5);
  }

  Widget _dot(BuildContext context, Color color, double opacity) => Opacity(
    opacity: opacity.clamp(0.3, 1),
    child: Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    ),
  );
}
