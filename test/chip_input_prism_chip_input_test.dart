import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('shows the current chips', (tester) async {
    await tester.pumpWidget(
      host(PrismChipInput(
        value: const ['work', 'urgent'],
        onChanged: (_) {},
      )),
    );
    expect(find.text('work'), findsOneWidget);
    expect(find.text('urgent'), findsOneWidget);
  });

  testWidgets('submitting the field adds a chip', (tester) async {
    List<String>? changed;
    await tester.pumpWidget(
      host(PrismChipInput(value: const [], onChanged: (v) => changed = v)),
    );
    await tester.enterText(find.byType(TextField), 'reading');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(changed, ['reading']);
  });

  testWidgets('trims surrounding whitespace', (tester) async {
    List<String>? changed;
    await tester.pumpWidget(
      host(PrismChipInput(value: const [], onChanged: (v) => changed = v)),
    );
    await tester.enterText(find.byType(TextField), '  spaced  ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(changed, ['spaced']);
  });

  testWidgets('ignores empty submissions', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      host(PrismChipInput(value: const [], onChanged: (_) => calls++)),
    );
    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('rejects duplicates case-insensitively', (tester) async {
    List<String>? changed;
    await tester.pumpWidget(
      host(PrismChipInput(
        value: const ['Work'],
        onChanged: (v) => changed = v,
      )),
    );
    await tester.enterText(find.byType(TextField), 'work');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(changed, isNull);
    expect(find.textContaining('already added'), findsOneWidget);
  });

  testWidgets('allowDuplicates permits repeated labels', (tester) async {
    List<String>? changed;
    await tester.pumpWidget(
      host(PrismChipInput(
        value: const ['Work'],
        allowDuplicates: true,
        onChanged: (v) => changed = v,
      )),
    );
    await tester.enterText(find.byType(TextField), 'Work');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(changed, ['Work', 'Work']);
  });

  testWidgets('enforces maxChips', (tester) async {
    List<String>? changed;
    await tester.pumpWidget(
      host(PrismChipInput(
        value: const ['a', 'b'],
        maxChips: 2,
        onChanged: (v) => changed = v,
      )),
    );
    await tester.enterText(find.byType(TextField), 'c');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(changed, isNull);
    expect(find.text('Maximum reached'), findsOneWidget);
  });

  testWidgets('splits pasted comma-separated values', (tester) async {
    List<String>? changed;
    await tester.pumpWidget(
      host(PrismChipInput(value: const [], onChanged: (v) => changed = v)),
    );
    // Enter a comma in the text field: the listener commits the prefix.
    await tester.enterText(find.byType(TextField), 'one,');
    await tester.pump();
    expect(changed, ['one']);
  });

  testWidgets('removing a chip calls onChanged', (tester) async {
    List<String>? changed;
    await tester.pumpWidget(
      host(PrismChipInput(
        value: const ['alpha', 'beta'],
        onChanged: (v) => changed = v,
      )),
    );
    final removeAlpha = find.bySemanticsLabel('Remove alpha');
    await tester.tap(removeAlpha);
    await tester.pump();
    expect(changed, ['beta']);
  });

  testWidgets('custom validator rejects a value', (tester) async {
    List<String>? changed;
    await tester.pumpWidget(
      host(PrismChipInput(
        value: const [],
        onChanged: (v) => changed = v,
        validator: (v) => v.contains('@') ? null : 'No emails please',
      )),
    );
    await tester.enterText(find.byType(TextField), 'plain');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(changed, isNull);
    expect(find.text('No emails please'), findsOneWidget);
  });

  testWidgets('suggestions appear on focus and can be tapped', (tester) async {
    List<String>? changed;
    await tester.pumpWidget(
      host(PrismChipInput(
        value: const [],
        suggestions: const ['work', 'personal'],
        onChanged: (v) => changed = v,
      )),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    expect(find.text('personal'), findsOneWidget);

    await tester.tap(find.text('personal'));
    await tester.pump();
    expect(changed, ['personal']);
  });

  testWidgets('already-added suggestions are filtered out', (tester) async {
    await tester.pumpWidget(
      host(PrismChipInput(
        value: const ['work'],
        suggestions: const ['work', 'personal'],
        onChanged: (_) {},
      )),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();
    // 'work' appears once as a chip, never as a suggestion chip.
    expect(find.text('personal'), findsOneWidget);
    expect(find.text('work'), findsOneWidget);
  });

  testWidgets('external errorText is displayed', (tester) async {
    await tester.pumpWidget(
      host(PrismChipInput(
        value: const [],
        errorText: 'Too many tags',
        onChanged: (_) {},
      )),
    );
    expect(find.text('Too many tags'), findsOneWidget);
  });

  testWidgets('custom chipBuilder replaces default rendering', (tester) async {
    await tester.pumpWidget(
      host(PrismChipInput(
        value: const ['custom'],
        onChanged: (_) {},
        chipBuilder: (context, label, remove) => Text('»$label«'),
      )),
    );
    expect(find.text('»custom«'), findsOneWidget);
  });
}
