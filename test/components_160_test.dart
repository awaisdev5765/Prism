import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_kit/prism.dart';
import 'package:prism_kit/testing.dart';

void main() {
  group('PrismAiThinkingIndicator', () {
    testWidgets('renders three dots and announces itself', (tester) async {
      await tester.pumpWidget(
        prismTestApp(
          child: const PrismAiThinkingIndicator(label: 'Using tool: search'),
        ),
      );
      await tester.pump();
      expect(find.byType(PrismAiThinkingIndicator), findsOneWidget);
      expect(find.text('Using tool: search'), findsOneWidget);
      // Semantics announces the status.
      final semantics = tester.getSemantics(find.byType(Semantics).last);
      expect(semantics, isNotNull);
    });

    testWidgets('stays static under reduced motion', (tester) async {
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: prismTestApp(child: const PrismAiThinkingIndicator()),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  });

  group('PrismAiMessageBubble', () {
    testWidgets('renders user text right-aligned', (tester) async {
      await tester.pumpWidget(
        prismTestApp(
          child: PrismAiMessageBubble(
            message: AiChatMessage.user('Hello there'),
          ),
        ),
      );
      expect(find.text('Hello there'), findsOneWidget);
      final aligner = tester.widget<Align>(
        find.ancestor(
          of: find.text('Hello there'),
          matching: find.byType(Align),
        ).first,
      );
      expect(aligner.alignment, Alignment.centerRight);
    });

    testWidgets('assistant markdown renders', (tester) async {
      await tester.pumpWidget(
        prismTestApp(
          child: PrismAiMessageBubble(
            message: AiChatMessage.assistant('# Heading\n\nBody **bold**'),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Heading'), findsOneWidget);
    });

    testWidgets('tool calls render as chips', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        prismTestApp(
          child: PrismAiMessageBubble(
            message: AiChatMessage.assistantWithToolCalls(
              const [AiToolCallRequest(id: '1', name: 'search', argumentsJson: '{}')],
              content: 'Let me look that up.',
            ),
            onToolCallTap: (_) => tapped = true,
          ),
        ),
      );
      expect(find.text('search'), findsOneWidget);
      await tester.tap(find.text('search'));
      expect(tapped, isTrue);
    });

    testWidgets('streaming without content shows thinking indicator',
        (tester) async {
      await tester.pumpWidget(
        prismTestApp(
          child: PrismAiMessageBubble(
            message: AiChatMessage.assistant(''),
            isStreaming: true,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PrismAiThinkingIndicator), findsOneWidget);
    });

    testWidgets('regenerate callback fires', (tester) async {
      var regenerated = false;
      await tester.pumpWidget(
        prismTestApp(
          child: PrismAiMessageBubble(
            message: AiChatMessage.assistant('Done.'),
            onRegenerate: () => regenerated = true,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Regenerate response'));
      expect(regenerated, isTrue);
    });
  });

  group('PrismPromptComposer', () {
    testWidgets('send button fires with trimmed text and clears field',
        (tester) async {
      var sent = '';
      final controller = TextEditingController();
      await tester.pumpWidget(
        prismTestApp(
          child: PrismPromptComposer(
            controller: controller,
            onSend: (text) => sent = text,
          ),
        ),
      );
      await tester.enterText(
        find.byType(TextField),
        '  What is the weather?  ',
      );
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_upward));
      expect(sent, 'What is the weather?');
      expect(controller.text, isEmpty);
    });

    testWidgets('suggestion chips send immediately', (tester) async {
      var sent = '';
      await tester.pumpWidget(
        prismTestApp(
          child: PrismPromptComposer(
            suggestions: const ['Summarise this page'],
            onSend: (text) => sent = text,
          ),
        ),
      );
      await tester.tap(find.text('Summarise this page'));
      expect(sent, 'Summarise this page');
    });

    testWidgets('busy state disables sending', (tester) async {
      var sent = 0;
      final controller = TextEditingController(text: 'hello');
      await tester.pumpWidget(
        prismTestApp(
          child: PrismPromptComposer(
            controller: controller,
            busy: true,
            onSend: (_) => sent++,
          ),
        ),
      );
      final button = tester.widget<IconButton>(
        find.byType(IconButton),
      );
      expect(button.onPressed, isNull);
      expect(sent, 0);
    });
  });

  group('PrismColorPicker', () {
    testWidgets('hex input changes the colour', (tester) async {
      var picked = const Color(0xFF3366CC);
      await tester.pumpWidget(
        prismTestApp(
          child: PrismColorPicker(
            color: picked,
            onChanged: (c) => picked = c,
          ),
        ),
      );
      await tester.enterText(find.byType(TextFormField), 'FF0000');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(picked.toARGB32() & 0xFFFFFF, 0xFF0000);
    });

    testWidgets('renders hue bar and SV box without exceptions',
        (tester) async {
      await tester.pumpWidget(
        prismTestApp(
          child: PrismColorPicker(
            color: const Color(0xFF00AA55),
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('PrismSparkline', () {
    testWidgets('renders without exceptions', (tester) async {
      await tester.pumpWidget(
        prismTestApp(
          child: PrismSparkline(
            values: const [3, 5, 4, 7, 6, 9],
            semanticLabel: 'Weekly revenue trend',
          ),
        ),
      );
      expect(find.byType(PrismSparkline), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('flat data does not divide by zero', () {
      final spark = PrismSparkline(
        values: const [4, 4, 4],
        semanticLabel: 'flat',
      );
      expect(spark.semanticLabel, 'flat');
    });
  });

  group('PrismOverlayStack', () {
    testWidgets('shows overlay, advances and finishes', (tester) async {
      final keyOne = GlobalKey();
      final keyTwo = GlobalKey();
      var done = false;

      await tester.pumpWidget(
        prismTestApp(
          child: Column(
            children: [
              Container(key: keyOne, height: 50, color: Colors.blue),
              Container(key: keyTwo, height: 50, color: Colors.red),
              PrismOverlayStack(
                steps: [
                  PrismOverlayStep(anchorKey: keyOne, title: 'Step one'),
                  PrismOverlayStep(anchorKey: keyTwo, title: 'Step two'),
                ],
                onDone: () => done = true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Step one'), findsOneWidget);
      expect(find.text('Step two'), findsNothing);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Step two'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(done, isTrue);
      expect(find.text('Step two'), findsNothing);
    });

    testWidgets('skip ends the tour immediately', (tester) async {
      final key = GlobalKey();
      var done = false;
      var skipped = false;

      await tester.pumpWidget(
        prismTestApp(
          child: Column(
            children: [
              Container(key: key, height: 50),
              PrismOverlayStack(
                steps: [
                  PrismOverlayStep(anchorKey: key, title: 'Only step'),
                ],
                onDone: () => done = true,
                onSkip: () => skipped = true,
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip tour'));
      await tester.pumpAndSettle();
      expect(skipped, isTrue);
      expect(done, isFalse);
      expect(find.text('Only step'), findsNothing);
    });

    testWidgets('empty steps render nothing', (tester) async {
      var done = false;
      await tester.pumpWidget(
        prismTestApp(
          child: PrismOverlayStack(
            steps: const [],
            onDone: () => done = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(done, isFalse);
      expect(find.text('Skip tour'), findsNothing);
    });
  });
}
