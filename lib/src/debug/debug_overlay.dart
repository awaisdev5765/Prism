import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A live inspector for the Prism design system.
///
/// Drop it over your app in debug builds and you can see exactly which tokens
/// are active, which window class the layout is in, and whether the platform is
/// asking for reduced motion. It answers the question every theming bug starts
/// with — "are the tokens I set actually the tokens being read?" — without
/// adding a print statement and rebuilding.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => PrismDebugOverlay(
///     enabled: kDebugMode,
///     child: child!,
///   ),
///   home: const HomePage(),
/// )
/// ```
///
/// [enabled] defaults to false, so it is safe to leave in a tree: pass
/// `kDebugMode` and it disappears in release builds.
class PrismDebugOverlay extends StatefulWidget {
  /// Creates a debug overlay.
  const PrismDebugOverlay({
    super.key,
    required this.child,
    this.enabled = false,
    this.initiallyExpanded = false,
    this.alignment = Alignment.topLeft,
  });

  /// The app.
  final Widget child;

  /// Whether the overlay is shown at all.
  final bool enabled;

  /// Whether the panel starts open.
  final bool initiallyExpanded;

  /// Where the badge and panel sit.
  final Alignment alignment;

  @override
  State<PrismDebugOverlay> createState() => _PrismDebugOverlayState();
}

class _PrismDebugOverlayState extends State<PrismDebugOverlay> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    // StackFit.expand, not the default: a Stack sizes itself to its largest
    // non-positioned child, so wrapping a small widget would leave the panel
    // outside the stack's bounds and untappable.
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        Positioned(
          top: widget.alignment.y < 0 ? 8 : null,
          bottom: widget.alignment.y >= 0 ? 8 : null,
          left: widget.alignment.x < 0 ? 8 : null,
          right: widget.alignment.x >= 0 ? 8 : null,
          child: SafeArea(
            child: _Panel(
              expanded: _expanded,
              onToggle: () => setState(() => _expanded = !_expanded),
            ),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);
    final windowClass = switch (size.width) {
      final w when w < tokens.breakpointCompact => 'compact',
      final w when w < tokens.breakpointExpanded => 'medium',
      final w when w < 1200 => 'expanded',
      _ => 'extra-large',
    };

    return Material(
      color: colors.surfaceRaised,
      elevation: 6,
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceSm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.tune, size: 16, color: scheme.primary),
                  SizedBox(width: tokens.spaceXs + 2),
                  Text(
                    expanded ? 'Prism' : 'Prism tokens',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: tokens.spaceXs + 2),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (expanded) ...[
                SizedBox(height: tokens.spaceSm),
                _Row(
                  label: 'viewport',
                  value:
                      '${size.width.round()} '
                      'x ${size.height.round()}',
                ),
                _Row(label: 'window class', value: windowClass),
                _Row(
                  label: 'brightness',
                  value: Theme.of(context).brightness.name,
                ),
                _Row(
                  label: 'reduce motion',
                  value: context.prismReduceMotion ? 'yes' : 'no',
                ),
                Divider(height: tokens.spaceMd, color: colors.outline),
                _Row(label: 'spaceMd', value: _n(tokens.spaceMd)),
                _Row(label: 'spaceLg', value: _n(tokens.spaceLg)),
                _Row(label: 'radiusMd', value: _n(tokens.radiusMd)),
                _Row(label: 'radiusLg', value: _n(tokens.radiusLg)),
                _Row(
                  label: 'durationMedium',
                  value: '${tokens.durationMedium.inMilliseconds}ms',
                ),
                _Row(label: 'controlHeight', value: _n(tokens.controlHeight)),
                Divider(height: tokens.spaceMd, color: colors.outline),
                Wrap(
                  spacing: tokens.spaceXs,
                  runSpacing: tokens.spaceXs,
                  children: [
                    for (final role in PrismSemantic.values)
                      _Swatch(role: role, colors: colors),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _n(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.spaceXs / 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: tokens.controlHeight * 2.6,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.role, required this.colors});

  final PrismSemantic role;
  final PrismColors colors;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final pair = colors.forRole(role);
    return Tooltip(
      message: '${role.name}: ${colors.accentForRole(role)}',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceXs + 2,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: pair.background,
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
        child: Text(
          role.name,
          style: TextStyle(fontSize: 10, color: pair.foreground),
        ),
      ),
    );
  }
}
