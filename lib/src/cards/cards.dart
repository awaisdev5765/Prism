import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A card with an optional tap target, corner radius and elevation from tokens.
///
/// Wraps Flutter's `Card` so it uses Prism tokens for the radius and margin
/// rather than the Material default. Adds a `onLongPress` callback, which the
/// default lacks.
///
/// ```dart
/// PrismCard(
///   onTap: () => openNote(note),
///   onLongPress: () => showActions(note),
///   child: Text(note.title),
/// )
/// ```
class PrismCard extends StatelessWidget {
  /// Creates a card.
  const PrismCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.margin,
    this.padding,
    this.color,
    this.radius,
    this.elevation = 1,
    this.border,
  });

  /// The content inside the card.
  final Widget child;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Called when the card is long-pressed.
  final VoidCallback? onLongPress;

  /// Outer margin. Defaults to zero.
  final EdgeInsetsGeometry? margin;

  /// Inner padding. Defaults to [PrismTokens.spaceMd].
  final EdgeInsetsGeometry? padding;

  /// Card background colour. Defaults to the theme surface.
  final Color? color;

  /// Corner radius. Defaults to [PrismTokens.radiusLg].
  final double? radius;

  /// Elevation. Defaults to 1.
  final double elevation;

  /// Optional border. When set, the card is not elevated.
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final scheme = Theme.of(context).colorScheme;
    final resolvedRadius = radius ?? tokens.radiusLg;

    final card = Material(
      color: color ?? scheme.surfaceContainerLow,
      elevation: border != null ? 0 : elevation,
      shadowColor: scheme.shadow.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(resolvedRadius),
      borderOnForeground: border != null,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: padding ?? EdgeInsets.all(tokens.spaceMd),
          child: child,
        ),
      ),
    );

    if (border != null) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(resolvedRadius),
          border: border,
        ),
        child: card,
      );
    }

    return Container(margin: margin, child: card);
  }
}

/// A list tile with a leading icon, title, subtitle, trailing widget and an
/// optional badge, using Prism tokens for the spacing.
///
/// Wraps `ListTile` and adds a `badge` slot, which the default does not have.
/// Useful for a list of conversations or notifications.
///
/// ```dart
/// PrismTile(
///   leading: Icon(Icons.note_outlined),
///   title: 'Shopping list',
///   subtitle: '3 items',
///   badge: PrismBadge(count: 2, child: const SizedBox.shrink()),
///   onTap: () {},
/// )
/// ```
class PrismTile extends StatelessWidget {
  /// Creates a tile.
  const PrismTile({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.badge,
    this.onTap,
    this.onLongPress,
    this.selected = false,
    this.enabled = true,
    this.dense = false,
  });

  /// Leading widget, usually an icon or an avatar.
  final Widget? leading;

  /// Primary text.
  final String title;

  /// Supporting text under the title.
  final String? subtitle;

  /// Widget at the trailing edge, after any badge.
  final Widget? trailing;

  /// Widget rendered on top of the trailing widget, e.g. a count badge.
  final Widget? badge;

  /// Called when the tile is tapped.
  final VoidCallback? onTap;

  /// Called when the tile is long-pressed.
  final VoidCallback? onLongPress;

  /// Whether the tile is highlighted as the current selection.
  final bool selected;

  /// Whether the tile can be tapped.
  final bool enabled;

  /// Whether to use a smaller row height.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.prismColors;
    final foreground = enabled ? scheme.onSurface : colors.outline;

    return Semantics(
      button: onTap != null,
      selected: selected,
      label: title,
      child: ExcludeSemantics(
        child: ListTile(
          leading: leading,
          title: Text(
            title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: foreground,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          subtitle: subtitle == null
              ? null
              : Text(
                  subtitle!,
                  maxLines: dense ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
          trailing: badge != null
              ? SizedBox(
                  width: tokens.spaceLg,
                  height: tokens.spaceLg,
                  child: badge,
                )
              : trailing,
          onTap: enabled ? onTap : null,
          onLongPress: enabled ? onLongPress : null,
          selected: selected,
          enabled: enabled,
          dense: dense,
        ),
      ),
    );
  }
}

/// A hairline divider with optional label, for grouping content.
///
/// Wraps `Divider` and `VerticalDivider` with Prism token colours and spacing,
/// and adds a centred label for a common pattern that the defaults lack.
///
/// ```dart
/// PrismDivider()
/// PrismDivider(label: 'Or continue with')
/// ```
class PrismDivider extends StatelessWidget {
  /// Creates a horizontal divider, optionally with a centred label.
  const PrismDivider({
    super.key,
    this.label,
    this.height,
    this.thickness,
    this.color,
    this.indent,
    this.endIndent,
  });

  /// Label rendered in the middle of the line.
  final String? label;

  /// Vertical space the divider occupies.
  final double? height;

  /// Line thickness.
  final double? thickness;

  /// Line colour. Defaults to the theme's outline variant.
  final Color? color;

  /// Space before the line starts.
  final double? indent;

  /// Space after the line ends.
  final double? endIndent;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final lineColour = color ?? Theme.of(context).colorScheme.outlineVariant;

    if (label == null) {
      return Divider(
        height: height,
        thickness: thickness ?? tokens.borderWidth,
        color: lineColour,
        indent: indent,
        endIndent: endIndent,
      );
    }

    final side = (indent ?? 0.0) + (endIndent ?? 0.0);
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: lineColour,
            thickness: thickness ?? tokens.borderWidth,
            indent: indent,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceMd),
          child: Text(
            label!,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            color: lineColour,
            thickness: thickness ?? tokens.borderWidth,
            endIndent: endIndent,
          ),
        ),
      ],
    );
  }
}
