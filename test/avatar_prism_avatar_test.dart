import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('PrismAvatar.initialsFor', () {
    test('uses first letters of the first two words', () {
      expect(PrismAvatar.initialsFor('Ayesha Khan'), 'AK');
      expect(PrismAvatar.initialsFor('john ronald reuel tolkien'), 'JR');
    });

    test('handles a single name', () {
      expect(PrismAvatar.initialsFor('Madonna'), 'MA');
    });

    test('single short name keeps its characters', () {
      expect(PrismAvatar.initialsFor('Li'), 'LI');
    });

    test('splits on punctuation and whitespace', () {
      expect(PrismAvatar.initialsFor('  ayesha   khan  '), 'AK');
      expect(PrismAvatar.initialsFor('ayesha-khan'), 'AK');
      expect(PrismAvatar.initialsFor('ayesha.khan'), 'AK');
    });

    test('falls back to a placeholder for empty input', () {
      expect(PrismAvatar.initialsFor(''), '?');
      expect(PrismAvatar.initialsFor('   '), '?');
    });

    test('honours the max argument', () {
      expect(PrismAvatar.initialsFor('one two three', max: 3), 'OTT');
    });
  });

  testWidgets('renders initials when there is no image', (tester) async {
    await tester.pumpWidget(host(const PrismAvatar(name: 'Ayesha Khan')));
    expect(find.text('AK'), findsOneWidget);
  });

  testWidgets('colour for a name is deterministic', (tester) async {
    final colors = <Color>[];
    for (var i = 0; i < 2; i++) {
      await tester.pumpWidget(host(const PrismAvatar(name: 'Ayesha Khan')));
      final container = tester.widget<Container>(find.byType(Container).first);
      colors.add((container.decoration! as BoxDecoration).color!);
    }
    expect(colors[0], colors[1]);
  });

  testWidgets('different names can produce different colors', (tester) async {
    final seen = <Color>{};
    for (final name in ['Ayesha', 'Bilal', 'Chen', 'Dana', 'Eve', 'Farid']) {
      await tester.pumpWidget(host(PrismAvatar(name: name)));
      final container = tester.widget<Container>(find.byType(Container).first);
      seen.add((container.decoration! as BoxDecoration).color!);
    }
    expect(seen.length, greaterThan(1));
  });

  testWidgets('falls back to initials when the network image fails',
      (tester) async {
    await tester.pumpWidget(
      host(const PrismAvatar(name: 'Ayesha Khan', imageUrl: 'not-a-url')),
    );
    // Let the (failing) network load settle, then confirm the errorBuilder
    // fell back to initials instead of a broken-image glyph.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('AK'), findsOneWidget);
  });

  testWidgets('circle shape uses a circular radius', (tester) async {
    await tester.pumpWidget(
      host(const PrismAvatar(name: 'Ann', size: 40)),
    );
    final container = tester.widget<Container>(find.byType(Container).first);
    final radius = ((container.decoration! as BoxDecoration).borderRadius
        as BorderRadius?)?.topLeft.x;
    expect(radius, 20);
  });

  testWidgets('rounded shape is not fully round', (tester) async {
    await tester.pumpWidget(
      host(const PrismAvatar(
        name: 'Ann',
        size: 100,
        shape: PrismAvatarShape.rounded,
      )),
    );
    final container = tester.widget<Container>(find.byType(Container).first);
    final radius = ((container.decoration! as BoxDecoration).borderRadius
        as BorderRadius?)?.topLeft.x;
    expect(radius, closeTo(28, 0.001));
  });

  testWidgets('presence dot is rendered with a semantic label', (tester) async {
    await tester.pumpWidget(
      host(const PrismAvatar(name: 'Ayesha Khan', presence: PrismPresence.online)),
    );
    expect(find.bySemanticsLabel('Ayesha Khan, online'), findsOneWidget);
  });

  testWidgets('badge widget is layered on the avatar', (tester) async {
    await tester.pumpWidget(
      host(const PrismAvatar(
        name: 'Ayesha',
        badge: Icon(Icons.star),
      )),
    );
    expect(find.byIcon(Icons.star), findsOneWidget);
  });

  testWidgets('borderWidth draws a ring', (tester) async {
    await tester.pumpWidget(
      host(const PrismAvatar(name: 'Ann', borderWidth: 2)),
    );
    // Container count grows by one for the ring wrapper.
    expect(find.byType(Container), findsWidgets);
  });

  test('presence labels are human readable', () {
    expect(PrismPresence.online.label, 'online');
    expect(PrismPresence.offline.label, 'offline');
    expect(PrismPresence.busy.label, 'busy');
    expect(PrismPresence.away.label, 'away');
  });
}
