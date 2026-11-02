import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

const steps = [
  PrismStep(title: 'Account'),
  PrismStep(title: 'Profile'),
  PrismStep(title: 'Preferences', isOptional: true),
];

void main() {
  group('stateOf', () {
    const stepper = PrismStepper(steps: steps, currentIndex: 2);
    test('the active step is active', () {
      expect(stepper.stateOf(2), PrismStepState.active);
    });

    test('earlier steps are complete', () {
      expect(stepper.stateOf(0), PrismStepState.complete);
      expect(stepper.stateOf(1), PrismStepState.complete);
    });

    test('later steps are pending', () {
      const first = PrismStepper(steps: steps, currentIndex: 0);
      expect(first.stateOf(1), PrismStepState.pending);
    });

    test('errored indices win over completion', () {
      const errored = PrismStepper(
        steps: steps,
        currentIndex: 2,
        erroredIndices: {0},
      );
      expect(errored.stateOf(0), PrismStepState.error);
    });

    test('explicitly completed indices beyond the current are complete', () {
      const s = PrismStepper(
        steps: steps,
        currentIndex: 0,
        completedIndices: {2},
      );
      expect(s.stateOf(2), PrismStepState.complete);
    });
  });

  testWidgets('wide layout shows every step label', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(const PrismStepper(steps: steps, currentIndex: 1)),
    );
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.text('Preferences'), findsOneWidget);
  });

  testWidgets('compact layout shows "Step X of Y" and the progress bar', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(const PrismStepper(steps: steps, currentIndex: 1)),
    );
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('compact layout flags optional steps', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(const PrismStepper(steps: steps, currentIndex: 2)),
    );
    expect(find.text('Optional'), findsOneWidget);
  });

  testWidgets('tapping a step reports its index in the wide layout', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    int? tapped;
    await tester.pumpWidget(
      host(
        PrismStepper(
          steps: steps,
          currentIndex: 0,
          onStepTapped: (i) => tapped = i,
        ),
      ),
    );
    await tester.tap(find.text('Profile'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('disabled steps do not fire the callback', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    int? tapped;
    await tester.pumpWidget(
      host(
        PrismStepper(
          currentIndex: 0,
          onStepTapped: (i) => tapped = i,
          steps: const [
            PrismStep(title: 'One'),
            PrismStep(title: 'Locked', isEnabled: false),
          ],
        ),
      ),
    );
    await tester.tap(find.text('Locked'));
    await tester.pump();
    expect(tapped, isNull);
  });

  testWidgets('progress value tracks the current index', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(const PrismStepper(steps: steps, currentIndex: 0)),
    );
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, closeTo(1 / 3, 0.001));
  });

  testWidgets('empty step list renders nothing', (tester) async {
    await tester.pumpWidget(
      host(const PrismStepper(steps: [], currentIndex: 0)),
    );
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('exposes an accessibility label', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      host(const PrismStepper(steps: steps, currentIndex: 1)),
    );
    final node = tester.getSemantics(find.byType(PrismStepper));
    expect(node.label, contains('Step 2 of 3'));
  });
}
