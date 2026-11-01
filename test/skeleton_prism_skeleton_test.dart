import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders a block with the requested size', (tester) async {
    await tester.pumpWidget(
      host(const PrismSkeleton(width: 120, height: 24)),
    );
    final container = tester.widget<Container>(find.byType(Container).first);
    expect(container.constraints?.maxWidth, 120);
  });

  testWidgets('static mode does not animate', (tester) async {
    await tester.pumpWidget(
      host(const PrismSkeleton(width: 50, height: 10, animate: false)),
    );
    // A static skeleton is a plain Container — no ShaderMask shimmer.
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('animating mode wraps content in a ShaderMask', (tester) async {
    await tester.pumpWidget(host(const PrismSkeleton(width: 50, height: 10)));
    await tester.pump();
    expect(find.byType(ShaderMask), findsOneWidget);
  });

  testWidgets('reduced motion disables the shimmer', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: host(const PrismSkeleton(width: 50, height: 10)),
      ),
    );
    await tester.pump();
    expect(find.byType(ShaderMask), findsNothing);
  });

  testWidgets('circle constructor produces equal width and height',
      (tester) async {
    await tester.pumpWidget(host(const PrismSkeleton.circle(diameter: 44)));
    final container = tester.widget<Container>(find.byType(Container).first);
    expect(container.constraints?.maxWidth, 44);
    expect(container.constraints?.maxHeight, 44);
  });

  testWidgets('text variant renders one block per line', (tester) async {
    await tester.pumpWidget(
      host(const PrismSkeletonText(lines: 4, spacing: 4)),
    );
    expect(find.byType(PrismSkeleton), findsNWidgets(4));
  });

  testWidgets('card variant renders media plus body lines', (tester) async {
    await tester.pumpWidget(
      host(const PrismSkeletonCard(mediaHeight: 100, lines: 2)),
    );
    expect(find.byType(PrismSkeleton), findsNWidgets(3)); // 1 media + 2 lines
  });

  testWidgets('card variant can omit the media area', (tester) async {
    await tester.pumpWidget(
      host(const PrismSkeletonCard(mediaHeight: 0, lines: 2)),
    );
    expect(find.byType(PrismSkeleton), findsNWidgets(2));
  });

  testWidgets('list.cards honours the count', (tester) async {
    await tester.pumpWidget(
      host(const PrismSkeletonList.cards(count: 3, mediaHeight: 0)),
    );
    expect(find.byType(PrismSkeletonCard), findsNWidgets(3));
  });

  testWidgets('list.tiles renders avatar rows', (tester) async {
    await tester.pumpWidget(host(const PrismSkeletonList.tiles(count: 4)));
    expect(find.byType(PrismSkeleton), findsWidgets);
  });

  testWidgets('toggling animate off stops the shimmer', (tester) async {
    await tester.pumpWidget(host(const PrismSkeleton(height: 10)));
    await tester.pump();
    expect(find.byType(ShaderMask), findsOneWidget);

    await tester.pumpWidget(
      host(const PrismSkeleton(height: 10, animate: false)),
    );
    await tester.pump();
    expect(find.byType(ShaderMask), findsNothing);
  });
}
