import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

void main() {
  group('presets compose three orthogonal choices', () {
    test('density alone changes spacing and control height', () {
      final compact = PrismTokenPresets.preset(density: PrismDensity.compact);
      final comfortable = PrismTokenPresets.preset(
        density: PrismDensity.comfortable,
      );
      final spacious = PrismTokenPresets.preset(density: PrismDensity.spacious);

      expect(compact.spaceMd, lessThan(comfortable.spaceMd));
      expect(comfortable.spaceMd, lessThan(spacious.spaceMd));
      expect(compact.controlHeight, lessThan(comfortable.controlHeight));
      expect(comfortable.controlHeight, lessThan(spacious.controlHeight));
    });

    test('shape alone changes radii without touching spacing', () {
      final sharp = PrismTokenPresets.preset(shape: PrismShape.sharp);
      final rounded = PrismTokenPresets.preset(shape: PrismShape.rounded);
      final pill = PrismTokenPresets.preset(shape: PrismShape.pill);

      expect(sharp.radiusMd, lessThan(rounded.radiusMd));
      expect(rounded.radiusMd, lessThan(pill.radiusLg));
      expect(sharp.spaceMd, rounded.spaceMd);
      expect(rounded.spaceMd, pill.spaceMd);
    });

    test('motion alone changes durations without touching spacing', () {
      final brisk = PrismTokenPresets.preset(motion: PrismMotion.brisk);
      final standard = PrismTokenPresets.preset(motion: PrismMotion.standard);
      final relaxed = PrismTokenPresets.preset(motion: PrismMotion.relaxed);

      expect(
        brisk.durationMedium.inMilliseconds,
        lessThan(standard.durationMedium.inMilliseconds),
      );
      expect(
        standard.durationMedium.inMilliseconds,
        lessThan(relaxed.durationMedium.inMilliseconds),
      );
      expect(brisk.spaceMd, relaxed.spaceMd);
    });

    test('every preset keeps the scale monotonic', () {
      for (final density in PrismDensity.values) {
        for (final shape in PrismShape.values) {
          for (final motion in PrismMotion.values) {
            final t = PrismTokenPresets.preset(
              density: density,
              shape: shape,
              motion: motion,
            );
            final reason = '$density/$shape/$motion';
            expect(t.spaceXs < t.spaceSm, isTrue, reason: reason);
            expect(t.spaceSm < t.spaceMd, isTrue, reason: reason);
            expect(t.spaceMd < t.spaceLg, isTrue, reason: reason);
            expect(t.spaceLg < t.spaceXl, isTrue, reason: reason);
            expect(t.spaceXl < t.spaceXxl, isTrue, reason: reason);
            expect(t.radiusSm <= t.radiusMd, isTrue, reason: reason);
            expect(t.radiusMd <= t.radiusLg, isTrue, reason: reason);
            expect(t.radiusLg <= t.radiusXl, isTrue, reason: reason);
            expect(t.durationFast < t.durationMedium, isTrue, reason: reason);
            expect(t.durationMedium < t.durationSlow, isTrue, reason: reason);
          }
        }
      }
    });

    test('named presets match their described personality', () {
      expect(PrismTokenPresets.technical.radiusMd, lessThan(8));
      expect(PrismTokenPresets.technical.controlHeight, lessThan(44));
      expect(PrismTokenPresets.friendly.radiusLg, greaterThan(20));
      expect(PrismTokenPresets.editorial.spaceMd, greaterThan(20));
      expect(
        PrismTokenPresets.editorial.durationMedium,
        greaterThan(const Duration(milliseconds: 300)),
      );
    });
  });

  group('prismTheme', () {
    testWidgets('registers tokens and a seeded scheme', (tester) async {
      late PrismTokens tokens;
      late ColorScheme scheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: prismTheme(seed: const Color(0xFF6A1B9A)),
          home: Builder(
            builder: (context) {
              tokens = context.prismTokens;
              scheme = Theme.of(context).colorScheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(tokens.spaceMd, PrismTokens.fallback.spaceMd);
      expect(scheme.brightness, Brightness.light);
      expect(scheme.primary, isNot(Colors.blue));
    });

    testWidgets('honours brightness', (tester) async {
      late Brightness brightness;
      await tester.pumpWidget(
        MaterialApp(
          theme: prismTheme(brightness: Brightness.dark),
          home: Builder(
            builder: (context) {
              brightness = Theme.of(context).brightness;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(brightness, Brightness.dark);
    });

    testWidgets('a preset changes what components render', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: prismTheme(
            density: PrismDensity.compact,
            shape: PrismShape.sharp,
          ),
          home: const Scaffold(
            body: PrismSkeleton(width: 100, height: 20, animate: false),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final radius =
          (container.decoration! as BoxDecoration).borderRadius as BorderRadius;
      expect(
        radius.topLeft.x,
        PrismTokenPresets.preset(shape: PrismShape.sharp).radiusSm,
      );
    });

    testWidgets('an explicit token set wins over the preset', (tester) async {
      late PrismTokens tokens;
      await tester.pumpWidget(
        MaterialApp(
          theme: prismTheme(
            density: PrismDensity.spacious,
            tokens: const PrismTokens(spaceMd: 7),
          ),
          home: Builder(
            builder: (context) {
              tokens = context.prismTokens;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(tokens.spaceMd, 7);
    });

    testWidgets('extends a base theme rather than replacing it', (
      tester,
    ) async {
      late ThemeData theme;
      await tester.pumpWidget(
        MaterialApp(
          theme: prismTheme(
            base: ThemeData(
              colorSchemeSeed: const Color(0xFF39A9DB),
              useMaterial3: true,
            ),
          ),
          home: Builder(
            builder: (context) {
              theme = Theme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(theme.extensions.values.whereType<PrismTokens>(), hasLength(1));
      expect(theme.useMaterial3, isTrue);
    });

    testWidgets('never registers two token sets', (tester) async {
      // Rebuilding with a different preset must replace, not accumulate.
      await tester.pumpWidget(
        MaterialApp(
          theme: prismTheme(density: PrismDensity.compact),
          home: const SizedBox.shrink(),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: prismTheme(density: PrismDensity.spacious),
          home: Builder(
            builder: (context) {
              expect(
                Theme.of(context).extensions.values.whereType<PrismTokens>(),
                hasLength(1),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });
}
