import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// One event on a [PrismTimeline].
@immutable
class PrismTimelineEntry {
  /// Creates a timeline entry.
  const PrismTimelineEntry({
    required this.title,
    this.subtitle,
    this.timestamp,
    this.icon,
    this.semantic = PrismSemantic.info,
    this.child,
    this.trailing,
    this.accentColor,
    this.isActive = false,
  });

  /// Primary line of text.
  final String title;

  /// Optional secondary line.
  final String? subtitle;

  /// Optional timestamp or relative time label.
  final String? timestamp;

  /// Icon drawn in the marker. Defaults to the semantic role's icon.
  final IconData? icon;

  /// Semantic role driving marker colors and the default icon.
  final PrismSemantic semantic;

  /// Arbitrary content rendered under the header (cards, code, images).
  final Widget? child;

  /// Widget rendered at the trailing edge of the header row.
  final Widget? trailing;

  /// Overrides the marker color entirely.
  final Color? accentColor;

  /// Emphasizes this entry — a filled marker and heavier title.
  final bool isActive;
}

/// A vertical timeline of events, with connectors drawn between markers.
///
/// Good for order tracking, audit logs, activity feeds, changelogs and
/// onboarding checklists. Entries accept arbitrary [child] content, so each
/// node can expand into a card without leaving the timeline.
///
/// ```dart
/// PrismTimeline(
///   entries: [
///     PrismTimelineEntry(
///       title: 'Order placed',
///       timestamp: '09:12',
///       semantic: PrismSemantic.success,
///       icon: Icons.check,
///     ),
///     PrismTimelineEntry(
///       title: 'Out for delivery',
///       subtitle: 'Driver: Sam · 2 stops away',
///       timestamp: '09:48',
///       isActive: true,
///     ),
///   ],
/// )
/// ```
class PrismTimeline extends StatelessWidget {
  /// Creates a timeline.
  const PrismTimeline({
    super.key,
    required this.entries,
    this.markerSize = 28,
    this.connectorWidth = 2,
    this.dense = false,
    this.alternate = false,
    this.onEntryTap,
    this.padding,
    this.indent = 0,
  });

  /// Events, top to bottom.
  final List<PrismTimelineEntry> entries;

  /// Diameter of each marker.
  final double markerSize;

  /// Thickness of the connector line.
  final double connectorWidth;

  /// Tightens spacing and typography.
  final bool dense;

  /// Mirrors entries left/right of a centre line (wide windows only).
  final bool alternate;

  /// Called when an entry's header is tapped.
  final void Function(int index, PrismTimelineEntry entry)? onEntryTap;

  /// Outer padding around the whole timeline.
  final EdgeInsetsGeometry? padding;

  /// Leading indent applied to the entire timeline.
  final double indent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    if (entries.isEmpty) {
      return Padding(
        padding: padding ?? EdgeInsets.all(tokens.spaceMd),
        child: Text(
          'Nothing to show yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    final wideEnough = MediaQuery.sizeOf(context).width >= tokens.breakpointExpanded;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < entries.length; i++)
            _TimelineRow(
              entry: entries[i],
              index: i,
              isFirst: i == 0,
              isLast: i == entries.length - 1,
              markerSize: markerSize,
              connectorWidth: connectorWidth,
              dense: dense,
              mirror: alternate && wideEnough,
              indent: indent,
              onTap: onEntryTap == null
                  ? null
                  : () => onEntryTap!(i, entries[i]),
            ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.entry,
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.markerSize,
    required this.connectorWidth,
    required this.dense,
    required this.mirror,
    required this.indent,
    this.onTap,
  });

  final PrismTimelineEntry entry;
  final int index;
  final bool isFirst;
  final bool isLast;
  final double markerSize;
  final double connectorWidth;
  final bool dense;
  final bool mirror;
  final double indent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;

    final accent = entry.accentColor ??
        (entry.isActive
            ? colors.accentForRole(entry.semantic)
            : colors.forRole(entry.semantic).foreground);
    final containerColor = entry.isActive
        ? accent
        : colors.forRole(entry.semantic).background;
    final markerIcon = entry.icon ?? colors.iconForRole(entry.semantic);
    final gap = dense ? tokens.spaceSm : tokens.spaceMd;
    final bottomPad = dense ? tokens.spaceMd : tokens.spaceLg;

    final marker = Container(
      width: markerSize,
      height: markerSize,
      decoration: BoxDecoration(
        color: containerColor,
        shape: BoxShape.circle,
        border: entry.isActive
            ? null
            : Border.all(color: accent.withValues(alpha: 0.5), width: connectorWidth),
      ),
      child: Icon(
        markerIcon,
        size: markerSize * 0.55,
        color: entry.isActive
            ? (ThemeData.estimateBrightnessForColor(accent) == Brightness.dark
                ? Colors.white
                : Colors.black87)
            : accent,
      ),
    );

    final header = Column(
      crossAxisAlignment:
          mirror ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                entry.title,
                textAlign: mirror ? TextAlign.end : TextAlign.start,
                style: (dense
                        ? Theme.of(context).textTheme.bodyMedium
                        : Theme.of(context).textTheme.titleSmall)
                    ?.copyWith(
                  fontWeight: entry.isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            if (entry.trailing != null) ...[
              SizedBox(width: tokens.spaceSm),
              entry.trailing!,
            ],
          ],
        ),
        if (entry.timestamp != null) ...[
          SizedBox(height: tokens.spaceXs / 2),
          Text(
            entry.timestamp!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
        if (entry.subtitle != null) ...[
          SizedBox(height: tokens.spaceXs),
          Text(
            entry.subtitle!,
            textAlign: mirror ? TextAlign.end : TextAlign.start,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
        if (entry.child != null) ...[
          SizedBox(height: tokens.spaceSm),
          entry.child!,
        ],
      ],
    );

    // IntrinsicHeight gives the marker column a definite height so the
    // connector can use Expanded and stretch to the content's height.
    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        textDirection: mirror ? TextDirection.rtl : TextDirection.ltr,
        children: [
          SizedBox(
            width: markerSize,
            child: Column(
              children: [
                // Incoming connector (absent on the first entry).
                if (!isFirst)
                  SizedBox(
                    height: dense ? tokens.spaceXs : tokens.spaceSm,
                    child: _Connector(
                      width: connectorWidth,
                      color: colors.outline,
                    ),
                  ),
                marker,
                if (!isLast)
                  Expanded(
                    child: _Connector(
                      width: connectorWidth,
                      color: colors.outline,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : bottomPad * 0.6),
              child: header,
            ),
          ),
        ],
      ),
    );

    final tappable = onTap == null
        ? row
        : Semantics(
            button: true,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.spaceXs),
                child: row,
              ),
            ),
          );

    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: tappable,
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(width / 2),
      ),
    );
  }
}
