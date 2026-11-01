import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('opens on a compact window and returns an action value',
      (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    bool? result;
    await tester.pumpWidget(host(Builder(
      builder: (context) => Center(
        child: ElevatedButton(
          onPressed: () async {
            result = await PrismAdaptiveSheet.show<bool>(
              context: context,
              title: 'Delete note?',
              child: const Text('This cannot be undone.'),
              actions: const [
                PrismSheetAction(label: 'Cancel', value: false),
                PrismSheetAction(
                  label: 'Delete',
                  value: true,
                  isDestructive: true,
                ),
              ],
            );
          },
          child: const Text('open'),
        ),
      ),
    )));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Delete note?'), findsOneWidget);
    expect(find.text('This cannot be undone.'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('cancel returns false', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    bool? result;
    await tester.pumpWidget(host(Builder(
      builder: (context) => Center(
        child: ElevatedButton(
          onPressed: () async {
            result = await PrismAdaptiveSheet.show<bool>(
              context: context,
              title: 'Confirm',
              child: const Text('body'),
              actions: const [
                PrismSheetAction(label: 'Cancel', value: false),
                PrismSheetAction(label: 'OK', value: true, isPrimary: true),
              ],
            );
          },
          child: const Text('open'),
        ),
      ),
    )));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
  });

  testWidgets('uses a dialog on a wide window', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(Builder(
      builder: (context) => Center(
        child: ElevatedButton(
          onPressed: () => PrismAdaptiveSheet.show<void>(
            context: context,
            title: 'Wide dialog',
            child: const Text('dialog body'),
          ),
          child: const Text('open'),
        ),
      ),
    )));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsOneWidget);
    expect(find.text('Wide dialog'), findsOneWidget);
  });

  testWidgets('renders a subtitle when supplied', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(Builder(
      builder: (context) => Center(
        child: ElevatedButton(
          onPressed: () => PrismAdaptiveSheet.show<void>(
            context: context,
            title: 'Title',
            subtitle: 'Supporting copy',
            child: const Text('body'),
          ),
          child: const Text('open'),
        ),
      ),
    )));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Supporting copy'), findsOneWidget);
  });

  testWidgets('action onPressed runs before the sheet closes', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var tapped = false;
    await tester.pumpWidget(host(Builder(
      builder: (context) => Center(
        child: ElevatedButton(
          onPressed: () => PrismAdaptiveSheet.show<void>(
            context: context,
            title: 'T',
            child: const Text('body'),
            actions: [
              PrismSheetAction(
                label: 'Run',
                onPressed: () => tapped = true,
              ),
            ],
          ),
          child: const Text('open'),
        ),
      ),
    )));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Run'));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('closeOnTap false keeps the sheet open', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(Builder(
      builder: (context) => Center(
        child: ElevatedButton(
          onPressed: () => PrismAdaptiveSheet.show<void>(
            context: context,
            title: 'Sticky',
            child: const Text('body'),
            actions: const [
              PrismSheetAction(
                label: 'Validate',
                closeOnTap: false,
              ),
            ],
          ),
          child: const Text('open'),
        ),
      ),
    )));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Validate'));
    await tester.pumpAndSettle();
    expect(find.text('Sticky'), findsOneWidget);
  });

  testWidgets('renders a custom header when supplied', (tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(Builder(
      builder: (context) => Center(
        child: ElevatedButton(
          onPressed: () => PrismAdaptiveSheet.show<void>(
            context: context,
            header: const Text('CUSTOM HEADER'),
            child: const Text('body'),
          ),
          child: const Text('open'),
        ),
      ),
    )));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('CUSTOM HEADER'), findsOneWidget);
  });
}
