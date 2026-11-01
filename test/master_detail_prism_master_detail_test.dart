import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_kit/prism.dart';

Widget _host(Widget child) {
  return MaterialApp(home: child);
}

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(400, 800),
  int? selectedIndex,
  ValueChanged<int?>? onSelectionChanged,
  bool compactOverride = false,
  PrismCompactBehavior compactBehavior = PrismCompactBehavior.push,
  bool autoFocus = false,
  double? masterPaneWidthExtraLarge,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _host(
      StatefulBuilder(
        builder: (context, setState) => PrismMasterDetail<String>(
          items: const ['One', 'Two', 'Three'],
          selectedIndex: selectedIndex,
          onSelectionChanged: onSelectionChanged,
          debugCompactOverride: compactOverride,
          compactBehavior: compactBehavior,
          autoFocus: autoFocus,
          masterPaneWidthExtraLarge: masterPaneWidthExtraLarge,
          masterBuilder: (context, item, selected) =>
              ListTile(selected: selected, title: Text(item)),
          detailBuilder: (context, item) =>
              Center(child: Text('Detail: $item')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PrismMasterDetail — compact', () {
    testWidgets('shows master list full-screen', (tester) async {
      await _pump(tester);
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
      expect(find.textContaining('Detail:'), findsNothing);
    });

    testWidgets('push behavior: tapping item pushes detail page with back', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(find.text('Detail: Two'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Two'), findsOneWidget);
      expect(find.textContaining('Detail:'), findsNothing);
    });

    testWidgets('replace behavior: swaps in place, back clears selection', (
      tester,
    ) async {
      int? callbackValue;
      await _pump(
        tester,
        onSelectionChanged: (i) => callbackValue = i,
        compactBehavior: PrismCompactBehavior.replace,
      );
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(find.text('Detail: Two'), findsOneWidget);
      expect(find.text('Two'), findsNothing); // list replaced

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Two'), findsOneWidget);
      expect(callbackValue, isNull); // back reports null
    });

    testWidgets('fires selection callback', (tester) async {
      int? selected;
      await _pump(tester, onSelectionChanged: (i) => selected = i);
      await tester.tap(find.text('Three'));
      expect(selected, 2);
    });

    testWidgets('empty list renders without errors', (tester) async {
      await tester.pumpWidget(
        _host(
          PrismMasterDetail<String>(
            items: const [],
            masterBuilder: (context, item, selected) => const SizedBox(),
            detailBuilder: (context, item) => const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('PrismMasterDetail — wide', () {
    testWidgets('shows both panes side by side', (tester) async {
      await _pump(tester, size: const Size(1000, 800));
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Select an item'), findsOneWidget);
    });

    testWidgets('tapping updates detail inline', (tester) async {
      await _pump(tester, size: const Size(1000, 800));
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();
      expect(find.text('Detail: Two'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget); // master pane still visible
    });

    testWidgets('controlled selection updates detail', (tester) async {
      await _pump(tester, size: const Size(1000, 800), selectedIndex: 2);
      expect(find.text('Detail: Three'), findsOneWidget);
    });

    testWidgets('custom empty widget renders', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _host(
          PrismMasterDetail<String>(
            items: const ['One'],
            empty: (context) => const Text('My empty state'),
            masterBuilder: (context, item, selected) =>
                ListTile(title: Text(item)),
            detailBuilder: (context, item) => const SizedBox(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My empty state'), findsOneWidget);
    });

    testWidgets('extra-large window uses wider master pane', (tester) async {
      await _pump(
        tester,
        size: const Size(1300, 800),
        masterPaneWidthExtraLarge: 500,
      );
      expect(tester.getSize(find.byType(ListView)).width, 500);
    });
  });

  group('PrismMasterDetail — keyboard navigation', () {
    testWidgets('arrow keys move selection, Enter opens detail', (
      tester,
    ) async {
      await _pump(tester, size: const Size(1000, 800), autoFocus: true);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Detail: One'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(find.text('Detail: Three'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(find.text('Detail: Two'), findsOneWidget);
    });

    testWidgets('Enter on compact pushes detail', (tester) async {
      await _pump(tester, autoFocus: true);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(find.text('Detail: One'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('keyboard selection fires callback without activation', (
      tester,
    ) async {
      final selections = <int?>[];
      await _pump(
        tester,
        size: const Size(1000, 800),
        autoFocus: true,
        onSelectionChanged: selections.add,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(selections, [0]); // moved but not activated
    });
  });
}
