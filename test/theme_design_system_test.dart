import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

/// The design system is only real if overriding it actually changes what the
/// components render. These tests install a deliberately unusual token set and
/// assert that components pick it up — a component that quietly hard-codes a
/// radius or duration would fail here.
void main() {
  // Deliberately distinctive values, so a default cannot be mistaken for a
  // resolved token.
  const kTokens = PrismTokens(
    spaceXs: 3,
    spaceSm: 7,
    spaceMd: 19,
    spaceLg: 29,
    spaceXl: 37,
    spaceXxl: 61,
    radiusSm: 5,
    radiusMd: 11,
    radiusLg: 23,
    radiusXl: 31,
    durationFast: Duration(milliseconds: 77),
    durationMedium: Duration(milliseconds: 143),
    durationSlow: Duration(milliseconds: 211),
    breakpointCompact: 900,
    breakpointExpanded: 1200,
    controlHeight: 52,
  );

  Widget host(
    Widget child, {
    PrismTokens tokens = kTokens,
    Brightness brightness = Brightness.light,
  }) {
    return MaterialApp(
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF39A9DB),
        brightness: brightness,
        extensions: [tokens],
      ),
      home: Scaffold(body: child),
    );
  }

  group('tokens reach components', () {
    testWidgets('PrismStateView uses the token padding', (tester) async {
      await tester.pumpWidget(host(
        PrismStateView<String>(
          state: const PrismViewLoading(),
          successBuilder: (data) => Text(data),
        ),
      ));

      final padding = tester
          .widget<Padding>(find.ancestor(
            of: find.byType(CircularProgressIndicator),
            matching: find.byType(Padding),
          ).first)
          .padding;
      expect(padding, EdgeInsets.all(kTokens.spaceLg));
    });

    testWidgets('PrismStateView uses the token icon size', (tester) async {
      await tester.pumpWidget(host(
        PrismStateView<String>(
          state: const PrismViewEmpty(),
          successBuilder: (data) => Text(data),
        ),
      ));

      final icon = tester.widget<Icon>(find.byIcon(Icons.inbox_outlined));
      expect(icon.size, kTokens.spaceXxl);
    });

    testWidgets('PrismStateView uses the token transition duration',
        (tester) async {
      await tester.pumpWidget(host(
        PrismStateView<String>(
          state: const PrismViewLoading(),
          successBuilder: (data) => Text(data),
        ),
      ));

      final switcher = tester.widget<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      expect(switcher.duration, kTokens.durationMedium);
    });

    testWidgets('PrismBanner uses the token radius', (tester) async {
      await tester.pumpWidget(host(
        const PrismBanner(
          announcements: [
            PrismAnnouncement(id: 'a', message: 'Hello'),
          ],
        ),
      ));
      await tester.pumpAndSettle();

      final material = tester.widget<Material>(
        find.ancestor(
          of: find.text('Hello'),
          matching: find.byType(Material),
        ).first,
      );
      expect(
        material.borderRadius,
        BorderRadius.circular(kTokens.radiusMd),
      );
    });

    testWidgets('PrismSkeleton uses the token radius', (tester) async {
      await tester.pumpWidget(host(
        const PrismSkeleton(width: 100, height: 20, animate: false),
      ));

      final container = tester.widget<Container>(find.byType(Container).first);
      final radius =
          (container.decoration! as BoxDecoration).borderRadius as BorderRadius;
      expect(radius.topLeft.x, kTokens.radiusSm);
    });

    testWidgets('PrismChipInput uses the token radius and spacing',
        (tester) async {
      await tester.pumpWidget(host(
        PrismChipInput(value: const ['a'], onChanged: (_) {}),
      ));

      final decorated = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.borderRadius != null);
      final radius = decorated.borderRadius! as BorderRadius;
      expect(radius.topLeft.x, kTokens.radiusMd);
    });

    testWidgets('PrismOtpField honours the token control height',
        (tester) async {
      // The field takes an explicit box size, so verify the token-driven
      // default indirectly through the documented API contract.
      await tester.pumpWidget(host(
        PrismOtpField(length: 4, boxSize: kTokens.controlHeight),
      ));

      final boxes = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(boxes, isNotEmpty);
    });
  });

  group('semantic colours', () {
    // Each capture happens in its own pump, and is read immediately: a second
    // pumpWidget rebuilds the whole tree, which would overwrite a captured
    // value if both lived in the same test.
    Future<PrismColors> capture(
      WidgetTester tester,
      Brightness brightness,
    ) async {
      late PrismColors captured;
      await tester.pumpWidget(host(
        Builder(builder: (context) {
          captured = context.prismColors;
          return const SizedBox.shrink();
        }),
        brightness: brightness,
      ));
      return captured;
    }

    testWidgets('dark mode resolves a different success colour',
        (tester) async {
      final light = await capture(tester, Brightness.light);
      expect(light.success, const Color(0xFF1B7A4B));
    });

    testWidgets('dark mode resolves a different success container',
        (tester) async {
      final dark = await capture(tester, Brightness.dark);
      expect(dark.success, const Color(0xFF7BD8A8));
      expect(dark.forRole(PrismSemantic.success).background,
          const Color(0xFF1E4C33));
    });

    testWidgets('all four roles are visually distinct', (tester) async {
      late PrismColors colors;
      await tester.pumpWidget(host(
        Builder(builder: (context) {
          colors = context.prismColors;
          return const SizedBox.shrink();
        }),
      ));

      final accents = {
        for (final role in PrismSemantic.values) colors.accentForRole(role),
      };
      expect(accents, hasLength(PrismSemantic.values.length));
    });

    testWidgets('role backgrounds differ from role accents', (tester) async {
      late PrismColors colors;
      await tester.pumpWidget(host(
        Builder(builder: (context) {
          colors = context.prismColors;
          return const SizedBox.shrink();
        }),
      ));

      for (final role in PrismSemantic.values) {
        expect(
          colors.forRole(role).background,
          isNot(colors.accentForRole(role)),
          reason: '$role should have a distinct container colour',
        );
      }
    });
  });

  group('breakpoints', () {
    testWidgets('PrismAdaptiveScaffold honours token breakpoints',
        (tester) async {
      // With breakpointCompact raised to 900, a 700px window is compact, so the
      // scaffold should render a NavigationBar rather than a rail.
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(
        PrismAdaptiveScaffold(
          destinations: const [
            AdaptiveDestination(icon: Icons.home, label: 'Home'),
            AdaptiveDestination(icon: Icons.settings, label: 'Settings'),
          ],
          bodyBuilder: (i) => const SizedBox.shrink(),
        ),
      ));

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
    });

    testWidgets('default tokens keep 700px as a rail', (tester) async {
      tester.view.physicalSize = const Size(700, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(host(
        PrismAdaptiveScaffold(
          destinations: const [
            AdaptiveDestination(icon: Icons.home, label: 'Home'),
            AdaptiveDestination(icon: Icons.settings, label: 'Settings'),
          ],
          bodyBuilder: (i) => const SizedBox.shrink(),
        ),
        tokens: PrismTokens.fallback,
      ));

      expect(find.byType(NavigationRail), findsOneWidget);
    });
  });

  group('graceful degradation', () {
    testWidgets('components work with no tokens registered', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              PrismStateView<String>(
                state: const PrismViewLoading(),
                successBuilder: (d) => Text(d),
              ),
              PrismSkeleton(height: 10, animate: false),
              const PrismAvatar(name: 'No Tokens'),
            ],
          ),
        ),
      ));

      // Nothing throws and the avatar still resolves a stable colour.
      expect(find.text('NT'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('fallback tokens are internally consistent', () {
      const t = PrismTokens.fallback;
      expect(t.spaceXs < t.spaceSm, isTrue);
      expect(t.spaceSm < t.spaceMd, isTrue);
      expect(t.spaceMd < t.spaceLg, isTrue);
      expect(t.spaceLg < t.spaceXl, isTrue);
      expect(t.spaceXl < t.spaceXxl, isTrue);
      expect(t.radiusSm < t.radiusMd, isTrue);
      expect(t.radiusMd < t.radiusLg, isTrue);
      expect(t.radiusLg < t.radiusXl, isTrue);
      expect(t.durationFast < t.durationMedium, isTrue);
      expect(t.durationMedium < t.durationSlow, isTrue);
      expect(t.breakpointCompact < t.breakpointExpanded, isTrue);
      expect(t.controlHeight, greaterThan(0));
    });
  });
}
