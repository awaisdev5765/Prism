import 'package:flutter/material.dart';

import 'colors.dart';

/// The shared design tokens every Prism component reads from.
///
/// Prism components ship with sensible defaults, so you never *have* to
/// install tokens. Register them once and every Prism widget on screen —
/// toasts, banners, sheets, skeletons, tables — picks up the same spacing
/// rhythm, corner radii and motion language.
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: const [PrismTokens.fallback], // or your own values
///   ),
/// )
/// ```
///
/// Read them anywhere with [PrismTokens.of] or the `context.prismTokens`
/// extension:
///
/// ```dart
/// final tokens = context.prismTokens;
/// SizedBox(height: tokens.spaceMd);
/// ```
@immutable
class PrismTokens extends ThemeExtension<PrismTokens> {
  /// Creates a token set. Every field has a sensible default so you can
  /// override only what you care about.
  const PrismTokens({
    this.spaceXs = 4,
    this.spaceSm = 8,
    this.spaceMd = 16,
    this.spaceLg = 24,
    this.spaceXl = 32,
    this.spaceXxl = 48,
    this.radiusSm = 8,
    this.radiusMd = 12,
    this.radiusLg = 16,
    this.radiusXl = 24,
    this.durationFast = const Duration(milliseconds: 120),
    this.durationMedium = const Duration(milliseconds: 240),
    this.durationSlow = const Duration(milliseconds: 420),
    this.curveStandard = Curves.easeInOutCubic,
    this.curveEmphasized = Curves.easeOutExpo,
    this.curveExit = Curves.easeInCubic,
    this.contentMaxWidth = 720,
    this.breakpointCompact = 600,
    this.breakpointExpanded = 840,
    this.controlHeight = 44,
    this.borderWidth = 1,
  });

  /// The Prism default token set: a 4-point spacing scale, 8/12/16/24
  /// radii, and a fast/medium/slow motion language.
  static const PrismTokens fallback = PrismTokens();

  /// Extra-small spacing — 4 logical pixels by default.
  final double spaceXs;

  /// Small spacing — 8 by default.
  final double spaceSm;

  /// Medium spacing — 16 by default.
  final double spaceMd;

  /// Large spacing — 24 by default.
  final double spaceLg;

  /// Extra-large spacing — 32 by default.
  final double spaceXl;

  /// Extra-extra-large spacing — 48 by default.
  final double spaceXxl;

  /// Small corner radius — 8 by default.
  final double radiusSm;

  /// Medium corner radius — 12 by default.
  final double radiusMd;

  /// Large corner radius — 16 by default.
  final double radiusLg;

  /// Extra-large corner radius — 24 by default.
  final double radiusXl;

  /// Fast motion — 120 ms by default. Hover, press, tiny fades.
  final Duration durationFast;

  /// Medium motion — 240 ms by default. Enter/exit, reveals.
  final Duration durationMedium;

  /// Slow motion — 420 ms by default. Page transitions, large layout shifts.
  final Duration durationSlow;

  /// Standard easing for symmetric transitions.
  final Curve curveStandard;

  /// Emphasized easing for entrances.
  final Curve curveEmphasized;

  /// Easing used when something leaves the screen.
  final Curve curveExit;

  /// Maximum content width on wide windows before content centres.
  final double contentMaxWidth;

  /// Window width below which the layout is considered "compact" (phone).
  final double breakpointCompact;

  /// Window width at or above which the layout is considered "expanded".
  final double breakpointExpanded;

  /// Standard height for buttons, fields and list rows.
  final double controlHeight;

  /// Hairline border width used for dividers and outlined surfaces.
  final double borderWidth;

  /// Reads the nearest tokens, falling back to [PrismTokens.fallback].
  ///
  /// Never returns null — components can call this without null checks.
  static PrismTokens of(BuildContext context) =>
      Theme.of(context).extension<PrismTokens>() ?? fallback;

  @override
  PrismTokens copyWith({
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? spaceXxl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusXl,
    Duration? durationFast,
    Duration? durationMedium,
    Duration? durationSlow,
    Curve? curveStandard,
    Curve? curveEmphasized,
    Curve? curveExit,
    double? contentMaxWidth,
    double? breakpointCompact,
    double? breakpointExpanded,
    double? controlHeight,
    double? borderWidth,
  }) {
    return PrismTokens(
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
      spaceXxl: spaceXxl ?? this.spaceXxl,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusXl: radiusXl ?? this.radiusXl,
      durationFast: durationFast ?? this.durationFast,
      durationMedium: durationMedium ?? this.durationMedium,
      durationSlow: durationSlow ?? this.durationSlow,
      curveStandard: curveStandard ?? this.curveStandard,
      curveEmphasized: curveEmphasized ?? this.curveEmphasized,
      curveExit: curveExit ?? this.curveExit,
      contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
      breakpointCompact: breakpointCompact ?? this.breakpointCompact,
      breakpointExpanded: breakpointExpanded ?? this.breakpointExpanded,
      controlHeight: controlHeight ?? this.controlHeight,
      borderWidth: borderWidth ?? this.borderWidth,
    );
  }

  @override
  PrismTokens lerp(ThemeExtension<PrismTokens>? other, double t) {
    if (other is! PrismTokens) return this;
    double d(double a, double b) => a + (b - a) * t;
    Duration dur(Duration a, Duration b) => Duration(
      microseconds:
          (a.inMicroseconds + (b.inMicroseconds - a.inMicroseconds) * t)
              .round(),
    );
    return PrismTokens(
      spaceXs: d(spaceXs, other.spaceXs),
      spaceSm: d(spaceSm, other.spaceSm),
      spaceMd: d(spaceMd, other.spaceMd),
      spaceLg: d(spaceLg, other.spaceLg),
      spaceXl: d(spaceXl, other.spaceXl),
      spaceXxl: d(spaceXxl, other.spaceXxl),
      radiusSm: d(radiusSm, other.radiusSm),
      radiusMd: d(radiusMd, other.radiusMd),
      radiusLg: d(radiusLg, other.radiusLg),
      radiusXl: d(radiusXl, other.radiusXl),
      durationFast: dur(durationFast, other.durationFast),
      durationMedium: dur(durationMedium, other.durationMedium),
      durationSlow: dur(durationSlow, other.durationSlow),
      curveStandard: t < 0.5 ? curveStandard : other.curveStandard,
      curveEmphasized: t < 0.5 ? curveEmphasized : other.curveEmphasized,
      curveExit: t < 0.5 ? curveExit : other.curveExit,
      contentMaxWidth: d(contentMaxWidth, other.contentMaxWidth),
      breakpointCompact: d(breakpointCompact, other.breakpointCompact),
      breakpointExpanded: d(breakpointExpanded, other.breakpointExpanded),
      controlHeight: d(controlHeight, other.controlHeight),
      borderWidth: d(borderWidth, other.borderWidth),
    );
  }
}

/// Convenience access to [PrismTokens] straight from a [BuildContext].
///
/// ```dart
/// Padding(padding: EdgeInsets.all(context.prismTokens.spaceMd), child: …)
/// ```
extension PrismTokenContext on BuildContext {
  /// The nearest [PrismTokens], or [PrismTokens.fallback] when none is
  /// registered.
  PrismTokens get prismTokens => PrismTokens.of(this);

  /// The semantic Prism colors for the current [ColorScheme].
  PrismColors get prismColors => PrismColors.of(this);
}
