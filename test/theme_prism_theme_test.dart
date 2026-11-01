import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

void main() {
  final scheme = ColorScheme.fromSeed(seedColor: const Color(0xFF39A9DB));

  group('PrismTokens', () {
    test('fallback exposes a coherent 4-point scale', () {
      const t = PrismTokens.fallback;
      expect(t.spaceXs, 4);
      expect(t.spaceSm, 8);
      expect(t.spaceMd, 16);
      expect(t.spaceLg, 24);
      expect(t.spaceXl, 32);
      expect(t.spaceXxl, 48);
      expect(t.spaceXs < t.spaceSm, isTrue);
      expect(t.spaceSm < t.spaceMd, isTrue);
      expect(t.spaceMd < t.spaceLg, isTrue);
      expect(t.spaceLg < t.spaceXl, isTrue);
      expect(t.spaceXl < t.spaceXxl, isTrue);
    });

    test('radii and durations increase monotonically', () {
      const t = PrismTokens.fallback;
      expect(t.radiusSm < t.radiusMd, isTrue);
      expect(t.radiusMd < t.radiusLg, isTrue);
      expect(t.radiusLg < t.radiusXl, isTrue);
      expect(t.durationFast < t.durationMedium, isTrue);
      expect(t.durationMedium < t.durationSlow, isTrue);
    });

    test('copyWith overrides only the named field', () {
      const base = PrismTokens.fallback;
      final changed = base.copyWith(spaceMd: 20, radiusLg: 30);
      expect(changed.spaceMd, 20);
      expect(changed.radiusLg, 30);
      expect(changed.spaceSm, base.spaceSm);
      expect(changed.curveStandard, base.curveStandard);
    });

    test('lerp interpolates between two token sets', () {
      const a = PrismTokens.fallback;
      final b = a.copyWith(spaceMd: 32, durationMedium: const Duration(milliseconds: 500));
      final mid = a.lerp(b, 0.5);
      expect(mid.spaceMd, closeTo(24, 0.001));
      expect(mid.durationMedium.inMicroseconds, closeTo(
        (a.durationMedium.inMicroseconds + 500000) / 2,
        1000,
      ));
    });

    test('lerp with a foreign extension returns itself', () {
      const a = PrismTokens.fallback;
      expect(a.lerp(null, 0.5).spaceMd, a.spaceMd);
    });

    testWidgets('of() falls back when no tokens are registered', (tester) async {
      late PrismTokens resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              resolved = context.prismTokens;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved.spaceMd, PrismTokens.fallback.spaceMd);
    });

    testWidgets('of() reads registered tokens', (tester) async {
      late PrismTokens resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [PrismTokens(spaceMd: 20, radiusMd: 4)],
          ),
          home: Builder(
            builder: (context) {
              resolved = context.prismTokens;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(resolved.spaceMd, 20);
      expect(resolved.radiusMd, 4);
    });
  });

  group('PrismColors', () {
    test('exposes distinct success/warning/error/info roles', () {
      final colors = PrismColors.resolve(scheme, Brightness.light);
      final accents = {
        colors.success,
        colors.warning,
        colors.error,
        colors.info,
      };
      expect(accents.length, 4, reason: 'each role should be visually distinct');
    });

    test('forRole returns matching container pairs', () {
      final colors = PrismColors.resolve(scheme, Brightness.light);
      expect(
        colors.forRole(PrismSemantic.success).background,
        colors.successContainer,
      );
      expect(
        colors.forRole(PrismSemantic.error).foreground,
        colors.onErrorContainer,
      );
    });

    test('accentForRole maps every role', () {
      final colors = PrismColors.resolve(scheme, Brightness.dark);
      for (final role in PrismSemantic.values) {
        expect(colors.accentForRole(role), isNotNull);
        expect(colors.iconForRole(role), isNotNull);
      }
    });

    test('semantic roles carry default icons', () {
      final colors = PrismColors.resolve(scheme, Brightness.light);
      expect(colors.iconForRole(PrismSemantic.success), Icons.check_circle_outline);
      expect(colors.iconForRole(PrismSemantic.error), Icons.error_outline);
    });

    test('dark mode differs from light mode', () {
      final light = PrismColors.resolve(scheme, Brightness.light);
      final dark = PrismColors.resolve(scheme, Brightness.dark);
      expect(light.success, isNot(dark.success));
      expect(light.onSuccessContainer, isNot(dark.onSuccessContainer));
    });

    test('equality and hashCode follow values', () {
      final a = PrismColors.resolve(scheme, Brightness.light);
      final b = PrismColors.resolve(scheme, Brightness.light);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    testWidgets('context.prismColors resolves from the theme', (tester) async {
      late PrismColors colors;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: scheme),
          home: Builder(
            builder: (context) {
              colors = context.prismColors;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(colors.info, scheme.primary);
    });
  });
}
