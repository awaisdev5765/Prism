import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_kit/prism.dart';

Future<void> _pumpHost(
  WidgetTester tester, {
  Size size = const Size(400, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => PrismAdaptiveDialog.show<bool>(
                context,
                title: 'Delete item?',
                builder: (context) => const Text('This cannot be undone.'),
                actions: [
                  AdaptiveDialogAction.cancel(context),
                  AdaptiveDialogAction.destructive(
                    context,
                    label: 'Delete',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PrismAdaptiveDialog', () {
    testWidgets('compact shows bottom sheet', (tester) async {
      await _pumpHost(tester, size: const Size(400, 800));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Delete item?'), findsOneWidget);
      expect(find.text('This cannot be undone.'), findsOneWidget);
    });

    testWidgets('expanded shows centered dialog', (tester) async {
      await _pumpHost(tester, size: const Size(1200, 800));
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Delete item?'), findsOneWidget);
    });

    testWidgets('presentation override forces dialog on compact', (
      tester,
    ) async {
      await _pumpHost(tester, size: const Size(400, 800));
      // Pump a host that forces PresentationStyle.dialog.
      tester.view.reset();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => PrismAdaptiveDialog.show<bool>(
                    context,
                    presentation: PresentationStyle.dialog,
                    builder: (context) => const Text('Forced dialog'),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Forced dialog'), findsOneWidget);
    });

    testWidgets('destructive action pops with true', (tester) async {
      Object? result;
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await PrismAdaptiveDialog.show<bool>(
                      context,
                      title: 'Delete item?',
                      builder: (context) => const Text('Sure?'),
                      actions: [
                        AdaptiveDialogAction.destructive(
                          context,
                          label: 'Delete',
                          onPressed: () => Navigator.pop(context, true),
                        ),
                      ],
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('cancel action pops with null', (tester) async {
      Object? result = 'sentinel';
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await PrismAdaptiveDialog.show<bool>(
                      context,
                      title: 'Delete item?',
                      builder: (context) => const Text('Sure?'),
                      actions: [AdaptiveDialogAction.cancel(context)],
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });

    testWidgets('barrier dismiss on bottom sheet pops with null', (
      tester,
    ) async {
      Object? result = 'sentinel';
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await PrismAdaptiveDialog.show<bool>(
                      context,
                      title: 'Delete item?',
                      builder: (context) => const Text('Sure?'),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      // Tap above the sheet to hit the barrier.
      await tester.tapAt(const Offset(200, 30));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
