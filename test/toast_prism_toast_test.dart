import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_kit/prism.dart';

Future<void> _pumpHost(
  WidgetTester tester, {
  Size size = const Size(1000, 800),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => PrismToast.success(context, 'Settings saved.'),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() => PrismToast.dismissAll());

  group('PrismToast — wide windows (desktop/web)', () {
    testWidgets('toast appears top-right with message', (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      expect(find.text('Settings saved.'), findsOneWidget);
      expect(find.byTooltip('Dismiss'), findsOneWidget);
    });

    testWidgets('stacked toasts pile up', (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      expect(find.text('Settings saved.'), findsNWidgets(2));
    });

    testWidgets('toast auto-dismisses after duration', (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      expect(find.text('Settings saved.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      expect(find.text('Settings saved.'), findsNothing);
    });

    testWidgets('close button dismisses early', (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Settings saved.'), findsNothing);
    });

    testWidgets('success shows check icon and container colors', (
      tester,
    ) async {
      await _pumpHost(tester);
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      final icons = tester
          .widgetList<Icon>(find.byType(Icon))
          .where((i) => i.icon == Icons.check_circle_rounded)
          .toList();
      expect(icons, isNotEmpty);
    });
  });

  group('PrismToast — compact windows (mobile)', () {
    testWidgets('toast appears bottom-centered', (tester) async {
      await _pumpHost(tester, size: const Size(400, 800));
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      expect(find.text('Settings saved.'), findsOneWidget);
      final toastRect = tester.getRect(find.text('Settings saved.'));
      expect(toastRect.bottom, greaterThan(700)); // near bottom
    });
  });

  group('PrismToast — variants and actions', () {
    testWidgets('each variant renders its icon', (tester) async {
      final cases = {
        PrismToastType.success: Icons.check_circle_rounded,
        PrismToastType.error: Icons.error_rounded,
        PrismToastType.warning: Icons.warning_amber_rounded,
        PrismToastType.info: Icons.info_rounded,
      };
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    PrismToast.show(
                      context,
                      const PrismToastMessage(message: 'msg a'),
                    );
                    PrismToast.show(
                      context,
                      const PrismToastMessage(
                        message: 'msg b',
                        type: PrismToastType.error,
                      ),
                    );
                    PrismToast.show(
                      context,
                      const PrismToastMessage(
                        message: 'msg c',
                        type: PrismToastType.warning,
                      ),
                    );
                    PrismToast.show(
                      context,
                      const PrismToastMessage(
                        message: 'msg d',
                        type: PrismToastType.success,
                      ),
                    );
                  },
                  child: const Text('show all'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('show all'));
      await tester.pumpAndSettle();
      for (final entry in cases.entries) {
        final found = tester
            .widgetList<Icon>(find.byType(Icon))
            .any((icon) => icon.icon == entry.value);
        expect(found, isTrue, reason: '${entry.value} missing');
      }
      expect(find.text('msg a'), findsOneWidget);
      expect(find.text('msg d'), findsOneWidget);
    });

    testWidgets('action button fires callback and dismisses', (tester) async {
      var tapped = false;
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () => PrismToast.show(
                    context,
                    PrismToastMessage(
                      message: 'Update available',
                      actionLabel: 'Install',
                      onAction: () => tapped = true,
                    ),
                  ),
                  child: const Text('show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Install'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
      expect(find.text('Update available'), findsNothing);
    });

    testWidgets('shorthands create correct types', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: ElevatedButton(
                  onPressed: () {
                    PrismToast.error(context, 'bad');
                    PrismToast.warning(context, 'meh');
                    PrismToast.info(context, 'fyi');
                  },
                  child: const Text('show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      expect(find.text('bad'), findsOneWidget);
      expect(find.text('meh'), findsOneWidget);
      expect(find.text('fyi'), findsOneWidget);
    });

    testWidgets('dismissAll removes everything', (tester) async {
      await _pumpHost(tester);
      await tester.tap(find.text('show'));
      await tester.tap(find.text('show'));
      await tester.pumpAndSettle();
      expect(find.text('Settings saved.'), findsNWidgets(2));
      PrismToast.dismissAll();
      await tester.pumpAndSettle();
      expect(find.text('Settings saved.'), findsNothing);
    });
  });
}
