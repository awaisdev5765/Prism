import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/prism.dart';

void main() {
  group('PrismStateView', () {
    Future<void> pumpState(
      WidgetTester tester,
      PrismViewState<String> state, {
      VoidCallback? onRetry,
      String? emptyMessage,
      String? emptyActionLabel,
      VoidCallback? onEmptyAction,
      bool settle = true,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrismStateView<String>(
              state: state,
              onRetry: onRetry,
              emptyMessage: emptyMessage,
              emptyActionLabel: emptyActionLabel,
              onEmptyAction: onEmptyAction,
              successBuilder: (data) => Text('Data: $data'),
            ),
          ),
        ),
      );
      if (settle) {
        await tester.pumpAndSettle();
      } else {
        await tester.pump();
      }
    }

    testWidgets('loading shows spinner and message', (tester) async {
      // CircularProgressIndicator never settles — pump once instead.
      await pumpState(
        tester,
        const PrismViewState.loading(message: 'Fetching…'),
        settle: false,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Fetching…'), findsOneWidget);
    });

    testWidgets('error shows message and retry', (tester) async {
      var retried = false;
      await pumpState(
        tester,
        const PrismViewState.error('Boom'),
        onRetry: () => retried = true,
      );
      expect(find.text('Boom'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('error without retry hides button', (tester) async {
      await pumpState(tester, const PrismViewState.error('Boom'));
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('empty shows message', (tester) async {
      await pumpState(
        tester,
        const PrismViewState.empty(),
        emptyMessage: 'No items yet',
      );
      expect(find.text('No items yet'), findsOneWidget);
    });

    testWidgets('empty action button fires callback', (tester) async {
      var tapped = false;
      await pumpState(
        tester,
        const PrismViewState.empty(),
        emptyActionLabel: 'Add item',
        onEmptyAction: () => tapped = true,
      );
      await tester.tap(find.text('Add item'));
      expect(tapped, isTrue);
    });

    testWidgets('success renders via successBuilder', (tester) async {
      await pumpState(tester, const PrismViewState.success('hello'));
      expect(find.text('Data: hello'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('cross-fades between states', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PrismStateView<String>(
            state: const PrismViewState.loading(),
            successBuilder: (data) => Text('Data: $data'),
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: PrismStateView<String>(
            state: const PrismViewState.success('done'),
            successBuilder: (data) => Text('Data: $data'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Data: done'), findsOneWidget);
    });
  });

  group('PrismViewStateNotifier', () {
    test('success with data', () async {
      final notifier = PrismViewStateNotifier<String>.fromFuture(
        Future.value('ok'),
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifier.value, isA<PrismViewSuccess<String>>());
    });

    test('empty iterable becomes PrismViewEmpty', () async {
      final notifier = PrismViewStateNotifier<List<int>>.fromFuture(
        Future.value([]),
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifier.value, isA<PrismViewEmpty<List<int>>>());
    });

    test('failure becomes PrismViewError', () async {
      final notifier = PrismViewStateNotifier<String>.fromFuture(
        Future<String>.error(StateError('bad')),
      );
      await Future<void>.delayed(Duration.zero);
      expect(notifier.value, isA<PrismViewError<String>>());
    });
  });
}
