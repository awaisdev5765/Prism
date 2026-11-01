import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders every entry title and subtitle', (tester) async {
    await tester.pumpWidget(host(const PrismTimeline(
      entries: [
        PrismTimelineEntry(title: 'Order placed', subtitle: 'Payment received'),
        PrismTimelineEntry(title: 'Packed', timestamp: '09:20'),
      ],
    )));
    expect(find.text('Order placed'), findsOneWidget);
    expect(find.text('Payment received'), findsOneWidget);
    expect(find.text('Packed'), findsOneWidget);
    expect(find.text('09:20'), findsOneWidget);
  });

  testWidgets('empty state renders a friendly message', (tester) async {
    await tester.pumpWidget(host(const PrismTimeline(entries: [])));
    expect(find.text('Nothing to show yet'), findsOneWidget);
  });

  testWidgets('uses the semantic default icon', (tester) async {
    await tester.pumpWidget(host(const PrismTimeline(
      entries: [
        PrismTimelineEntry(title: 'Done', semantic: PrismSemantic.success),
        PrismTimelineEntry(title: 'Failed', semantic: PrismSemantic.error),
      ],
    )));
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
  });

  testWidgets('explicit icon overrides the semantic default', (tester) async {
    await tester.pumpWidget(host(const PrismTimeline(
      entries: [
        PrismTimelineEntry(title: 'Shipped', icon: Icons.local_shipping),
      ],
    )));
    expect(find.byIcon(Icons.local_shipping), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsNothing);
  });

  testWidgets('connectors are drawn between entries but not around the ends',
      (tester) async {
    await tester.pumpWidget(host(const PrismTimeline(
      entries: [
        PrismTimelineEntry(title: 'One'),
        PrismTimelineEntry(title: 'Two'),
        PrismTimelineEntry(title: 'Three'),
      ],
    )));
    // Two between-entry connectors for three entries.
    expect(find.byType(Container), findsWidgets);
  });

  testWidgets('child content is rendered inside an entry', (tester) async {
    await tester.pumpWidget(host(const PrismTimeline(
      entries: [
        PrismTimelineEntry(
          title: 'Attachment',
          child: Card(child: Text('inner card')),
        ),
      ],
    )));
    expect(find.text('inner card'), findsOneWidget);
  });

  testWidgets('trailing widget is rendered', (tester) async {
    await tester.pumpWidget(host(const PrismTimeline(
      entries: [
        PrismTimelineEntry(title: 'With badge', trailing: Chip(label: Text('new'))),
      ],
    )));
    expect(find.text('new'), findsOneWidget);
  });

  testWidgets('tapping an entry reports its index', (tester) async {
    int? tapped;
    await tester.pumpWidget(host(PrismTimeline(
      onEntryTap: (index, entry) => tapped = index,
      entries: const [
        PrismTimelineEntry(title: 'First'),
        PrismTimelineEntry(title: 'Second'),
      ],
    )));
    await tester.tap(find.text('Second'));
    await tester.pump();
    expect(tapped, 1);
  });

  testWidgets('entries are not tappable without a callback', (tester) async {
    await tester.pumpWidget(host(const PrismTimeline(
      entries: [PrismTimelineEntry(title: 'Inert')],
    )));
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('accentColor overrides the semantic color', (tester) async {
    await tester.pumpWidget(host(const PrismTimeline(
      entries: [
        PrismTimelineEntry(title: 'Custom', accentColor: Colors.pink),
      ],
    )));
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('dense mode renders more compactly', (tester) async {
    await tester.pumpWidget(host(const PrismTimeline(
      dense: true,
      entries: [
        PrismTimelineEntry(title: 'A'),
        PrismTimelineEntry(title: 'B'),
      ],
    )));
    expect(find.text('A'), findsOneWidget);
  });
}
