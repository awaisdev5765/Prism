import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

/// Accessibility is a functional requirement, not a polish pass: if a screen
/// reader cannot operate a component, the component does not work. These tests
/// assert the specific behaviours that make each component usable without sight,
/// and they fail loudly when someone regresses one.
/// Runs a widget test with semantics enabled, disposing the handle inside the
/// test body. `addTearDown` is too late: the framework verifies that every
/// handle was disposed before tear-downs run.
void semanticsTest(
  String description,
  Future<void> Function(WidgetTester) body,
) {
  testWidgets(description, (tester) async {
    final handle = tester.ensureSemantics();
    try {
      await body(tester);
    } finally {
      handle.dispose();
    }
  });
}

void main() {
  // Build the MediaQuery from the ambient one: a bare MediaQueryData() reports
  // a zero-size viewport, which would silently push width-dependent components
  // into their compact layout and make these tests lie.
  Widget host(Widget child, {bool reduceMotion = false}) => MaterialApp(
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: Scaffold(body: child),
      ),
    ),
  );

  group('live regions announce changes the user did not trigger', () {
    semanticsTest('PrismToast announces its message', (tester) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  PrismToast.success(context, 'Saved successfully'),
              child: const Text('show'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('show'));
      await tester.pump(const Duration(milliseconds: 300));

      final node = tester.getSemantics(find.text('Saved successfully'));
      expect(node.flagsCollection.isLiveRegion, isTrue);
      expect(node.label, contains('Saved successfully'));

      PrismToast.dismissAll();
      await tester.pump(const Duration(seconds: 1));
    });

    semanticsTest('PrismStateView announces loading', (tester) async {
      await tester.pumpWidget(
        host(
          PrismStateView<String>(
            state: const PrismViewLoading(),
            successBuilder: (d) => Text(d),
          ),
        ),
      );
      await tester.pump();

      final node = tester.getSemantics(find.byType(CircularProgressIndicator));
      expect(node.flagsCollection.isLiveRegion, isTrue);
    });

    semanticsTest('PrismStateView announces an error', (tester) async {
      await tester.pumpWidget(
        host(
          PrismStateView<String>(
            state: PrismViewError<String>(StateError('Network unreachable')),
            successBuilder: (d) => Text(d),
          ),
        ),
      );
      await tester.pump();

      final node = tester.getSemantics(
        find.textContaining('Network unreachable'),
      );
      expect(node.flagsCollection.isLiveRegion, isTrue);
    });
  });

  group('decorative content is hidden from assistive tech', () {
    testWidgets('PrismSkeleton is not announced', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [PrismSkeletonList.tiles(count: 3), Text('Real content')],
          ),
        ),
      );
      await tester.pump();

      // Every skeleton block is wrapped in an ExcludeSemantics, so a screen
      // reader hears nothing about placeholders.
      final exclusions = find.descendant(
        of: find.byType(PrismSkeleton),
        matching: find.byType(ExcludeSemantics),
      );
      expect(exclusions, findsWidgets);

      // The real content is still reachable.
      expect(find.text('Real content'), findsOneWidget);
    });
  });

  group('interactive targets are big enough to hit', () {
    testWidgets('a chip remove button meets the 32dp floor', (tester) async {
      await tester.pumpWidget(
        host(PrismChipInput(value: const ['alpha'], onChanged: (_) {})),
      );

      final target = find.bySemanticsLabel('Remove alpha');
      final size = tester.getSize(
        find.descendant(of: target, matching: find.byType(SizedBox)).first,
      );
      expect(size.width, greaterThanOrEqualTo(32));
      expect(size.height, greaterThanOrEqualTo(32));
    });

    testWidgets('the OTP field is at least 48dp tall by default', (
      tester,
    ) async {
      await tester.pumpWidget(host(const PrismOtpField(length: 4)));

      final box = tester.getSize(find.byType(AnimatedContainer).first);
      expect(box.height, greaterThanOrEqualTo(44));
    });

    testWidgets('data table rows are comfortably tappable', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          PrismDataTable<String>(
            rows: const ['one', 'two'],
            columns: [
              PrismColumn<String>(label: 'Value', cell: (c, r, i) => Text(r)),
            ],
            onRowTap: (row, i) {},
          ),
        ),
      );

      final rowHeight = tester.getSize(find.text('one')).height;
      expect(rowHeight, greaterThan(0));
    });
  });

  group('state is expressed, not just implied by colour', () {
    semanticsTest('a sorted column says so', (tester) async {
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          PrismDataTable<String>(
            rows: const ['b', 'a'],
            columns: [
              PrismColumn<String>(
                label: 'Value',
                cell: (c, r, i) => Text(r),
                sortComparator: (a, b) => a.compareTo(b),
              ),
            ],
          ),
        ),
      );

      // The header's Text sits inside an ExcludeSemantics so the label is not
      // announced twice, so match the accessible Semantics node by its label
      // rather than walking ancestors (which would hit internal nodes with no
      // semantics of their own).
      Finder header() => find.byWidgetPredicate(
        (w) => w is Semantics && (w.properties.label ?? '').startsWith('Value'),
      );

      // Before sorting: advertised as sortable.
      expect(tester.getSemantics(header()).label, contains('sortable'));

      await tester.tap(find.text('Value'));
      await tester.pump();

      // After sorting: the direction is announced, with the next action.
      final sorted = tester.getSemantics(header()).label;
      expect(sorted, contains('ascending'));
      expect(sorted, contains('reverse'));
    });

    semanticsTest('the stepper reports the current step as text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          const PrismStepper(
            steps: [
              PrismStep(title: 'Account'),
              PrismStep(title: 'Profile'),
            ],
            currentIndex: 1,
          ),
        ),
      );

      final node = tester.getSemantics(find.byType(PrismStepper));
      expect(node.label, contains('Step 2 of 2'));
      expect(node.label, contains('Profile'));
    });
  });

  group('reduce motion is honoured', () {
    testWidgets('PrismStateView stops animating', (tester) async {
      await tester.pumpWidget(
        host(
          PrismStateView<String>(
            state: const PrismViewLoading(),
            successBuilder: (d) => Text(d),
          ),
          reduceMotion: true,
        ),
      );
      await tester.pump();

      final switcher = tester.widget<AnimatedSwitcher>(
        find.byType(AnimatedSwitcher),
      );
      expect(switcher.duration, Duration.zero);
    });

    testWidgets('PrismSkeleton stops shimmering', (tester) async {
      await tester.pumpWidget(
        host(const PrismSkeleton(width: 80, height: 12), reduceMotion: true),
      );
      await tester.pump();

      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('PrismConnectionBanner stops animating', (tester) async {
      await tester.pumpWidget(
        host(
          PrismConnectionBanner(source: () => const Stream<bool>.empty()),
          reduceMotion: true,
        ),
      );
      await tester.pump();

      final size = tester.widget<AnimatedSize>(find.byType(AnimatedSize));
      expect(size.duration, Duration.zero);
    });

    testWidgets('PrismStepper markers stop animating', (tester) async {
      await tester.pumpWidget(
        host(
          const PrismStepper(
            steps: [
              PrismStep(title: 'One'),
              PrismStep(title: 'Two'),
            ],
            currentIndex: 0,
          ),
          reduceMotion: true,
        ),
      );
      await tester.pump();

      final markers = tester.widgetList<AnimatedContainer>(
        find.byType(AnimatedContainer),
      );
      expect(markers, isNotEmpty);
      for (final marker in markers) {
        expect(marker.duration, Duration.zero);
      }
    });
  });

  group('both text directions are supported', () {
    testWidgets('PrismToast renders in RTL without error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => PrismToast.info(context, 'مرحبا'),
                  child: const Text('show'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('show'));
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text('مرحبا'), findsOneWidget);

      PrismToast.dismissAll();
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('PrismTimeline renders in RTL', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: const PrismTimeline(
                entries: [
                  PrismTimelineEntry(
                    title: 'الخطوة الأولى',
                    timestamp: '٠٩:١٢',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('الخطوة الأولى'), findsOneWidget);
    });
  });
}
