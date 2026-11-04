import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:prism_kit/prism.dart';

/// Builds `tokens.json`, the design tokens in a form a design tool or stylesheet
/// can read.
///
/// The point is that a designer working in Figma, or a CSS file that has to match
/// the app, reads the same numbers the components use instead of transcribing
/// them and drifting.
///
/// This lives under `test/` rather than `tool/` for a concrete reason: it imports
/// Flutter, and a plain `dart run` cannot compile Flutter code because `dart:ui`
/// is not available outside the Flutter engine. Running it through `flutter test`
/// is the supported path, and it keeps one regeneration mechanism for the whole
/// package rather than two.
///
/// Regenerate with:
///
/// ```bash
/// PRISM_UPDATE_TOKENS=1 flutter test test/token_export_test.dart
/// ```

/// The seed used for the exported semantic colours.
///
/// Only `error` and `info` derive from the scheme; `success` and `warning` are
/// fixed, so the seed affects two of the four roles. It is stated here rather
/// than left implicit so the export is reproducible.
const exportSeed = Color(0xFF39A9DB);

/// Builds the export.
Map<String, Object?> buildTokenExport() {
  const tokens = PrismTokens.fallback;
  final colors = PrismColors.resolve(
    ColorScheme.fromSeed(seedColor: exportSeed),
    Brightness.light,
  );
  final darkColors = PrismColors.resolve(
    ColorScheme.fromSeed(seedColor: exportSeed, brightness: Brightness.dark),
    Brightness.dark,
  );

  String hex(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  /// Emits 4 rather than 4.0 for whole values, which is what a designer reading
  /// the file expects to see.
  num tidy(double value) =>
      value == value.roundToDouble() ? value.round() : value;

  Map<String, Object?> role(PrismColors palette, PrismSemantic semantic) {
    final pair = palette.forRole(semantic);
    return {
      'accent': hex(palette.accentForRole(semantic)),
      'container': hex(pair.background),
      'onContainer': hex(pair.foreground),
    };
  }

  return {
    r'$comment':
        'Generated. Do not edit by hand; token_export_test.dart fails if this '
            'drifts from PrismTokens. Regenerate with: '
            'PRISM_UPDATE_TOKENS=1 flutter test test/token_export_test.dart',
    'spacing': {
      'spaceXs': tidy(tokens.spaceXs),
      'spaceSm': tidy(tokens.spaceSm),
      'spaceMd': tidy(tokens.spaceMd),
      'spaceLg': tidy(tokens.spaceLg),
      'spaceXl': tidy(tokens.spaceXl),
      'spaceXxl': tidy(tokens.spaceXxl),
    },
    'radius': {
      'radiusSm': tidy(tokens.radiusSm),
      'radiusMd': tidy(tokens.radiusMd),
      'radiusLg': tidy(tokens.radiusLg),
      'radiusXl': tidy(tokens.radiusXl),
    },
    'motion': {
      'durationFast': tokens.durationFast.inMilliseconds,
      'durationMedium': tokens.durationMedium.inMilliseconds,
      'durationSlow': tokens.durationSlow.inMilliseconds,
    },
    'breakpoints': {
      'compact': tidy(tokens.breakpointCompact),
      'expanded': tidy(tokens.breakpointExpanded),
    },
    'controlHeight': tidy(tokens.controlHeight),
    'contentMaxWidth': tidy(tokens.contentMaxWidth),
    'semantic': {
      'light': {
        for (final semantic in PrismSemantic.values)
          semantic.name: role(colors, semantic),
      },
      'dark': {
        for (final semantic in PrismSemantic.values)
          semantic.name: role(darkColors, semantic),
      },
    },
  };
}

/// The export as formatted JSON, with a trailing newline.
String encodeTokenExport() =>
    '${const JsonEncoder.withIndent('  ').convert(buildTokenExport())}\n';
