import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

/// WCAG contrast is a real accessibility requirement, not a nicety: text below
/// 4.5:1 is unreadable for a large share of users in bright light or with low
/// vision. These tests hold the semantic palette to that bar in both
/// brightnesses, for a range of brand seeds so a dynamic-colour app cannot
/// produce unreadable Prism components.
///
/// Ratios follow WCAG 2.1: (L1 + 0.05) / (L2 + 0.05) with relative luminance.
double _luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  final lighter = math.max(la, lb);
  final darker = math.min(la, lb);
  return (lighter + 0.05) / (darker + 0.05);
}

/// A spread of seeds, including deliberately awkward hues, so the palette is
/// tested against real brand colours rather than one convenient blue.
const _seeds = <String, Color>{
  'blue': Color(0xFF39A9DB),
  'teal': Color(0xFF00897B),
  'green': Color(0xFF2E7D32),
  'amber': Color(0xFFFFA000),
  'orange': Color(0xFFE65100),
  'red': Color(0xFFC62828),
  'purple': Color(0xFF6A1B9A),
  'pink': Color(0xFFD81B60),
  'grey': Color(0xFF546E7A),
  'near-black': Color(0xFF111111),
};

/// Body text needs 4.5:1; large text and UI boundaries need 3:1.
const _aaText = 4.5;
const _aaLarge = 3.0;

void main() {
  group('containers meet AA against their foreground', () {
    for (final brightness in Brightness.values) {
      for (final MapEntry(key: name, value: seed) in _seeds.entries) {
        test('$name / ${brightness.name}', () {
          final scheme = ColorScheme.fromSeed(
            seedColor: seed,
            brightness: brightness,
          );
          final colors = PrismColors.resolve(scheme, brightness);

          for (final role in PrismSemantic.values) {
            final pair = colors.forRole(role);
            final ratio = _contrast(pair.background, pair.foreground);
            expect(
              ratio,
              greaterThanOrEqualTo(_aaText),
              reason:
                  '$role foreground on its container is only '
                  '${ratio.toStringAsFixed(2)}:1 (need $_aaText:1)',
            );
          }
        });
      }
    }
  });

  group('solid accents are readable as icon or large-text colour', () {
    for (final brightness in Brightness.values) {
      for (final MapEntry(key: name, value: seed) in _seeds.entries) {
        test('$name / ${brightness.name}', () {
          final scheme = ColorScheme.fromSeed(
            seedColor: seed,
            brightness: brightness,
          );
          final colors = PrismColors.resolve(scheme, brightness);

          for (final role in PrismSemantic.values) {
            final accent = colors.accentForRole(role);
            final surface = scheme.surface;
            final ratio = _contrast(accent, surface);
            expect(
              ratio,
              greaterThanOrEqualTo(_aaLarge),
              reason:
                  '$role accent on the base surface is only '
                  '${ratio.toStringAsFixed(2)}:1 (need $_aaLarge:1)',
            );
          }
        });
      }
    }
  });

  group('the roles stay distinct enough to tell apart', () {
    for (final brightness in Brightness.values) {
      test(brightness.name, () {
        final scheme = ColorScheme.fromSeed(
          seedColor: const Color(0xFF39A9DB),
          brightness: brightness,
        );
        final colors = PrismColors.resolve(scheme, brightness);

        // Success and warning must not collapse into each other; a diff of a
        // few RGB steps reads as "the same colour" at a glance.
        final success = colors.accentForRole(PrismSemantic.success);
        final warning = colors.accentForRole(PrismSemantic.warning);
        final error = colors.accentForRole(PrismSemantic.error);

        double channelDistance(Color a, Color b) =>
            ((a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs()) / 3;

        expect(
          channelDistance(success, warning),
          greaterThan(0.15),
          reason: 'success and warning are too close to distinguish',
        );
        expect(
          channelDistance(success, error),
          greaterThan(0.1),
          reason: 'success and error are too close to distinguish',
        );
        expect(
          channelDistance(warning, error),
          greaterThan(0.1),
          reason: 'warning and error are too close to distinguish',
        );
      });
    }
  });

  test('the contrast helper itself is correct', () {
    // Sanity-check the maths against the two extremes WCAG defines.
    expect(
      _contrast(const Color(0xFF000000), const Color(0xFFFFFFFF)),
      closeTo(21, 0.01),
    );
    expect(
      _contrast(const Color(0xFF777777), const Color(0xFF777777)),
      closeTo(1, 0.01),
    );
  });
}
