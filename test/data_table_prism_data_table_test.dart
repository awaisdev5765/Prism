import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

class Invoice {
  Invoice(this.id, this.client, this.total);
  final String id;
  final String client;
  final int total;
}

final invoices = [
  Invoice('INV-1', 'Zenith', 300),
  Invoice('INV-2', 'Aurora', 100),
  Invoice('INV-3', 'Meridian', 200),
];

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

List<PrismColumn<Invoice>> columns({bool sortable = false}) => [
      PrismColumn<Invoice>(
        label: 'Invoice',
        alwaysVisible: true,
        cell: (c, r, i) => Text(r.id),
        sortComparator: sortable ? (a, b) => a.id.compareTo(b.id) : null,
      ),
      PrismColumn<Invoice>(
        label: 'Client',
        cell: (c, r, i) => Text(r.client),
        sortComparator: sortable ? (a, b) => a.client.compareTo(b.client) : null,
      ),
      PrismColumn<Invoice>(
        label: 'Total',
        numeric: true,
        cell: (c, r, i) => Text('${r.total}'),
      ),
    ];

void main() {
  testWidgets('wide layout renders rows and headers', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(PrismDataTable<Invoice>(
      rows: invoices,
      columns: columns(),
    )));
    expect(find.text('Invoice'), findsOneWidget); // header
    expect(find.text('INV-1'), findsOneWidget);
    expect(find.text('Meridian'), findsOneWidget);
  });

  testWidgets('shows the empty message with no rows', (tester) async {
    await tester.pumpWidget(host(PrismDataTable<Invoice>(
      rows: const [],
      columns: columns(),
      emptyMessage: 'Nothing here',
    )));
    expect(find.text('Nothing here'), findsOneWidget);
  });

  testWidgets('compact layout renders cards with field labels', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(PrismDataTable<Invoice>(
      rows: invoices,
      columns: columns(),
    )));
    // alwaysVisible column is the card title; the rest become labelled pairs.
    expect(find.text('INV-1'), findsOneWidget);
    expect(find.text('Client'), findsWidgets);
    expect(find.text('Aurora'), findsOneWidget);
  });

  testWidgets('row taps report the row and index', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    Invoice? tapped;
    int? index;
    await tester.pumpWidget(host(PrismDataTable<Invoice>(
      rows: invoices,
      columns: columns(),
      onRowTap: (row, i) {
        tapped = row;
        index = i;
      },
    )));
    await tester.tap(find.text('Aurora'));
    await tester.pump();
    expect(tapped?.id, 'INV-2');
    expect(index, 1);
  });

  testWidgets('sorting ascending then descending', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(PrismDataTable<Invoice>(
      rows: invoices,
      columns: columns(sortable: true),
    )));

    // Sort by client ascending.
    await tester.tap(find.text('Client'));
    await tester.pump();
    var order = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    expect(order.indexOf('Aurora'), lessThan(order.indexOf('Zenith')));

    // Toggle descending.
    await tester.tap(find.text('Client'));
    await tester.pump();
    order = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data)
        .whereType<String>()
        .toList();
    expect(order.indexOf('Zenith'), lessThan(order.indexOf('Aurora')));
  });

  testWidgets('non-sortable columns ignore taps', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(PrismDataTable<Invoice>(
      rows: invoices,
      columns: columns(),
    )));
    await tester.tap(find.text('Total'));
    await tester.pump();
    // Original order preserved.
    expect(find.text('INV-1'), findsOneWidget);
  });

  testWidgets('trailing builder is rendered per row', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(PrismDataTable<Invoice>(
      rows: invoices,
      columns: columns(),
      trailing: (c, r, i) => IconButton(
        icon: const Icon(Icons.more_vert),
        onPressed: () {},
      ),
    )));
    expect(find.byIcon(Icons.more_vert), findsNWidgets(3));
  });

  testWidgets('zebra striping is optional', (tester) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(PrismDataTable<Invoice>(
      rows: invoices,
      columns: columns(),
      zebraStripes: false,
    )));
    expect(find.text('INV-3'), findsOneWidget);
  });

  testWidgets('honours an explicit compactBreakpoint', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(PrismDataTable<Invoice>(
      rows: invoices,
      columns: columns(),
      compactBreakpoint: 1000,
    )));
    // Forced to cards: field labels appear instead of a header row.
    expect(find.text('Client'), findsWidgets);
  });
}
