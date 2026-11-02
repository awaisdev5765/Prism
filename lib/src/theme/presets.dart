import 'package:flutter/material.dart';

import 'tokens.dart';

/// How tightly a Prism app is spaced.
///
/// Spacing and control height move together: a dense UI with comfortable
/// controls feels broken, so the two are never configured separately.
enum PrismDensity {
  /// Data-heavy screens: tables, dashboards, admin tools.
  compact,

  /// The default. Comfortable for touch, readable at a desk.
  comfortable,

  /// Reading and focus: one thing at a time, generous breathing room.
  spacious,
}

/// The corner-radius personality of a Prism app.
///
/// This is the single most noticeable "look" decision after colour, and getting
/// it consistent across every component is exactly what a token set is for.
enum PrismShape {
  /// Square corners. Feels technical and precise.
  sharp,

  /// Slightly rounded. Unremarkable in the best way.
  rounded,

  /// Fully rounded controls. Feels friendly and consumer-facing.
  pill,
}

/// How quickly motion runs.
enum PrismMotion {
  /// Snappy. Suits tools where the user is already in a flow.
  brisk,

  /// The default.
  standard,

  /// Slower and softer. Suits reading-oriented apps.
  relaxed,
}

/// Builds a token set from a density, a shape and a motion preference.
///
/// Composing three orthogonal choices is more honest than deriving spacing from
/// a colour: a brand colour says nothing about how much padding a table row
/// wants. Use this to get a coherent look in one line, then override individual
/// values if you need to.
///
/// ```dart
/// PrismTokens.preset(
///   density: PrismDensity.compact,
///   shape: PrismShape.sharp,
///   motion: PrismMotion.brisk,
/// )
/// ```
extension PrismTokenPresets on PrismTokens {
  /// Returns a token set for the given [density], [shape] and [motion].
  static PrismTokens preset({
    PrismDensity density = PrismDensity.comfortable,
    PrismShape shape = PrismShape.rounded,
    PrismMotion motion = PrismMotion.standard,
  }) {
    final space = switch (density) {
      PrismDensity.compact => const [3.0, 6.0, 12.0, 18.0, 24.0, 36.0],
      PrismDensity.comfortable => const [4.0, 8.0, 16.0, 24.0, 32.0, 48.0],
      PrismDensity.spacious => const [6.0, 12.0, 24.0, 36.0, 48.0, 72.0],
    };

    final radius = switch (shape) {
      PrismShape.sharp => const [0.0, 2.0, 3.0, 4.0],
      PrismShape.rounded => const [8.0, 12.0, 16.0, 24.0],
      PrismShape.pill => const [12.0, 20.0, 28.0, 999.0],
    };

    final duration = switch (motion) {
      PrismMotion.brisk => const [80, 150, 260],
      PrismMotion.standard => const [120, 240, 420],
      PrismMotion.relaxed => const [180, 340, 560],
    };

    final curve = switch (motion) {
      PrismMotion.brisk => Curves.easeOut,
      PrismMotion.standard => Curves.easeInOutCubic,
      PrismMotion.relaxed => Curves.easeInOut,
    };

    return PrismTokens(
      spaceXs: space[0],
      spaceSm: space[1],
      spaceMd: space[2],
      spaceLg: space[3],
      spaceXl: space[4],
      spaceXxl: space[5],
      radiusSm: radius[0],
      radiusMd: radius[1],
      radiusLg: radius[2],
      radiusXl: radius[3],
      durationFast: Duration(milliseconds: duration[0]),
      durationMedium: Duration(milliseconds: duration[1]),
      durationSlow: Duration(milliseconds: duration[2]),
      curveStandard: curve,
      controlHeight: switch (density) {
        PrismDensity.compact => 36,
        PrismDensity.comfortable => 44,
        PrismDensity.spacious => 52,
      },
    );
  }

  /// Compact density, sharp corners, brisk motion. For developer tools.
  static const PrismTokens technical = PrismTokens(
    spaceXs: 3,
    spaceSm: 6,
    spaceMd: 12,
    spaceLg: 18,
    spaceXl: 24,
    spaceXxl: 36,
    radiusSm: 0,
    radiusMd: 2,
    radiusLg: 3,
    radiusXl: 4,
    durationFast: Duration(milliseconds: 80),
    durationMedium: Duration(milliseconds: 150),
    durationSlow: Duration(milliseconds: 260),
    curveStandard: Curves.easeOut,
    controlHeight: 36,
  );

  /// Comfortable density, fully rounded controls. For consumer apps.
  static const PrismTokens friendly = PrismTokens(
    radiusSm: 12,
    radiusMd: 20,
    radiusLg: 28,
    radiusXl: 999,
    durationMedium: Duration(milliseconds: 280),
  );

  /// Spacious density, relaxed motion. For reading-oriented apps.
  static const PrismTokens editorial = PrismTokens(
    spaceXs: 6,
    spaceSm: 12,
    spaceMd: 24,
    spaceLg: 36,
    spaceXl: 48,
    spaceXxl: 72,
    radiusSm: 2,
    radiusMd: 4,
    radiusLg: 6,
    radiusXl: 8,
    durationFast: Duration(milliseconds: 180),
    durationMedium: Duration(milliseconds: 340),
    durationSlow: Duration(milliseconds: 560),
    curveStandard: Curves.easeInOut,
    contentMaxWidth: 640,
    controlHeight: 52,
  );
}

/// Builds a fully configured [ThemeData] for a Prism app.
///
/// One call replaces the three-step dance of seeding a scheme, registering
/// tokens and remembering to pass the same brightness twice:
///
/// ```dart
/// MaterialApp(
///   theme: prismTheme(seed: brandPurple),
///   darkTheme: prismTheme(seed: brandPurple, brightness: Brightness.dark),
/// )
/// ```
///
/// [base] is respected and extended rather than replaced, so typography and
/// component themes you already configured survive.
ThemeData prismTheme({
  Color seed = const Color(0xFF39A9DB),
  Brightness brightness = Brightness.light,
  PrismDensity density = PrismDensity.comfortable,
  PrismShape shape = PrismShape.rounded,
  PrismMotion motion = PrismMotion.standard,
  PrismTokens? tokens,
  ThemeData? base,
}) {
  final theme = base != null
      ? base.copyWith(
          colorScheme: base.colorScheme.brightness == brightness
              ? base.colorScheme
              : ColorScheme.fromSeed(seedColor: seed, brightness: brightness),
        )
      : ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: seed,
            brightness: brightness,
          ),
        );

  final resolved =
      tokens ??
      PrismTokenPresets.preset(density: density, shape: shape, motion: motion);

  return theme.copyWith(
    extensions: [
      ...theme.extensions.values.where((e) => e is! PrismTokens),
      resolved,
    ],
  );
}
