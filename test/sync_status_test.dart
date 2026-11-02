import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('PrismSyncSnapshot', () {
    test('idle with nothing pending reads as settled', () {
      const snapshot = PrismSyncSnapshot.idle();
      expect(snapshot.isSettled, isTrue);
      expect(snapshot.isBusy, isFalse);
      expect(snapshot.label, 'Up to date');
      expect(snapshot.semantic, PrismSemantic.success);
    });

    test('idle with pending changes says how many', () {
      const snapshot = PrismSyncSnapshot(
        phase: PrismSyncPhase.idle,
        pendingChanges: 3,
      );
      expect(snapshot.isSettled, isFalse);
      expect(snapshot.label, '3 waiting to sync');
    });

    test('pushing and pulling report progress', () {
      const pushing = PrismSyncSnapshot(
        phase: PrismSyncPhase.pushing,
        completed: 5,
        total: 10,
      );
      expect(pushing.isBusy, isTrue);
      expect(pushing.progress, 0.5);
      expect(pushing.semantic, PrismSemantic.info);
      expect(pushing.label, 'Uploading changes');

      const pulling = PrismSyncSnapshot(phase: PrismSyncPhase.pulling);
      expect(pulling.label, 'Downloading changes');
      expect(pulling.progress, isNull);
    });

    test('offline reports pending work', () {
      const snapshot = PrismSyncSnapshot(
        phase: PrismSyncPhase.offline,
        pendingChanges: 2,
      );
      expect(snapshot.isOffline, isTrue);
      expect(snapshot.label, 'Offline — 2 waiting');
      expect(snapshot.semantic, PrismSemantic.warning);
    });

    test('failure carries the error and an error role', () {
      const snapshot = PrismSyncSnapshot(
        phase: PrismSyncPhase.failed,
        error: 'network down',
      );
      expect(snapshot.semantic, PrismSemantic.error);
      expect(snapshot.label, 'Sync failed');
    });

    test('progress is null when the total is unknown or zero', () {
      expect(
        const PrismSyncSnapshot(phase: PrismSyncPhase.pushing).progress,
        isNull,
      );
      expect(
        const PrismSyncSnapshot(
          phase: PrismSyncPhase.pushing,
          total: 0,
        ).progress,
        isNull,
      );
    });

    test('progress is clamped', () {
      const over = PrismSyncSnapshot(
        phase: PrismSyncPhase.pushing,
        completed: 20,
        total: 10,
      );
      expect(over.progress, 1.0);
    });

    test('every phase has a label, an icon and a role', () {
      for (final phase in PrismSyncPhase.values) {
        final snapshot = PrismSyncSnapshot(phase: phase);
        expect(snapshot.label, isNotEmpty, reason: '$phase');
        expect(snapshot.icon, isNotNull, reason: '$phase');
        expect(snapshot.semantic, isNotNull, reason: '$phase');
      }
    });

    test('copyWith replaces only what is named', () {
      const base = PrismSyncSnapshot(
        phase: PrismSyncPhase.idle,
        pendingChanges: 1,
      );
      final changed = base.copyWith(phase: PrismSyncPhase.offline);
      expect(changed.phase, PrismSyncPhase.offline);
      expect(changed.pendingChanges, 1);
    });
  });

  group('PrismSyncStatus', () {
    testWidgets('shows the label and icon when idle', (tester) async {
      await tester.pumpWidget(
        host(const PrismSyncStatus(snapshot: PrismSyncSnapshot.idle())),
      );
      expect(find.text('Up to date'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    });

    testWidgets('shows a spinner while busy', (tester) async {
      await tester.pumpWidget(
        host(
          const PrismSyncStatus(
            snapshot: PrismSyncSnapshot(
              phase: PrismSyncPhase.pushing,
              completed: 1,
              total: 4,
            ),
          ),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Uploading changes'), findsOneWidget);
    });

    testWidgets('offers retry only on failure', (tester) async {
      var retried = 0;
      await tester.pumpWidget(
        host(
          PrismSyncStatus(
            snapshot: const PrismSyncSnapshot(
              phase: PrismSyncPhase.failed,
              error: 'boom',
            ),
            onRetry: () => retried++,
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pump();
      expect(retried, 1);
    });

    testWidgets('does not offer retry while healthy', (tester) async {
      await tester.pumpWidget(
        host(
          PrismSyncStatus(
            snapshot: const PrismSyncSnapshot.idle(),
            onRetry: () {},
          ),
        ),
      );
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('hides the label but keeps it for assistive tech', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const PrismSyncStatus(
              snapshot: PrismSyncSnapshot(phase: PrismSyncPhase.offline),
              showLabel: false,
            ),
          ),
        );

        expect(find.text('Offline'), findsNothing);
        final node = tester.getSemantics(find.byType(PrismSyncStatus));
        expect(node.label, contains('Offline'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('announces the failure reason', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const PrismSyncStatus(
              snapshot: PrismSyncSnapshot(
                phase: PrismSyncPhase.failed,
                error: 'network unreachable',
              ),
            ),
          ),
        );
        final node = tester.getSemantics(find.byType(PrismSyncStatus));
        expect(node.label, contains('network unreachable'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('is a live region, so a failure is announced', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            const PrismSyncStatus(
              snapshot: PrismSyncSnapshot(phase: PrismSyncPhase.offline),
            ),
          ),
        );
        final node = tester.getSemantics(find.byType(PrismSyncStatus));
        expect(node.flagsCollection.isLiveRegion, isTrue);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('renders cleanly in dark mode and RTL', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(brightness: Brightness.dark),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: const Scaffold(
              body: PrismSyncStatus(
                snapshot: PrismSyncSnapshot(
                  phase: PrismSyncPhase.offline,
                  pendingChanges: 5,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
