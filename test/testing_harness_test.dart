import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';
import 'package:prism_kit/testing.dart';

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

  group('pumpPrismWithSemantics', () {
    testWidgets('enables the semantics tree', (tester) async {
      await pumpPrismWithSemantics(
        tester,
        const PrismAvatar(name: 'Ayesha Khan'),
      );
      expect(find.bySemanticsLabel('Ayesha Khan'), findsOneWidget);
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
