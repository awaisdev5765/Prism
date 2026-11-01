import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

List<PrismCommand> commands(List<String> log) => [
      PrismCommand(
        label: 'New note',
        icon: Icons.add,
        group: 'File',
        shortcut: '⌘N',
        onSelect: () => log.add('new'),
      ),
      PrismCommand(
        label: 'Toggle theme',
        icon: Icons.dark_mode,
        group: 'View',
        onSelect: () => log.add('theme'),
      ),
      PrismCommand(
        label: 'Sign out',
        group: 'Account',
        onSelect: () => log.add('out'),
      ),
    ];

void main() {
  testWidgets('lists all commands with group headers', (tester) async {
    await tester.pumpWidget(host(PrismCommandPalette(commands: commands([]))));
    expect(find.text('New note'), findsOneWidget);
    expect(find.text('Toggle theme'), findsOneWidget);
    expect(find.text('FILE'), findsOneWidget);
    expect(find.text('VIEW'), findsOneWidget);
  });

  testWidgets('filters as you type', (tester) async {
    await tester.pumpWidget(host(PrismCommandPalette(commands: commands([]))));
    await tester.enterText(find.byType(TextField), 'theme');
    await tester.pump();
    expect(find.text('Toggle theme'), findsOneWidget);
    expect(find.text('New note'), findsNothing);
  });

  testWidgets('fuzzy subsequence matching finds non-contiguous matches',
      (tester) async {
    await tester.pumpWidget(host(PrismCommandPalette(commands: commands([]))));
    await tester.enterText(find.byType(TextField), 'tt');
    await tester.pump();
    expect(find.text('Toggle theme'), findsOneWidget);
  });

  testWidgets('keywords participate in matching', (tester) async {
    await tester.pumpWidget(host(PrismCommandPalette(
      commands: [
        PrismCommand(
          label: 'Export',
          keywords: const ['download', 'save as'],
          onSelect: () {},
        ),
      ],
    )));
    await tester.enterText(find.byType(TextField), 'download');
    await tester.pump();
    expect(find.text('Export'), findsOneWidget);
  });

  testWidgets('shows the empty message when nothing matches', (tester) async {
    await tester.pumpWidget(host(PrismCommandPalette(commands: commands([]))));
    await tester.enterText(find.byType(TextField), 'zzzzzz');
    await tester.pump();
    expect(find.text('No matching commands'), findsOneWidget);
  });

  testWidgets('tapping a command runs it', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(host(PrismCommandPalette(commands: commands(log))));
    await tester.tap(find.text('Sign out'));
    await tester.pump();
    expect(log, ['out']);
  });

  testWidgets('enter runs the highlighted command', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(host(PrismCommandPalette(commands: commands(log))));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(log, ['new']); // first result is highlighted initially
  });

  testWidgets('arrow down moves the highlight', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(host(PrismCommandPalette(commands: commands(log))));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(log, ['theme']);
  });

  testWidgets('arrow up wraps to the last result', (tester) async {
    final log = <String>[];
    await tester.pumpWidget(host(PrismCommandPalette(commands: commands(log))));
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(log, ['out']);
  });

  testWidgets('onCommandSelected fires before the command itself',
      (tester) async {
    final order = <String>[];
    await tester.pumpWidget(host(PrismCommandPalette(
      commands: [
        PrismCommand(label: 'Go', onSelect: () => order.add('select')),
      ],
      onCommandSelected: (c) => order.add('notified'),
    )));
    await tester.tap(find.text('Go'));
    await tester.pump();
    expect(order, ['notified', 'select']);
  });

  testWidgets('disabled commands are hidden', (tester) async {
    await tester.pumpWidget(host(PrismCommandPalette(
      commands: [
        PrismCommand(label: 'Visible', onSelect: () {}),
        PrismCommand(label: 'Hidden', enabled: false, onSelect: () {}),
      ],
    )));
    expect(find.text('Visible'), findsOneWidget);
    expect(find.text('Hidden'), findsNothing);
  });

  testWidgets('initialQuery pre-filters the list', (tester) async {
    await tester.pumpWidget(host(PrismCommandPalette(
      commands: commands([]),
      initialQuery: 'sign',
    )));
    expect(find.text('Sign out'), findsOneWidget);
    expect(find.text('New note'), findsNothing);
  });

  testWidgets('shortcut hint is rendered', (tester) async {
    await tester.pumpWidget(host(PrismCommandPalette(commands: commands([]))));
    expect(find.text('⌘N'), findsOneWidget);
  });

  testWidgets('show() resolves with the chosen command', (tester) async {
    PrismCommand? chosen;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () async {
                chosen = await PrismCommandPalette.show(
                  context: context,
                  commands: [
                    PrismCommand(label: 'Pick me', onSelect: () {}),
                  ],
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Pick me'), findsOneWidget);

    await tester.tap(find.text('Pick me'));
    await tester.pumpAndSettle();
    expect(chosen?.label, 'Pick me');
  });
}
