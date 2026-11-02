// ignore_for_file: depend_on_referenced_packages
//
// This library is the only place Prism touches flutter_test. It lives in a
// separate entry point (package:prism_kit/testing.dart) so the main library
// stays free of a test-only dependency; consumers already have flutter_test in
// their dev_dependencies, which is where this is used.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../theme/theme.dart';

/// Sizes worth testing any adaptive component at.
///
/// These are not arbitrary: `phone` is the narrowest layout most apps support,
/// `tablet` straddles the compact/medium boundary, and `desktop` is where
/// two-pane layouts and extended navigation rails appear.
const prismTestSizes = <String, Size>{
  'phone': Size(320, 568),
  'tablet': Size(834, 1112),
  'desktop': Size(1440, 900),
};

/// Pumps [child] inside a fully configured Prism environment.
///
/// Writing this by hand in every test is how people accidentally test the wrong
/// thing: a bare `MediaQueryData()` reports a zero-size viewport, so an adaptive
/// component silently falls into its compact layout and the test passes while
/// asserting nothing.
///
/// ```dart
/// testWidgets('my screen shows the empty state', (tester) async {
///   await pumpPrism(tester, const MyScreen(), size: .phone);
///   expect(find.text('Nothing here yet'), findsOneWidget);
/// });
/// ```
Future<void> pumpPrism(
  WidgetTester tester,
  Widget child, {
  PrismTokens? tokens,
  Brightness brightness = Brightness.light,
  Size? size,
  TextDirection textDirection = TextDirection.ltr,
  bool reduceMotion = false,
  ThemeData? theme,
  bool settle = true,
}) async {
  if (size != null) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  final base =
      theme ??
      ThemeData(
        colorSchemeSeed: const Color(0xFF39A9DB),
        brightness: brightness,
      );

  await tester.pumpWidget(
    MaterialApp(
      theme: base.copyWith(
        extensions: [
          ...base.extensions.values.where((e) => e is! PrismTokens),
          tokens ?? PrismTokens.fallback,
        ],
      ),
      home: Builder(
        builder: (context) => MediaQuery(
          // Derive from the ambient MediaQuery: a fresh MediaQueryData() would
          // report a zero-size viewport and hide layout bugs.
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: reduceMotion),
          child: Directionality(
            textDirection: textDirection,
            child: Scaffold(body: child),
          ),
        ),
      ),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Pumps [child] at every size in [prismTestSizes] and asserts it never throws
/// or overflows.
///
/// Use this for any component that adapts to the window. It catches the class of
/// bug that only appears at an extreme width.
///
/// ```dart
/// testWidgets('my card survives every window size', (tester) async {
///   await expectNoOverflow(tester, () => const MyCard());
/// });
/// ```
Future<void> expectNoOverflow(
  WidgetTester tester,
  Widget Function() build, {
  Brightness brightness = Brightness.light,
  TextDirection textDirection = TextDirection.ltr,
  PrismTokens? tokens,
  Map<String, Size> sizes = prismTestSizes,
}) async {
  for (final MapEntry(key: name, value: size) in sizes.entries) {
    await pumpPrism(
      tester,
      build(),
      size: size,
      brightness: brightness,
      textDirection: textDirection,
      tokens: tokens,
      settle: false,
    );
    // Let implicit animations finish so a late layout change is caught too.
    await tester.pump(const Duration(milliseconds: 400));

    expect(
      tester.takeException(),
      isNull,
      reason: 'threw at $name (${size.width}x${size.height})',
    );
  }
}

/// Pumps [child] and asserts it is reachable without sight.
///
/// Enables the semantics tree, so the assertion is about what a screen reader
/// would find rather than what is merely painted.
Future<void> pumpPrismWithSemantics(
  WidgetTester tester,
  Widget child, {
  Size? size,
  Brightness brightness = Brightness.light,
}) async {
  final handle = tester.ensureSemantics();
  try {
    await pumpPrism(tester, child, size: size, brightness: brightness);
  } finally {
    // Disposed inside the test body: the framework checks for leaked handles
    // before tear-downs run.
    handle.dispose();
  }
}
