import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_kit/prism.dart';

Widget _wrap(Widget child) => MaterialApp(home: child);

Future<void> _pumpScaffold(
  WidgetTester tester, {
  Size size = const Size(400, 800),
  int currentIndex = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    _wrap(
      PrismAdaptiveScaffold(
        destinations: const [
          AdaptiveDestination(icon: Icons.inbox_outlined, label: 'Inbox'),
          AdaptiveDestination(icon: Icons.send_outlined, label: 'Sent'),
        ],
        currentIndex: currentIndex,
        bodyBuilder: (index) => Center(child: Text('Page $index')),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('PrismBreakpoint', () {
    test('resolves compact below 600', () {
      expect(PrismBreakpoint.resolve(0), PrismBreakpoint.compact);
      expect(PrismBreakpoint.resolve(599.9), PrismBreakpoint.compact);
    });

    test('resolves medium at 600–839', () {
      expect(PrismBreakpoint.resolve(600), PrismBreakpoint.medium);
      expect(PrismBreakpoint.resolve(839.9), PrismBreakpoint.medium);
    });

    test('resolves expanded at 840–1199', () {
      expect(PrismBreakpoint.resolve(840), PrismBreakpoint.expanded);
      expect(PrismBreakpoint.resolve(1199.9), PrismBreakpoint.expanded);
    });

    test('resolves extraLarge at 1200+', () {
      expect(PrismBreakpoint.resolve(1200), PrismBreakpoint.extraLarge);
      expect(PrismBreakpoint.resolve(4000), PrismBreakpoint.extraLarge);
    });

    test('equality is value-based', () {
      expect(const PrismBreakpoint(600), const PrismBreakpoint(600));
      expect(
        PrismBreakpoint.medium.isSameClass(PrismBreakpoint.medium),
        isTrue,
      );
    });
  });

  group('PrismAdaptiveScaffold layouts', () {
    testWidgets('compact shows bottom navigation bar', (tester) async {
      await _pumpScaffold(tester, size: const Size(400, 800));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.text('Page 0'), findsOneWidget);
    });

    testWidgets('medium shows navigation rail without labels', (tester) async {
      await _pumpScaffold(tester, size: const Size(700, 800));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('expanded shows extended rail', (tester) async {
      await _pumpScaffold(tester, size: const Size(1000, 800));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.text('Inbox'), findsOneWidget);
    });

    testWidgets('destination selection updates body', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      var selected = 0;
      await tester.pumpWidget(
        _wrap(
          StatefulBuilder(
            builder: (context, setState) => PrismAdaptiveScaffold(
              destinations: const [
                AdaptiveDestination(icon: Icons.inbox_outlined, label: 'Inbox'),
                AdaptiveDestination(icon: Icons.send_outlined, label: 'Sent'),
              ],
              currentIndex: selected,
              onDestinationSelected: (i) => setState(() => selected = i),
              bodyBuilder: (index) => Center(child: Text('Page $index')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sent'));
      await tester.pumpAndSettle();
      expect(find.text('Page 1'), findsOneWidget);
    });
  });
}
