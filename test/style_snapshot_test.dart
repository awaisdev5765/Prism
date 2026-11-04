import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

import 'support/style_snapshot.dart';

/// One snapshot per component, recording the styles it resolved.
///
/// This is the visual-regression net for the design system: change a token
/// default, or hard-code a radius inside a component, and the relevant snapshot
/// fails with a readable diff instead of silently shipping.
///
/// Run with `PRISM_UPDATE_SNAPSHOTS=1` to rewrite them, and read the diff.
void main() {
  /// Wraps a component so the snapshot covers it and not Flutter's chrome.
  Widget wrap(Widget child) => MaterialApp(
        theme: ThemeData(colorSchemeSeed: const Color(0xFF39A9DB)),
        home: Scaffold(
          body: KeyedSubtree(key: StyleSnapshot.rootKey, child: child),
        ),
      );

  Future<void> snapshot(
    WidgetTester tester,
    String name,
    Widget component, {
    Size size = const Size(1000, 800),
    Set<String> ignore = const {},
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(wrap(component));
    await tester.pump(const Duration(milliseconds: 400));
    StyleSnapshot.expectMatches(tester, name, ignore: ignore);
  }

  group('layout and navigation', () {
    testWidgets('adaptive scaffold', (tester) async {
      await snapshot(
        tester,
        'adaptive_scaffold',
        PrismAdaptiveScaffold(
          destinations: const [
            AdaptiveDestination(icon: Icons.home, label: 'Home'),
            AdaptiveDestination(icon: Icons.settings, label: 'Settings'),
          ],
          bodyBuilder: (i) => const SizedBox.shrink(),
        ),
      );
    });

    testWidgets('tabs', (tester) async {
      await snapshot(
        tester,
        'tabs',
        PrismTabs(
          index: 0,
          onChanged: (_) {},
          tabs: const [PrismTab(label: 'One'), PrismTab(label: 'Two')],
          children: const [Text('a'), Text('b')],
        ),
      );
    });

    testWidgets('stepper', (tester) async {
      await snapshot(
        tester,
        'stepper',
        const PrismStepper(
          steps: [PrismStep(title: 'One'), PrismStep(title: 'Two')],
          currentIndex: 0,
        ),
      );
    });

    testWidgets('accordion', (tester) async {
      await snapshot(
        tester,
        'accordion',
        const PrismAccordion(
          sections: [
            PrismAccordionSection(
              title: 'Section',
              child: Text('body'),
              initiallyExpanded: true,
            ),
          ],
        ),
      );
    });

    testWidgets('master detail', (tester) async {
      await snapshot(
        tester,
        'master_detail',
        PrismMasterDetail<String>(
          items: const ['Alpha'],
          masterBuilder: (c, item, selected) => Text(item),
          detailBuilder: (c, item) => Text('detail $item'),
        ),
      );
    });
  });

  group('feedback and status', () {
    testWidgets('state view loading', (tester) async {
      await snapshot(
        tester,
        'state_view',
        PrismStateView<String>(
          state: const PrismViewLoading(),
          successBuilder: (d) => Text(d),
        ),
      );
    });

    testWidgets('state view empty', (tester) async {
      await snapshot(
        tester,
        'state_view_empty',
        PrismStateView<String>(
          state: const PrismViewEmpty(),
          successBuilder: (d) => Text(d),
        ),
      );
    });

    testWidgets('skeleton', (tester) async {
      await snapshot(
        tester,
        'skeleton',
        const PrismSkeleton(width: 120, height: 20, animate: false),
      );
    });

    testWidgets('badge', (tester) async {
      await snapshot(
        tester,
        'badge',
        const PrismBadge(count: 5, child: Icon(Icons.mail)),
      );
    });

    testWidgets('timeline', (tester) async {
      await snapshot(
        tester,
        'timeline',
        const PrismTimeline(
          entries: [
            PrismTimelineEntry(title: 'First', timestamp: '09:12'),
            PrismTimelineEntry(
              title: 'Second',
              semantic: PrismSemantic.success,
            ),
          ],
        ),
      );
    });

    testWidgets('banner', (tester) async {
      await snapshot(
        tester,
        'banner',
        const PrismBanner(
          announcements: [
            PrismAnnouncement(id: 'a', title: 'Title', message: 'Message'),
          ],
        ),
      );
    });

    testWidgets('connection banner', (tester) async {
      await snapshot(
        tester,
        'connection_banner',
        PrismConnectionBanner(source: () => const Stream<bool>.empty()),
      );
    });

    testWidgets('sync status', (tester) async {
      await snapshot(
        tester,
        'sync_status',
        const PrismSyncStatus(
          snapshot: PrismSyncSnapshot(
            phase: PrismSyncPhase.offline,
            pendingChanges: 3,
          ),
        ),
      );
    });

    testWidgets('pagination', (tester) async {
      await snapshot(
        tester,
        'pagination',
        PrismPaginatedList<String>(
          pageLoader: (_) async => const ['one'],
          itemBuilder: (c, item, i) => ListTile(title: Text(item)),
        ),
      );
    });
  });

  group('data and input', () {
    testWidgets('data table', (tester) async {
      await snapshot(
        tester,
        'data_table',
        PrismDataTable<String>(
          rows: const ['a', 'b'],
          columns: [
            PrismColumn<String>(
              label: 'Value',
              cell: (c, r, i) => Text(r),
              sortComparator: (a, b) => a.compareTo(b),
            ),
          ],
        ),
      );
    });

    testWidgets('calendar', (tester) async {
      await snapshot(
        tester,
        'calendar',
        PrismCalendar(
          month: DateTime(2026, 8),
          selected: const {},
          today: DateTime(2026, 8, 15),
          onDaySelected: (_) {},
        ),
      );
    });

    testWidgets('segmented control', (tester) async {
      await snapshot(
        tester,
        'segmented_control',
        PrismSegmentedControl<String>(
          value: 'a',
          onChanged: (_) {},
          segments: const [
            PrismSegment(value: 'a', label: 'Alpha'),
            PrismSegment(value: 'b', label: 'Beta'),
          ],
        ),
      );
    });

    testWidgets('rating', (tester) async {
      await snapshot(
        tester,
        'rating',
        PrismRating(value: 3, onChanged: (_) {}),
      );
    });

    testWidgets('chip input', (tester) async {
      await snapshot(
        tester,
        'chip_input',
        PrismChipInput(value: const ['alpha'], onChanged: (_) {}),
      );
    });

    testWidgets('otp field', (tester) async {
      await snapshot(tester, 'otp_field', const PrismOtpField(length: 4));
    });

    testWidgets('search', (tester) async {
      await snapshot(
        tester,
        'search',
        PrismSearch<String>(
          items: const ['Alpha', 'Beta'],
          itemLabel: (s) => s,
        ),
      );
    });

    testWidgets('settings', (tester) async {
      await snapshot(
        tester,
        'settings',
        PrismSettingsPage(
          sections: const [
            PrismSettingsSection(
              title: 'General',
              tiles: [
                PrismSwitchTile(
                  common: PrismTileCommon(key: 'k', title: 'Toggle'),
                ),
              ],
            ),
          ],
        ),
      );
    });

    testWidgets('command palette', (tester) async {
      await snapshot(
        tester,
        'command_palette',
        PrismCommandPalette(
          commands: [
            PrismCommand(label: 'Run', icon: Icons.play_arrow, onSelect: () {}),
          ],
        ),
      );
    });
  });

  group('content and media', () {
    testWidgets('avatar', (tester) async {
      await snapshot(
        tester,
        'avatar',
        const PrismAvatar(name: 'Ayesha Khan', presence: PrismPresence.online),
      );
    });

    testWidgets('markdown', (tester) async {
      await snapshot(
        tester,
        'markdown',
        const PrismMarkdown('# Heading\n\nSome **bold** text.'),
      );
    });

    testWidgets('code view', (tester) async {
      await snapshot(
        tester,
        'code_view',
        const PrismCodeView(code: 'void main() {}'),
      );
    });

    testWidgets('changelog', (tester) async {
      await snapshot(
        tester,
        'changelog',
        const ChangelogView(changelog: '## 1.0.0\n\n### Added\n- Thing\n'),
      );
    });
  });

  group('the snapshots are actually recording something', () {
    testWidgets('a capture contains style data', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const PrismAvatar(name: 'Ayesha Khan')));
      await tester.pump();

      final captured = StyleSnapshot.capture(tester);
      expect(captured, isNotEmpty);
      expect(captured.keys, contains('fill'));
    });

    testWidgets('the root key scopes the capture', (tester) async {
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const SizedBox.shrink()));
      // A bare SizedBox resolves no styling. If the capture walked from the
      // root it would carry Scaffold and Material values, and every snapshot
      // would be testing Flutter's defaults instead of Prism's.
      final captured = StyleSnapshot.capture(tester);
      expect(captured.keys, isNot(contains('fill')));
      expect(captured.keys, isNot(contains('text')));
      expect(captured.keys, isNot(contains('radius')));
    });
  });
}
