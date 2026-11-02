import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A circular or rounded avatar with initials fallback, presence and status.
///
/// Handles the three cases every app hits: an image that loads, an image
/// that *fails*, and a user with no image at all. Initials are derived from
/// the name automatically and the background color is picked deterministically
/// from the name, so the same person always looks the same.
///
/// ```dart
/// PrismAvatar(name: 'Ayesha Khan')
/// PrismAvatar(name: 'Ayesha Khan', imageUrl: user.photoUrl, size: 56)
/// PrismAvatar(name: 'Ayesha Khan', presence: PrismPresence.online)
/// ```
class PrismAvatar extends StatelessWidget {
  /// Creates an avatar.
  const PrismAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.image,
    this.size = 40,
    this.shape = PrismAvatarShape.circle,
    this.backgroundColor,
    this.foregroundColor,
    this.presence,
    this.badge,
    this.initialsOverride,
    this.semanticLabel,
    this.borderWidth = 0,
    this.borderColor,
  });

  /// Display name. Used for initials, color selection and the a11y label.
  final String name;

  /// Network image URL. Falls back to initials if it fails to load.
  final String? imageUrl;

  /// In-memory image provider, useful for locally picked photos.
  final ImageProvider? image;

  /// Avatar diameter (or width for non-circular shapes).
  final double size;

  /// Circle by default; choose [PrismAvatarShape.rounded] for app icons.
  final PrismAvatarShape shape;

  /// Fallback background; defaults to a deterministic palette color.
  final Color? backgroundColor;

  /// Fallback text color; defaults to a color that contrasts the background.
  final Color? foregroundColor;

  /// Optional presence dot.
  final PrismPresence? presence;

  /// Optional widget layered at the bottom-end corner (e.g. a count badge).
  final Widget? badge;

  /// Overrides the computed initials.
  final String? initialsOverride;

  /// Accessibility label; defaults to the name plus presence.
  final String? semanticLabel;

  /// Ring width drawn around the avatar.
  final double borderWidth;

  /// Ring color; defaults to the theme surface.
  final Color? borderColor;

  /// Derives up to two uppercase initials from [name].
  ///
  /// Handles single names and names with punctuation or extra whitespace.
  static String initialsFor(String name, {int max = 2}) {
    final parts = name
        .trim()
        .split(RegExp(r'[\s._-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final single = parts.first;
      return single.characters.take(max).toString().toUpperCase();
    }
    return parts.take(max).map((p) => p.characters.first).join().toUpperCase();
  }

  /// Deterministically picks a stable background color for [name] from the
  /// theme's tonal palette.
  ///
  /// The same name always maps to the same color, so avatars stay visually
  /// stable across rebuilds, sessions and devices.
  static Color colorFor(BuildContext context, String name) {
    final scheme = Theme.of(context).colorScheme;
    final index = name.trim().toLowerCase().hashCode.abs() % 6;
    switch (index) {
      case 0:
        return scheme.primaryContainer;
      case 1:
        return scheme.secondaryContainer;
      case 2:
        return scheme.tertiaryContainer;
      case 3:
        return scheme.surfaceContainerHighest;
      case 4:
        return Color.alphaBlend(
          scheme.primary.withValues(alpha: 0.24),
          scheme.surfaceContainerHighest,
        );
      default:
        return Color.alphaBlend(
          scheme.tertiary.withValues(alpha: 0.24),
          scheme.surfaceContainerHighest,
        );
    }
  }

  /// A foreground color that reads well on [background].
  static Color onColorFor(Color background) {
    return ThemeData.estimateBrightnessForColor(background) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }

  BorderRadius _radius() {
    switch (shape) {
      case PrismAvatarShape.circle:
        return BorderRadius.circular(size / 2);
      case PrismAvatarShape.rounded:
        return BorderRadius.circular(size * 0.28);
      case PrismAvatarShape.square:
        return BorderRadius.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? colorFor(context, name);
    final fg = foregroundColor ?? onColorFor(bg);
    final initials = initialsOverride ?? initialsFor(name);
    final presenceValue = presence;
    final label =
        semanticLabel ??
        (presenceValue == null ? name : '$name, ${presenceValue.label}');

    final provider =
        image ?? (imageUrl != null ? NetworkImage(imageUrl!) : null);

    Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: _radius()),
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      child: provider == null
          ? _Initials(text: initials, size: size, color: fg)
          : Image(
              image: provider,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Any load failure silently falls back to initials so avatars
              // never render as a broken-image glyph.
              errorBuilder: (context, error, stack) =>
                  _Initials(text: initials, size: size, color: fg),
            ),
    );

    if (borderWidth > 0) {
      content = Container(
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: shape == PrismAvatarShape.circle
              ? BoxShape.circle
              : BoxShape.rectangle,
          borderRadius: shape == PrismAvatarShape.circle ? null : _radius(),
          border: Border.all(
            color: borderColor ?? Theme.of(context).colorScheme.surface,
            width: borderWidth,
          ),
        ),
        child: content,
      );
    }

    if (presenceValue != null || badge != null) {
      content = Stack(
        clipBehavior: Clip.none,
        children: [
          content,
          if (presenceValue != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: _PresenceDot(
                presence: presenceValue,
                size: (size * 0.26).clamp(8.0, 18.0),
                ringColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          if (badge != null) Positioned(right: -2, top: -2, child: badge!),
        ],
      );
    }

    return Semantics(
      image: provider != null,
      label: label,
      child: ExcludeSemantics(child: content),
    );
  }
}

class _Initials extends StatelessWidget {
  const _Initials({
    required this.text,
    required this.size,
    required this.color,
  });

  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textScaler: TextScaler.noScaling,
      style: TextStyle(
        color: color,
        fontSize: size * 0.4,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        height: 1,
      ),
    );
  }
}

class _PresenceDot extends StatelessWidget {
  const _PresenceDot({
    required this.presence,
    required this.size,
    required this.ringColor,
  });

  final PrismPresence presence;
  final double size;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: presence.color(context),
        shape: BoxShape.circle,
        border: Border.all(color: ringColor, width: size * 0.18),
      ),
    );
  }
}

/// The shape of a [PrismAvatar].
enum PrismAvatarShape {
  /// A perfect circle (default).
  circle,

  /// A rounded square — suits app icons and team logos.
  rounded,

  /// A sharp square.
  square,
}

/// Online/away/busy/offline presence indicator.
enum PrismPresence {
  /// User is available.
  online,

  /// User is reachable but idle.
  away,

  /// User is busy or in a call.
  busy,

  /// User is offline.
  offline;

  /// Human-readable label used in accessibility announcements.
  String get label {
    switch (this) {
      case PrismPresence.online:
        return 'online';
      case PrismPresence.away:
        return 'away';
      case PrismPresence.busy:
        return 'busy';
      case PrismPresence.offline:
        return 'offline';
    }
  }

  /// The dot color for this presence in the current theme.
  Color color(BuildContext context) {
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;
    switch (this) {
      case PrismPresence.online:
        return colors.success;
      case PrismPresence.away:
        return colors.warning;
      case PrismPresence.busy:
        return colors.error;
      case PrismPresence.offline:
        return scheme.outline;
    }
  }
}
