// Helpers used by Prism's own tests.
//
// These build on `WidgetTester`, so they live here rather than in `lib/`:
// `prism_kit` must not depend on `flutter_test` at runtime, and the pure-Flutter
// part of this convenience (`prismTestApp`) is already public API.
//
// Consumers who want these two functions can copy them verbatim; they are
// thin wrappers over the public `prismTestApp` and `prismTestSizes`.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';
import 'package:prism_kit/testing.dart';

/// Pumps [child] inside a configured Prism environment, sizing the viewport
/// first so width-dependent components take the layout under test.
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

  await tester.pumpWidget(
    prismTestApp(
      child: child,
      tokens: tokens,
      brightness: brightness,
      textDirection: textDirection,
      reduceMotion: reduceMotion,
      theme: theme,
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
