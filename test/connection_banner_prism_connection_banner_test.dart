import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('stays hidden while online', (tester) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      host(
        PrismConnectionBanner(
          source: () => controller.stream,
          settleDelay: Duration.zero,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('offline'), findsNothing);
  });

  testWidgets('shows the offline message when the source emits false', (
    tester,
  ) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      host(
        PrismConnectionBanner(
          source: () => controller.stream,
          settleDelay: Duration.zero,
          offlineMessage: 'No connection',
        ),
      ),
    );
    controller.add(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('No connection'), findsOneWidget);
  });

  testWidgets('brief blips are dampened by the settle delay', (tester) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      host(
        PrismConnectionBanner(
          source: () => controller.stream,
          settleDelay: const Duration(seconds: 1),
          offlineMessage: 'Offline now',
        ),
      ),
    );
    controller.add(false);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Offline now'), findsNothing);

    // Reconnect before the delay elapses — banner never appears.
    controller.add(true);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Offline now'), findsNothing);
  });

  testWidgets('hides again when the connection returns', (tester) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      host(
        PrismConnectionBanner(
          source: () => controller.stream,
          settleDelay: Duration.zero,
          offlineMessage: 'Offline now',
        ),
      ),
    );
    controller.add(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Offline now'), findsOneWidget);

    controller.add(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Offline now'), findsNothing);
  });

  testWidgets('shows the reconnected message briefly', (tester) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      host(
        PrismConnectionBanner(
          source: () => controller.stream,
          settleDelay: Duration.zero,
          onlineMessage: 'Back online',
          onlineDuration: const Duration(milliseconds: 300),
        ),
      ),
    );
    controller.add(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    controller.add(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Back online'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Back online'), findsNothing);
  });

  testWidgets('renders a retry action when provided', (tester) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);
    var retries = 0;

    await tester.pumpWidget(
      host(
        PrismConnectionBanner(
          source: () => controller.stream,
          settleDelay: Duration.zero,
          onRetry: () => retries++,
        ),
      ),
    );
    controller.add(false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('omits the retry action without a callback', (tester) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      host(
        PrismConnectionBanner(
          source: () => controller.stream,
          settleDelay: Duration.zero,
        ),
      ),
    );
    controller.add(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('assumeOnline false starts in the offline state', (tester) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      host(
        PrismConnectionBanner(
          source: () => controller.stream,
          settleDelay: Duration.zero,
          assumeOnline: false,
          offlineMessage: 'Starting offline',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Starting offline'), findsOneWidget);
  });

  testWidgets('switching source re-subscribes', (tester) async {
    final first = StreamController<bool>();
    final second = StreamController<bool>();
    addTearDown(first.close);
    addTearDown(second.close);

    await tester.pumpWidget(
      host(
        PrismConnectionBanner(
          source: () => first.stream,
          settleDelay: Duration.zero,
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      host(
        PrismConnectionBanner(
          source: () => second.stream,
          settleDelay: Duration.zero,
          offlineMessage: 'Second source',
        ),
      ),
    );
    second.add(false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Second source'), findsOneWidget);
  });

  testWidgets('announces connectivity changes to assistive tech', (
    tester,
  ) async {
    final controller = StreamController<bool>();
    addTearDown(controller.close);

    await tester.pumpWidget(
      host(
        PrismConnectionBanner(
          source: () => controller.stream,
          settleDelay: Duration.zero,
          offlineMessage: 'You are offline',
        ),
      ),
    );
    controller.add(false);
    await tester.pumpAndSettle();

    // A live-region Semantics node carries the message so screen readers
    // announce the connectivity change without interrupting the user.
    final labelled = tester
        .widgetList<Semantics>(find.byType(Semantics))
        .where((s) => s.properties.label == 'You are offline');
    expect(labelled, isNotEmpty);
    expect(labelled.first.properties.liveRegion, isTrue);
  });
}
