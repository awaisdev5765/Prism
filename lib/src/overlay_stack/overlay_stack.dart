import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A step in a [PrismOverlayStack] onboarding tour.
@immutable
class PrismOverlayStep {
  /// Creates a tour step anchored to [anchorKey].
  const PrismOverlayStep({
    required this.anchorKey,
    required this.title,
    this.message,
    this.child,
  });

  /// GlobalKey of the widget the spotlight should surround.
  final GlobalKey anchorKey;

  /// Headline for the tooltip card.
  final String title;

  /// Optional body copy under the title.
  final String? message;

  /// Optional extra widget below the message (e.g. an illustration).
  final Widget? child;
}

/// A guided onboarding tour that dims the screen and spotlights widgets.
///
/// Pass one [GlobalKey] per step, in order. Each step dims everything except
/// the anchored widget's bounds and shows a tooltip card next to it — above on
/// compact windows, beside on wide ones. Users advance by tapping the card's
/// button or anywhere on the dimmed area; a skip button is always available.
///
/// ```dart
/// final key = GlobalKey();
/// // …attach key to the widget you spotlight…
/// PrismOverlayStack(
///   steps: [
///     PrismOverlayStep(
///       anchorKey: key,
///       title: 'Search everything',
///       message: 'Press ⌘K or tap here to search.',
///     ),
///   ],
///   onDone: markOnboardingSeen,
/// )
/// ```
class PrismOverlayStack extends StatefulWidget {
  /// Creates a spotlight tour. Steps are shown in order; an empty list
  /// renders nothing.
  const PrismOverlayStack({
    super.key,
    required this.steps,
    required this.onDone,
    this.onSkip,
    this.skipLabel = 'Skip tour',
    this.darkening = 0.6,
  });

  /// Steps of the tour, in visiting order.
  final List<PrismOverlayStep> steps;

  /// Called after the last step is completed.
  final VoidCallback onDone;

  /// Called when the user skips the tour.
  final VoidCallback? onSkip;

  /// Label for the skip button.
  final String skipLabel;

  /// How dark the dimming layer is, 0..1.
  final double darkening;

  @override
  State<PrismOverlayStack> createState() => _PrismOverlayStackState();
}

class _PrismOverlayStackState extends State<PrismOverlayStack> {
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _showOverlay());
  }

  void _showOverlay() {
    if (!mounted || _entry != null || widget.steps.isEmpty) return;
    _insertEntry(0);
  }

  void _insertEntry(int index) {
    _entry = OverlayEntry(
      builder: (context) => _TourLayer(
        step: widget.steps[index],
        index: index,
        count: widget.steps.length,
        darkening: widget.darkening,
        skipLabel: widget.skipLabel,
        onNext: () {
          final next = index + 1;
          if (next >= widget.steps.length) {
            _finish();
          } else {
            _entry?.remove();
            _entry = null;
            _insertEntry(next);
          }
        },
        onSkip: _finishSkip,
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(_entry!);
  }

  void _finish() {
    _entry?.remove();
    _entry = null;
    widget.onDone();
  }

  void _finishSkip() {
    _entry?.remove();
    _entry = null;
    widget.onSkip?.call();
  }

  @override
  void dispose() {
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  // The tour renders nothing in the tree itself; all visuals live in the
  // overlay above the Navigator.
  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _TourLayer extends StatelessWidget {
  const _TourLayer({
    required this.step,
    required this.index,
    required this.count,
    required this.darkening,
    required this.skipLabel,
    required this.onNext,
    required this.onSkip,
  });

  final PrismOverlayStep step;
  final int index;
  final int count;
  final double darkening;
  final String skipLabel;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final theme = Theme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= tokens.breakpointExpanded;
    final size = MediaQuery.sizeOf(context);

    // Find the anchor bounds in screen coordinates.
    Rect? anchorRect;
    final ro = step.anchorKey.currentContext?.findRenderObject();
    if (ro is RenderBox && ro.attached && ro.hasSize) {
      anchorRect = ro.localToGlobal(Offset.zero) & ro.size;
    }

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onNext,
        child: Stack(
          children: [
            if (anchorRect != null)
              Positioned.fill(
                child: CustomPaint(
                  painter: _SpotlightPainter(
                    rect: anchorRect,
                    darkening: darkening,
                    radius: tokens.radiusMd,
                  ),
                ),
              )
            else
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withValues(alpha: darkening),
                ),
              ),
            if (anchorRect != null)
              // Card, positioned above or beside the anchor.
              Positioned(
                left: _cardLeft(anchorRect, size, tokens, wide),
                top: _cardTop(anchorRect, size, tokens, wide),
                child: _card(context, tokens, colors, theme, wide, size),
              )
            else
              Center(child: _card(context, tokens, colors, theme, wide, size)),
            Positioned(
              top: MediaQuery.paddingOf(context).top + tokens.spaceSm,
              right: tokens.spaceMd,
              child: TextButton(onPressed: onSkip, child: Text(skipLabel)),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isLast => index == count - 1;

  double _cardLeft(Rect anchor, Size screen, PrismTokens tokens, bool wide) {
    final width = wide ? 320.0 : screen.width - tokens.spaceLg * 2;
    if (wide) {
      // Prefer beside the anchor; flip left if there is no room right.
      final left = anchor.right + tokens.spaceMd;
      return left + width > screen.width - tokens.spaceMd
          ? anchor.left - tokens.spaceMd - width
          : left;
    }
    return (screen.width - width) / 2;
  }

  double _cardTop(Rect anchor, Size screen, PrismTokens tokens, bool wide) {
    if (wide) return anchor.top;
    // Compact: above the anchor if possible, else below.
    const estimated = 180.0;
    return anchor.top - estimated - tokens.spaceMd > 0
        ? anchor.top - estimated - tokens.spaceMd
        : anchor.bottom + tokens.spaceMd;
  }

  Widget _card(
    BuildContext context,
    PrismTokens tokens,
    PrismColors colors,
    ThemeData theme,
    bool wide,
    Size screen,
  ) {
    final width = wide ? 320.0 : screen.width - tokens.spaceLg * 2;
    return Container(
      width: width,
      padding: EdgeInsets.all(tokens.spaceMd),
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            step.title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (step.message != null) ...[
            SizedBox(height: tokens.spaceXs),
            Text(
              step.message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          if (step.child != null) ...[
            SizedBox(height: tokens.spaceSm),
            step.child!,
          ],
          SizedBox(height: tokens.spaceMd),
          Row(
            children: [
              for (var i = 0; i < count; i++)
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  width: i == index ? 20 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == index
                        ? theme.colorScheme.primary
                        : colors.outline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              const Spacer(),
              FilledButton(
                onPressed: onNext,
                child: Text(_isLast ? 'Done' : 'Next'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({
    required this.rect,
    required this.darkening,
    required this.radius,
  });

  final Rect rect;
  final double darkening;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: darkening);
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(
        RRect.fromRectAndRadius(rect.inflate(8), Radius.circular(radius)),
      )
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.rect != rect || old.darkening != darkening || old.radius != radius;
}
