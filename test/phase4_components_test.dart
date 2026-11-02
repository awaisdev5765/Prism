import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

/// Tests for the components added in 1.4.0: badge, rating, segmented control,
/// accordion, tabs and calendar.
/// Normalises a semantics flag to a bool.
///
/// Flutter's semantics flags are mid-migration between `bool` and the newer
/// tri-state enum, and different flags report different types on the same
/// object. Reading through one helper keeps these tests about Prism's behaviour
/// rather than about that transition.
bool _flag(Object? value) => switch (value) {
  final bool b => b,
  final Object o => o.toString().contains('isTrue'),
  _ => false,
};

void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('PrismBadge', () {
    testWidgets('shows a count', (tester) async {
      await tester.pumpWidget(
        host(const PrismBadge(count: 3, child: Icon(Icons.notifications))),
      );
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('caps the count at maxCount', (tester) async {
      await tester.pumpWidget(
        host(
          const PrismBadge(count: 150, maxCount: 99, child: Icon(Icons.mail)),
        ),
      );
      expect(find.text('99+'), findsOneWidget);
    });

    testWidgets('hides a zero count by default', (tester) async {
      await tester.pumpWidget(
        host(const PrismBadge(count: 0, child: Icon(Icons.mail))),
      );
      expect(find.text('0'), findsNothing);
    });

    testWidgets('can show a zero count when asked', (tester) async {
      await tester.pumpWidget(
        host(
          const PrismBadge(count: 0, showZero: true, child: Icon(Icons.mail)),
        ),
      );
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('the dot variant has no text', (tester) async {
      await tester.pumpWidget(
        host(const PrismBadge.dot(child: Icon(Icons.person))),
      );
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('announces the count', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(const PrismBadge(count: 4, child: Icon(Icons.mail))),
        );
        expect(tester.getSemantics(find.byType(PrismBadge)).label, '4 new');
      } finally {
        handle.dispose();
      }
    });
  });

  group('PrismRating', () {
    testWidgets('renders the requested number of stars', (tester) async {
      await tester.pumpWidget(host(const PrismRating(value: 2, max: 5)));
      expect(find.byIcon(Icons.star_border_rounded), findsNWidgets(5));
    });

    testWidgets('tapping a star reports the score', (tester) async {
      double? picked;
      await tester.pumpWidget(
        host(PrismRating(value: 0, onChanged: (v) => picked = v)),
      );

      await tester.tap(find.byIcon(Icons.star_border_rounded).at(2));
      await tester.pump();
      expect(picked, 3);
    });

    testWidgets('exposes slider semantics so it works without sight', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(PrismRating(value: 3, label: 'How was it?', onChanged: (_) {})),
        );
        final node = tester.getSemantics(find.byType(PrismRating));
        expect(node.label, 'How was it?');
        expect(node.value, contains('3'));
        expect(node.value, contains('5'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('a read-only rating is not interactive', (tester) async {
      await tester.pumpWidget(host(const PrismRating(value: 4)));
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      // Read-only: no interaction surface at all.
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('read-only announces the score', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(const PrismRating(value: 4, max: 5)));
        final node = tester.getSemantics(find.byType(PrismRating));
        expect(node.label, 'Rated 4.0 out of 5');
      } finally {
        handle.dispose();
      }
    });

    testWidgets('clamps an out-of-range value', (tester) async {
      await tester.pumpWidget(host(const PrismRating(value: 99, max: 5)));
      expect(tester.takeException(), isNull);
    });
  });

  group('PrismSegmentedControl', () {
    testWidgets('marks the selected segment', (tester) async {
      await tester.pumpWidget(
        host(
          PrismSegmentedControl<String>(
            value: 'b',
            onChanged: (_) {},
            segments: const [
              PrismSegment(value: 'a', label: 'Alpha'),
              PrismSegment(value: 'b', label: 'Beta'),
            ],
          ),
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('tapping a segment reports its value', (tester) async {
      String? picked;
      await tester.pumpWidget(
        host(
          PrismSegmentedControl<String>(
            value: 'a',
            onChanged: (v) => picked = v,
            segments: const [
              PrismSegment(value: 'a', label: 'Alpha'),
              PrismSegment(value: 'b', label: 'Beta'),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Beta'));
      await tester.pump();
      expect(picked, 'b');
    });

    testWidgets('a disabled segment cannot be picked', (tester) async {
      String? picked;
      await tester.pumpWidget(
        host(
          PrismSegmentedControl<String>(
            value: 'a',
            onChanged: (v) => picked = v,
            segments: const [
              PrismSegment(value: 'a', label: 'Alpha'),
              PrismSegment(value: 'b', label: 'Beta', enabled: false),
            ],
          ),
        ),
      );

      await tester.tap(find.text('Beta'));
      await tester.pump();
      expect(picked, isNull);
    });

    testWidgets('exposes a mutually exclusive group', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            PrismSegmentedControl<String>(
              value: 'a',
              onChanged: (_) {},
              semanticLabel: 'Density',
              segments: const [
                PrismSegment(value: 'a', label: 'Compact'),
                PrismSegment(value: 'b', label: 'Comfortable'),
              ],
            ),
          ),
        );

        final option = find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Comfortable',
        );
        final node = tester.getSemantics(option);
        expect(_flag(node.flagsCollection.isInMutuallyExclusiveGroup), isTrue);
        expect(_flag(node.flagsCollection.isSelected), isFalse);
      } finally {
        handle.dispose();
      }
    });

    testWidgets('scrolls rather than overflowing on a phone', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          PrismSegmentedControl<String>(
            value: 'a',
            onChanged: (_) {},
            segments: const [
              PrismSegment(value: 'a', label: 'A very long option label'),
              PrismSegment(value: 'b', label: 'Another long option label'),
              PrismSegment(value: 'c', label: 'A third long option label'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        find.byType(SingleChildScrollView),
        findsOneWidget,
        reason: 'the strip should scroll when labels do not fit',
      );
    });

    testWidgets('fills the width on a wide window', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          PrismSegmentedControl<String>(
            value: 'a',
            onChanged: (_) {},
            segments: const [
              PrismSegment(value: 'a', label: 'Alpha'),
              PrismSegment(value: 'b', label: 'Beta'),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SingleChildScrollView), findsNothing);
    });
  });

  group('PrismTabs', () {
    Widget tabs({int index = 0, ValueChanged<int>? onChanged, int count = 3}) =>
        PrismTabs(
          index: index,
          onChanged: onChanged ?? (_) {},
          tabs: [
            for (var i = 0; i < count; i++) PrismTab(label: 'Tab ${i + 1}'),
          ],
          children: [
            for (var i = 0; i < count; i++) Center(child: Text('Panel $i')),
          ],
        );

    testWidgets('shows the selected panel', (tester) async {
      await tester.pumpWidget(host(tabs(index: 1)));
      expect(find.text('Panel 1'), findsOneWidget);
    });

    testWidgets('tapping a tab reports the index', (tester) async {
      int? picked;
      await tester.pumpWidget(
        host(
          PrismTabs(
            index: 0,
            onChanged: (i) => picked = i,
            tabs: const [
              PrismTab(label: 'One'),
              PrismTab(label: 'Two'),
            ],
            children: const [Text('a'), Text('b')],
          ),
        ),
      );

      await tester.tap(find.text('Two'));
      await tester.pump();
      expect(picked, 1);
    });

    testWidgets('announces position within the strip', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(tabs(count: 3)));

        final tab = find.byWidgetPredicate(
          (w) =>
              w is Semantics && (w.properties.label ?? '') == 'Tab 2, 2 of 3',
        );
        expect(tab, findsOneWidget);
        expect(
          _flag(tester.getSemantics(tab).flagsCollection.isSelected),
          isFalse,
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('a disabled tab cannot be picked', (tester) async {
      int? picked;
      await tester.pumpWidget(
        host(
          PrismTabs(
            index: 0,
            onChanged: (i) => picked = i,
            tabs: const [
              PrismTab(label: 'One'),
              PrismTab(label: 'Two', enabled: false),
            ],
            children: const [Text('a'), Text('b')],
          ),
        ),
      );

      await tester.tap(find.text('Two'));
      await tester.pump();
      expect(picked, isNull);
    });

    testWidgets('scrolls the strip rather than overflowing on a phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        host(
          PrismTabs(
            index: 0,
            onChanged: (_) {},
            tabs: const [
              PrismTab(label: 'A long first tab'),
              PrismTab(label: 'A long second tab'),
              PrismTab(label: 'A long third tab'),
              PrismTab(label: 'A long fourth tab'),
            ],
            children: const [Text('a'), Text('b'), Text('c'), Text('d')],
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('rejects a mismatched child count', (tester) async {
      await tester.pumpWidget(
        host(
          PrismTabs(
            index: 0,
            onChanged: (_) {},
            tabs: const [
              PrismTab(label: 'One'),
              PrismTab(label: 'Two'),
            ],
            children: const [Text('only one')],
          ),
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });
  });

  group('PrismAccordion', () {
    Widget accordion({
      bool single = false,
      void Function(Set<int>)? onChanged,
    }) => PrismAccordion(
      singleExpansion: single,
      onExpansionChanged: onChanged,
      sections: const [
        PrismAccordionSection(
          title: 'Delivery',
          child: Text('Delivered in 3 days'),
        ),
        PrismAccordionSection(title: 'Returns', child: Text('30 day window')),
      ],
    );

    testWidgets('starts collapsed', (tester) async {
      await tester.pumpWidget(host(accordion()));
      expect(find.text('Delivered in 3 days'), findsNothing);
    });

    testWidgets('expands a section on tap', (tester) async {
      await tester.pumpWidget(host(accordion()));
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();
      expect(find.text('Delivered in 3 days'), findsOneWidget);
    });

    testWidgets('respects initiallyExpanded', (tester) async {
      await tester.pumpWidget(
        host(
          const PrismAccordion(
            sections: [
              PrismAccordionSection(
                title: 'Open by default',
                child: Text('body'),
                initiallyExpanded: true,
              ),
            ],
          ),
        ),
      );
      expect(find.text('body'), findsOneWidget);
    });

    testWidgets('singleExpansion closes the previous section', (tester) async {
      await tester.pumpWidget(host(accordion(single: true)));
      await tester.tap(find.text('Delivery'));
      await tester.pumpAndSettle();
      expect(find.text('Delivered in 3 days'), findsOneWidget);

      await tester.tap(find.text('Returns'));
      await tester.pumpAndSettle();
      expect(find.text('30 day window'), findsOneWidget);
      expect(find.text('Delivered in 3 days'), findsNothing);
    });

    testWidgets('reports the expanded set', (tester) async {
      Set<int>? expanded;
      await tester.pumpWidget(host(accordion(onChanged: (s) => expanded = s)));
      await tester.tap(find.text('Returns'));
      await tester.pumpAndSettle();
      expect(expanded, {1});
    });

    testWidgets('announces whether a section is expanded', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(accordion()));

        Finder header() => find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Delivery',
        );
        expect(
          _flag(tester.getSemantics(header()).flagsCollection.isExpanded),
          isFalse,
        );

        await tester.tap(find.text('Delivery'));
        await tester.pumpAndSettle();
        expect(
          _flag(tester.getSemantics(header()).flagsCollection.isExpanded),
          isTrue,
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('a disabled section cannot be opened', (tester) async {
      await tester.pumpWidget(
        host(
          const PrismAccordion(
            sections: [
              PrismAccordionSection(
                title: 'Locked',
                child: Text('secret'),
                enabled: false,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Locked'));
      await tester.pumpAndSettle();
      expect(find.text('secret'), findsNothing);
    });
  });

  group('PrismCalendar', () {
    final august = DateTime(2026, 8);

    Widget calendar({
      Set<DateTime> selected = const {},
      ValueChanged<DateTime>? onDaySelected,
      ValueChanged<DateTime>? onMonthChanged,
      PrismDateSelection selection = PrismDateSelection.single,
      Set<DateTime> markers = const {},
    }) => PrismCalendar(
      month: august,
      selected: selected,
      selection: selection,
      markers: markers,
      today: DateTime(2026, 8, 15),
      onDaySelected: onDaySelected ?? (_) {},
      onMonthChanged: onMonthChanged,
    );

    testWidgets('shows the month and every day', (tester) async {
      await tester.pumpWidget(host(calendar()));
      expect(find.text('August 2026'), findsOneWidget);
      // August 2026 has 31 days.
      expect(find.text('31'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('reports the tapped day', (tester) async {
      DateTime? picked;
      await tester.pumpWidget(host(calendar(onDaySelected: (d) => picked = d)));

      await tester.tap(find.text('12'));
      await tester.pump();
      expect(picked, DateTime(2026, 8, 12));
    });

    testWidgets('navigates months', (tester) async {
      DateTime? changed;
      await tester.pumpWidget(
        host(calendar(onMonthChanged: (m) => changed = m)),
      );

      await tester.tap(find.byTooltip('Next month'));
      await tester.pump();
      expect(changed, DateTime(2026, 9));
    });

    testWidgets('disables the month arrows when navigation is not allowed', (
      tester,
    ) async {
      await tester.pumpWidget(host(calendar()));
      // The tooltip stays on the button, so assert the disabled state: the
      // arrows remain for layout stability but cannot be pressed.
      final next = tester.widget<IconButton>(
        find.ancestor(
          of: find.byIcon(Icons.chevron_right),
          matching: find.byType(IconButton),
        ),
      );
      expect(next.onPressed, isNull);
    });

    testWidgets('announces a full date, not just the day number', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(host(calendar()));

        final day = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label ?? '').startsWith('15 August 2026'),
        );
        expect(day, findsOneWidget);
        expect(tester.getSemantics(day).label, contains('today'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('range mode marks the endpoints and the days between', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(
            calendar(
              selection: PrismDateSelection.range,
              selected: {DateTime(2026, 8, 5), DateTime(2026, 8, 9)},
            ),
          ),
        );

        Finder day(String prefix) => find.byWidgetPredicate(
          (w) =>
              w is Semantics && (w.properties.label ?? '').startsWith(prefix),
        );

        expect(
          tester.getSemantics(day('5 August')).label,
          contains('range start'),
        );
        expect(
          tester.getSemantics(day('9 August')).label,
          contains('range end'),
        );
        expect(
          _flag(
            tester.getSemantics(day('7 August')).flagsCollection.isSelected,
          ),
          isTrue,
        );
        expect(
          _flag(
            tester.getSemantics(day('12 August')).flagsCollection.isSelected,
          ),
          isFalse,
        );
      } finally {
        handle.dispose();
      }
    });

    testWidgets('respects firstDate and lastDate', (tester) async {
      await tester.pumpWidget(
        host(
          PrismCalendar(
            month: august,
            selected: const {},
            today: DateTime(2026, 8, 15),
            firstDate: DateTime(2026, 8, 10),
            lastDate: DateTime(2026, 8, 20),
            onDaySelected: (_) {},
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('marks days that have events', (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          host(calendar(markers: {DateTime(2026, 8, 20)})),
        );

        final day = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              (w.properties.label ?? '').startsWith('20 August 2026'),
        );
        expect(tester.getSemantics(day).label, contains('has events'));
      } finally {
        handle.dispose();
      }
    });

    testWidgets('supports localised month and weekday names', (tester) async {
      await tester.pumpWidget(
        host(
          PrismCalendar(
            month: august,
            selected: const {},
            today: DateTime(2026, 8, 15),
            monthNames: const [
              'Januar',
              'Februar',
              'März',
              'April',
              'Mai',
              'Juni',
              'Juli',
              'August',
              'September',
              'Oktober',
              'November',
              'Dezember',
            ],
            weekdayLabels: const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
            onDaySelected: (_) {},
          ),
        ),
      );

      expect(find.text('August 2026'), findsOneWidget);
      expect(find.text('Mo'), findsOneWidget);
    });

    testWidgets('starts the week on the requested day', (tester) async {
      await tester.pumpWidget(
        host(
          PrismCalendar(
            month: august,
            selected: const {},
            today: DateTime(2026, 8, 15),
            firstWeekday: DateTime.sunday,
            onDaySelected: (_) {},
          ),
        ),
      );

      expect(find.text(PrismCalendar.defaultWeekdayLabels[6]), findsOneWidget);
    });
  });
}
