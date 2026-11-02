import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders one box per digit', (tester) async {
    await tester.pumpWidget(host(const PrismOtpField(length: 4)));
    // Digit boxes are AnimatedContainers inside the decorative Wrap.
    expect(find.byType(AnimatedContainer), findsNWidgets(4));
  });

  testWidgets('typing fills the boxes left to right', (tester) async {
    await tester.pumpWidget(
      host(const PrismOtpField(length: 4, autofocus: true)),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('reports partial input through onChanged', (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(
      host(PrismOtpField(length: 4, onChanged: seen.add, autofocus: true)),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '12');
    await tester.pump();
    expect(seen.last, '12');
  });

  testWidgets('fires onCompleted only when the field is full', (tester) async {
    final completed = <String>[];
    await tester.pumpWidget(
      host(
        PrismOtpField(
          length: 4,
          onChanged: (_) {},
          onCompleted: completed.add,
          autofocus: true,
        ),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), '12');
    await tester.pump();
    expect(completed, isEmpty);

    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    expect(completed, ['1234']);
  });

  testWidgets('a pasted code fills every box at once', (tester) async {
    final completed = <String>[];
    await tester.pumpWidget(
      host(
        PrismOtpField(length: 6, onCompleted: completed.add, autofocus: true),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '987654');
    await tester.pump();
    expect(completed, ['987654']);
  });

  testWidgets('non-digits are stripped by the input formatter', (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(
      host(PrismOtpField(length: 4, onChanged: seen.add, autofocus: true)),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '1a2b');
    await tester.pump();
    expect(seen.last, '12');
  });

  testWidgets('length limits the input', (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(
      host(PrismOtpField(length: 3, onChanged: seen.add, autofocus: true)),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pump();
    expect(seen.last.length, lessThanOrEqualTo(3));
  });

  testWidgets('obscure mode hides the digits', (tester) async {
    await tester.pumpWidget(
      host(const PrismOtpField(length: 4, obscure: true, autofocus: true)),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    expect(find.text('1'), findsNothing);
    // Bullets are drawn as Containers, so the digits never hit the tree.
  });

  testWidgets('errorText is displayed and styled', (tester) async {
    await tester.pumpWidget(
      host(const PrismOtpField(length: 4, errorText: 'Invalid code')),
    );
    expect(find.text('Invalid code'), findsOneWidget);
  });

  testWidgets('helperText shows when there is no error', (tester) async {
    await tester.pumpWidget(
      host(const PrismOtpField(length: 4, helperText: 'Sent to •••1234')),
    );
    expect(find.text('Sent to •••1234'), findsOneWidget);
  });

  testWidgets('disabled field rejects input', (tester) async {
    final seen = <String>[];
    await tester.pumpWidget(
      host(
        PrismOtpField(
          length: 4,
          enabled: false,
          onChanged: seen.add,
          autofocus: true,
        ),
      ),
    );
    await tester.pump();
    await tester.enterText(find.byType(TextField), '1234');
    await tester.pump();
    expect(seen, isEmpty);
  });

  testWidgets('accepts an external controller and reflects its value', (
    tester,
  ) async {
    final controller = TextEditingController(text: '12');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      host(PrismOtpField(length: 4, controller: controller)),
    );
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('group separator widens the gap', (tester) async {
    await tester.pumpWidget(
      host(const PrismOtpField(length: 6, groupSeparatorAfter: 3)),
    );
    expect(find.byType(SizedBox), findsWidgets);
  });

  testWidgets('custom boxBuilder replaces the default box', (tester) async {
    await tester.pumpWidget(
      host(
        PrismOtpField(
          length: 3,
          boxBuilder: (context, index, char, focused) => Text('box$index'),
        ),
      ),
    );
    expect(find.text('box0'), findsOneWidget);
    expect(find.text('box2'), findsOneWidget);
  });
}
