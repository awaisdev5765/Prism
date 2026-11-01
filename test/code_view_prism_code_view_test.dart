import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism/prism.dart';

class MyTokenizer extends LanguageTokenizer {
  @override
  List<CodeToken> tokenize(String code) => [CodeToken(code, TokenKind.keyword)];
}

void main() {
  group('PrismCodeView rendering', () {
    Future<void> pumpCode(
      WidgetTester tester,
      String code, {
      PrismLanguage language = PrismLanguage.other,
      LanguageTokenizer? tokenizer,
      PrismCodeViewStyle? style,
      bool? showLineNumbers,
      bool? enableCopy,
      bool? wrap,
      double? maxHeight,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PrismCodeView(
              code: code,
              language: language,
              tokenizer: tokenizer,
              style: style,
              showLineNumbers: showLineNumbers,
              enableCopy: enableCopy,
              wrap: wrap,
              maxHeight: maxHeight,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders plain code', (tester) async {
      await pumpCode(tester, 'hello world');
      expect(find.textContaining('hello world'), findsOneWidget);
    });

    testWidgets('renders dart keywords with highlight', (tester) async {
      await pumpCode(tester, 'void main() {}', language: PrismLanguage.dart);
      expect(find.textContaining('void main()'), findsOneWidget);
    });

    testWidgets('renders json with highlight', (tester) async {
      await pumpCode(
        tester,
        '{"a": 1, "b": true}',
        language: PrismLanguage.json,
      );
      expect(find.textContaining('"a"'), findsOneWidget);
    });

    testWidgets('shows line numbers when enabled', (tester) async {
      await pumpCode(tester, 'line1\nline2', showLineNumbers: true);
      // The gutter renders each line number as its own Text widget.
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('hides line numbers by default', (tester) async {
      await pumpCode(tester, 'line1\nline2');
      // The gutter is absent; the code text itself does not exactly match.
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
    });

    testWidgets('shows copy button when enabled', (tester) async {
      await pumpCode(tester, 'some code');
      expect(find.byTooltip('Copy to clipboard'), findsOneWidget);
    });

    testWidgets('hides copy button when disabled', (tester) async {
      await pumpCode(tester, 'some code', enableCopy: false);
      expect(find.byTooltip('Copy to clipboard'), findsNothing);
    });

    testWidgets('custom tokenizer is used', (tester) async {
      await pumpCode(tester, 'custom code', tokenizer: MyTokenizer());
      expect(find.textContaining('custom code'), findsOneWidget);
    });

    testWidgets('constrains max height and scrolls', (tester) async {
      await pumpCode(tester, 'line\n' * 100, maxHeight: 100);
      expect(find.byType(Scrollbar), findsNothing);
      // Container should exist with scroll.
      expect(find.byType(SingleChildScrollView), findsWidgets);
    });
  });

  group('Tokenizer', () {
    test('DartTokenizer tokenizes keywords', () {
      final tokens = DartTokenizer().tokenize('final x = 1;');
      expect(
        tokens.any((t) => t.text == 'final' && t.kind == TokenKind.keyword),
        isTrue,
      );
      expect(tokens.any((t) => t.kind == TokenKind.number), isTrue);
      expect(tokens.any((t) => t.kind == TokenKind.punctuation), isTrue);
    });

    test('DartTokenizer handles strings', () {
      final tokens = DartTokenizer().tokenize("final s = 'hello';");
      expect(
        tokens.any(
          (t) => t.text.contains('hello') && t.kind == TokenKind.string,
        ),
        isTrue,
      );
    });

    test('DartTokenizer handles comments', () {
      final tokens = DartTokenizer().tokenize('// comment\nfinal x = 1;');
      expect(
        tokens.any(
          (t) => t.text.contains('comment') && t.kind == TokenKind.comment,
        ),
        isTrue,
      );
    });

    test('JsonTokenizer tokenizes booleans', () {
      final tokens = JsonTokenizer().tokenize('{"a": true}');
      expect(
        tokens.any((t) => t.text == 'true' && t.kind == TokenKind.keyword),
        isTrue,
      );
    });

    test('YamlTokenizer tokenizes comments and booleans', () {
      final tokens = YamlTokenizer().tokenize('# comment\nvalue: true');
      expect(
        tokens.any(
          (t) => t.text.contains('comment') && t.kind == TokenKind.comment,
        ),
        isTrue,
      );
      expect(
        tokens.any((t) => t.text == 'true' && t.kind == TokenKind.keyword),
        isTrue,
      );
    });

    test('Tokenizers preserve all input text', () {
      const source = 'final x = 1; // comment\nvar s = "hi";';
      for (final tokenizer in [
        DartTokenizer(),
        JsonTokenizer(),
        YamlTokenizer(),
      ]) {
        final joined = tokenizer.tokenize(source).map((t) => t.text).join();
        expect(joined, source);
      }
    });
  });
}
