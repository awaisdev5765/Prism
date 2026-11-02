import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('renders nothing when disabled', (tester) async {
    await tester.pumpWidget(host(const PrismDebugOverlay(child: Text('app'))));

    expect(find.text('app'), findsOneWidget);
    expect(find.text('Prism tokens'), findsNothing);
  });

  testWidgets('shows a collapsed badge when enabled', (tester) async {
    await tester.pumpWidget(
      host(const PrismDebugOverlay(enabled: true, child: Text('app'))),
    );

    expect(find.text('app'), findsOneWidget);
    expect(find.text('Prism tokens'), findsOneWidget);
    // Collapsed: no token rows yet.
    expect(find.text('spaceMd'), findsNothing);
  });

  testWidgets('expands to show the active tokens', (tester) async {
    await tester.pumpWidget(
      host(const PrismDebugOverlay(enabled: true, child: Text('app'))),
    );

    await tester.tap(find.text('Prism tokens'));
    await tester.pumpAndSettle();

    expect(find.text('spaceMd'), findsOneWidget);
    expect(find.text('radiusMd'), findsOneWidget);
    expect(find.text('durationMedium'), findsOneWidget);
    expect(find.text('window class'), findsOneWidget);
    expect(find.text('reduce motion'), findsOneWidget);
  });

  testWidgets('reports the tokens actually registered', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: prismTheme(tokens: const PrismTokens(spaceMd: 37)),
        home: const Scaffold(
          body: PrismDebugOverlay(
            enabled: true,
            initiallyExpanded: true,
            child: Text('app'),
          ),
        ),
      ),
    );

    // The overlay must read the live tokens, not the defaults: that is the
    // whole point of the panel.
    expect(find.text('37'), findsOneWidget);
  });

  testWidgets('reports reduced motion', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: const Scaffold(
              body: PrismDebugOverlay(
                enabled: true,
                initiallyExpanded: true,
                child: Text('app'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('yes'), findsOneWidget);
  });

  testWidgets('collapses again on a second tap', (tester) async {
    await tester.pumpWidget(
      host(const PrismDebugOverlay(enabled: true, child: Text('app'))),
    );

    await tester.tap(find.text('Prism tokens'));
    await tester.pumpAndSettle();
    expect(find.text('spaceMd'), findsOneWidget);

    await tester.tap(find.text('Prism'));
    await tester.pumpAndSettle();
    expect(find.text('spaceMd'), findsNothing);
  });

  testWidgets('shows the semantic role swatches when expanded', (tester) async {
    await tester.pumpWidget(
      host(
        const PrismDebugOverlay(
          enabled: true,
          initiallyExpanded: true,
          child: Text('app'),
        ),
      ),
    );

    for (final role in PrismSemantic.values) {
      expect(find.text(role.name), findsOneWidget, reason: role.name);
    }
  });
}
