import 'package:flutter/material.dart';

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

/// Wraps [child] in a fully configured Prism environment, ready to pump.
///
/// Writing this by hand in every test is how people accidentally test the wrong
/// thing. The subtle detail is the viewport: a bare `MediaQueryData()` reports a
/// **zero** size, so an adaptive component silently falls into its compact
/// layout and the test passes while asserting nothing.
///
/// ```dart
/// testWidgets('my screen shows the empty state', (tester) async {
///   await tester.pumpWidget(
///     prismTestApp(child: const MyScreen(), size: const Size(320, 568)),
///   );
///   expect(find.text('Nothing here yet'), findsOneWidget);
/// });
/// ```
///
/// Pump through `tester.pumpWidget` rather than a helper: this library stays
/// free of `flutter_test` so that `prism_kit` has no test-only runtime
/// dependency, and a single `pumpWidget` call is all the convenience that
/// actually buys you.
///
/// Combine with [prismTestSizes] to check a widget at every window class:
///
/// ```dart
/// for (final entry in prismTestSizes.entries) {
///   await tester.pumpWidget(prismTestApp(child: card, size: entry.value));
///   await tester.pump();
///   expect(tester.takeException(), isNull, reason: entry.key);
/// }
/// ```
Widget prismTestApp({
  required Widget child,
  PrismTokens? tokens,
  Brightness brightness = Brightness.light,
  Size? size,
  TextDirection textDirection = TextDirection.ltr,
  bool reduceMotion = false,
  ThemeData? theme,
}) {
  final base =
      theme ??
      ThemeData(
        colorSchemeSeed: const Color(0xFF39A9DB),
        brightness: brightness,
      );

  final app = MaterialApp(
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
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: Directionality(
          textDirection: textDirection,
          child: Scaffold(body: child),
        ),
      ),
    ),
  );

  if (size == null) return app;

  // Pin the viewport without touching the test binding, so the same helper
  // works from a plain widget test and from a preview.
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: app,
  );
}
