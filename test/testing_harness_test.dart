import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';
import 'package:prism_kit/testing.dart';

import 'support/prism_test_helpers.dart';

/// The harness is itself part of the public API, so it gets its own tests:
/// a broken harness would make every consumer's tests lie.
void main() {
  group('pumpPrism', () {
    testWidgets('installs the design system', (tester) async {
      late PrismTokens resolved;
      await pumpPrism(
        tester,
        Builder(
          builder: (context) {
            resolved = context.prismTokens;
            return const SizedBox.shrink();
          },
        ),
        tokens: const PrismTokens(spaceMd: 42),
      );
      expect(resolved.spaceMd, 42);
    });

    testWidgets('falls back to the default tokens', (tester) async {
      late PrismTokens resolved;
      await pumpPrism(
        tester,
        Builder(
          builder: (context) {
            resolved = context.prismTokens;
            return const SizedBox.shrink();
          },
        ),
      );
      expect(resolved.spaceMd, PrismTokens.fallback.spaceMd);
    });

    testWidgets('gives components a real viewport, not a zero one', (
      tester,
    ) async {
      late Size resolved;
      await pumpPrism(
        tester,
        Builder(
          builder: (context) {
            resolved = MediaQuery.sizeOf(context);
            return const SizedBox.shrink();
          },
        ),
        size: prismTestSizes['phone'],
      );
      expect(resolved, prismTestSizes['phone']);
    });

    testWidgets('honours the requested brightness', (tester) async {
      late Brightness resolved;
      await pumpPrism(
        tester,
        Builder(
          builder: (context) {
            resolved = Theme.of(context).brightness;
            return const SizedBox.shrink();
          },
        ),
        brightness: Brightness.dark,
      );
      expect(resolved, Brightness.dark);
    });

    testWidgets('honours the requested text direction', (tester) async {
      late TextDirection resolved;
      await pumpPrism(
        tester,
        Builder(
          builder: (context) {
            resolved = Directionality.of(context);
            return const SizedBox.shrink();
          },
        ),
        textDirection: TextDirection.rtl,
      );
      expect(resolved, TextDirection.rtl);
    });

    testWidgets('can request reduced motion', (tester) async {
      late bool resolved;
      await pumpPrism(
        tester,
        Builder(
          builder: (context) {
            resolved = context.prismReduceMotion;
            return const SizedBox.shrink();
          },
        ),
        reduceMotion: true,
      );
      expect(resolved, isTrue);
    });
  });

  group('expectNoOverflow', () {
    testWidgets('passes for a well-behaved widget', (tester) async {
      await expectNoOverflow(tester, () => const Text('fine'));
    });

    testWidgets('checks every size in the matrix', (tester) async {
      final seen = <Size>[];
      await expectNoOverflow(
        tester,
        () => Builder(
          builder: (context) {
            seen.add(MediaQuery.sizeOf(context));
            return const SizedBox.shrink();
          },
        ),
      );
      expect(seen, containsAll(prismTestSizes.values));
    });
  });

  group('prismTestApp', () {
    testWidgets('installs the design system and a real viewport', (
      tester,
    ) async {
      late PrismTokens tokens;
      late Size viewport;
      await tester.pumpWidget(
        prismTestApp(
          size: prismTestSizes['phone'],
          tokens: const PrismTokens(spaceMd: 21),
          child: Builder(
            builder: (context) {
              tokens = context.prismTokens;
              viewport = MediaQuery.sizeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(tokens.spaceMd, 21);
      expect(viewport, prismTestSizes['phone']);
    });

    testWidgets('defaults to a viewport that is not zero', (tester) async {
      late Size viewport;
      await tester.pumpWidget(
        prismTestApp(
          child: Builder(
            builder: (context) {
              viewport = MediaQuery.sizeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // The whole point of this helper: a bare MediaQueryData() would be 0x0,
      // which would silently make adaptive components take their compact path.
      expect(viewport.width, greaterThan(0));
      expect(viewport.height, greaterThan(0));
    });

    testWidgets('can request RTL, dark mode and reduced motion', (
      tester,
    ) async {
      late TextDirection direction;
      late Brightness brightness;
      late bool reduceMotion;
      await tester.pumpWidget(
        prismTestApp(
          textDirection: TextDirection.rtl,
          brightness: Brightness.dark,
          reduceMotion: true,
          child: Builder(
            builder: (context) {
              direction = Directionality.of(context);
              brightness = Theme.of(context).brightness;
              reduceMotion = context.prismReduceMotion;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(direction, TextDirection.rtl);
      expect(brightness, Brightness.dark);
      expect(reduceMotion, isTrue);
    });

    testWidgets('the semantics tree is inspectable after a plain pump', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          prismTestApp(child: const PrismAvatar(name: 'Ayesha Khan')),
        );
        expect(find.bySemanticsLabel('Ayesha Khan'), findsOneWidget);
      } finally {
        handle.dispose();
      }
    });
  });

  test('the documented sizes cover compact through expanded', () {
    expect(prismTestSizes.keys, containsAll(['phone', 'tablet', 'desktop']));
    expect(
      prismTestSizes['phone']!.width,
      lessThan(PrismTokens.fallback.breakpointCompact),
    );
    expect(
      prismTestSizes['desktop']!.width,
      greaterThan(PrismTokens.fallback.breakpointExpanded),
    );
  });
}
