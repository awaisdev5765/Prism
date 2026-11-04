import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

/// Parsers are where arbitrary input meets a hand-written state machine, and
/// Prism has several: structured model output, a changelog format, version
/// strings, and a markdown renderer.
///
/// These tests feed them hostile input — unbalanced delimiters, deep nesting,
/// control characters, lone surrogates, RTL text, megabyte strings — and assert
/// the property that matters: **they never throw an unexpected error**. A parser
/// that crashes on one malformed response takes down the screen that called it.
///
/// The corpus is seeded, so a failure is reproducible, and it runs without a
/// property-testing dependency.
void main() {
  // Generated inputs, named so the map below reads as a list of cases rather
  // than a pile of expressions.
  final deepNest = '${'[' * 200}1${']' * 200}';
  final markdownHeadingBomb = '# ${'#' * 200} heading';
  final markdownListBomb = '- item\n' * 200;
  final markdownLinkBomb = '[${'[' * 100}x${']' * 100}](y)';

  /// Inputs chosen for a specific reason, not at random.
  final corpus = <String, String>{
    'empty': '',
    'whitespace': '   \n\t  ',
    'lone open brace': '{',
    'lone close brace': '}',
    'unbalanced object': '{"a": 1',
    'unbalanced array': '[1, 2',
    'nested unclosed': '{"a": {"b": [1, 2',
    'only a fence': '```',
    'unclosed fence': '```json\n{"a":1}',
    'nested fences': '```\n```\n```json\n{"a":1}\n```',
    'brace inside string': '{"a":"}"}',
    'escaped quote': r'{"a":"\""}',
    'trailing comma': '{"a":1,}',
    'single quotes': "{'a':1}",
    'null bytes': '{"a":"\u0000"}',
    'control chars': '\u0001\u0002{"a":1}\u0003',
    'rtl': '{"نص":"عربي"}',
    'emoji': '{"a":"👨‍👩‍👧‍👦"}',
    'very deep': deepNest,
    'deep unbalanced': deepNest.substring(0, deepNest.length - 200),
    'long digits': '9' * 400,
    'version-ish': 'v1.2.3-beta.1+build.7',
    'version garbage': 'version: not.a.number.at.all',
    'negative version': '-1.-2.-3',
    'huge version': '${'9' * 100}.0.0',
    'changelog-ish': '## 1.0.0\n\n### Added\n- thing\n',
    'changelog no header': 'just some prose\nwith lines\n',
    'changelog weird header': '####### 1.0.0.0.0\n- x',
    'markdown bomb': markdownHeadingBomb,
    'markdown list bomb': markdownListBomb,
    'markdown link bomb': markdownLinkBomb,
    'markdown table': '| a | b |\n|---|---|\n| 1 | 2 |\n',
    'html-ish': '<script>alert(1)</script>',
    'crlf': '{"a":1}\r\n{"b":2}\r\n',
    'only newlines': '\n\n\n\n',
  };

  group('PrismStructuredOutput never throws', () {
    test('on the curated corpus', () {
      for (final MapEntry(key: label, value: input) in corpus.entries) {
        expect(
          () => PrismStructuredOutput.extract(input),
          returnsNormally,
          reason: 'extract threw on "$label"',
        );
        expect(
          () => PrismStructuredOutput.extractMap(input),
          returnsNormally,
          reason: 'extractMap threw on "$label"',
        );
        expect(
          () => PrismStructuredOutput.extractList(input),
          returnsNormally,
          reason: 'extractList threw on "$label"',
        );
        expect(
          () => PrismStructuredOutput.extractMapList(input),
          returnsNormally,
          reason: 'extractMapList threw on "$label"',
        );
      }
    });

    test('on random strings from a seeded generator', () {
      // Seeded, so a failure here is reproducible rather than a flake.
      final random = Random(20261104);
      const alphabet =
          '{}[]",:\\n\t abc123-_.`*#|\\/<>@!\u0000\u00e9\u0627\ud83d\ude00';

      for (var i = 0; i < 2000; i++) {
        final length = random.nextInt(120);
        final buffer = StringBuffer();
        for (var j = 0; j < length; j++) {
          buffer.write(alphabet[random.nextInt(alphabet.length)]);
        }
        final input = buffer.toString();
        expect(
          () => PrismStructuredOutput.extract(input),
          returnsNormally,
          reason: 'threw on generated input: ${input.replaceAll('\n', r'\n')}',
        );
      }
    });

    test('always returns the declared type', () {
      for (final input in corpus.values) {
        final map = PrismStructuredOutput.extractMap(input);
        expect(map, anyOf(isNull, isA<Map<String, Object?>>()));

        final list = PrismStructuredOutput.extractList(input);
        expect(list, anyOf(isNull, isA<List<Object?>>()));

        // extractMapList never returns null; it degrades to empty.
        expect(
          PrismStructuredOutput.extractMapList(input),
          isA<List<Object?>>(),
        );
      }
    });

    test('a deeply nested payload does not blow the stack', () {
      // 200 levels is past anything a model produces and exercises the
      // balanced-span scanner's recursion-free walk.
      final deep = deepNest;
      expect(() => PrismStructuredOutput.extract(deep), returnsNormally);
    });

    test('a large payload completes rather than hanging', () {
      final big = '{"a":"${'x' * 200000}"}';
      expect(
        PrismStructuredOutput.extractMap(big),
        isA<Map<String, Object?>>(),
      );
    });
  });

  group('PrismVersion.parse never throws an unexpected error', () {
    test('on the curated corpus', () {
      for (final MapEntry(key: label, value: input) in corpus.entries) {
        try {
          PrismVersion.parse(input);
        } on PrismVersionException {
          // The documented failure mode for unparseable input.
        } catch (error) {
          fail('parse threw ${error.runtimeType} on "$label": $error');
        }
      }
    });

    test('on random strings from a seeded generator', () {
      final random = Random(7);
      const alphabet = '0123456789.-+ abcXYZ\u00e9\u0627';

      for (var i = 0; i < 2000; i++) {
        final length = random.nextInt(30);
        final buffer = StringBuffer();
        for (var j = 0; j < length; j++) {
          buffer.write(alphabet[random.nextInt(alphabet.length)]);
        }
        final input = buffer.toString();
        try {
          PrismVersion.parse(input);
        } on PrismVersionException {
          // Expected for most random input.
        } catch (error) {
          fail('parse threw ${error.runtimeType} on "$input": $error');
        }
      }
    });

    test('the exception carries the offending input', () {
      try {
        PrismVersion.parse('not a version');
        fail('expected a PrismVersionException');
      } on PrismVersionException catch (error) {
        expect(error.input, 'not a version');
        expect(error.toString(), contains('not a version'));
      }
    });
  });

  group('ChangelogParser.parse never throws', () {
    test('on the curated corpus', () {
      for (final MapEntry(key: label, value: input) in corpus.entries) {
        expect(
          () => ChangelogParser.parse(input),
          returnsNormally,
          reason: 'parse threw on "$label"',
        );
      }
    });

    test('on random strings from a seeded generator', () {
      final random = Random(99);
      const alphabet = '#-* []().0123456789 abc\n\t';

      for (var i = 0; i < 1000; i++) {
        final length = random.nextInt(200);
        final buffer = StringBuffer();
        for (var j = 0; j < length; j++) {
          buffer.write(alphabet[random.nextInt(alphabet.length)]);
        }
        final input = buffer.toString();
        expect(
          () => ChangelogParser.parse(input),
          returnsNormally,
          reason: 'threw on generated input: ${input.replaceAll('\n', r'\n')}',
        );
      }
    });

    test('always returns a list', () {
      for (final input in corpus.values) {
        expect(ChangelogParser.parse(input), isA<List<ChangelogEntry>>());
      }
    });
  });

  group('the markdown renderer survives hostile input', () {
    testWidgets('rendering never throws', (tester) async {
      for (final MapEntry(key: label, value: input) in corpus.entries) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: PrismMarkdown(input)),
            ),
          ),
        );
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: 'PrismMarkdown threw on "$label"',
        );
      }
    });

    testWidgets('a very large document renders without throwing', (
      tester,
    ) async {
      final big = List.filled(500, '- item\n').join();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(child: PrismMarkdown(big)),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
