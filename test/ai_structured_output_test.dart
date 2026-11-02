import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

void main() {
  group('PrismStructuredOutput.extract', () {
    test('parses a bare object', () {
      expect(PrismStructuredOutput.extract('{"sentiment":"positive"}'), {
        'sentiment': 'positive',
      });
    });

    test('parses a bare array', () {
      expect(PrismStructuredOutput.extract('[1,2,3]'), [1, 2, 3]);
    });

    test('parses a fenced json block', () {
      const reply = '''
Sure! Here is the data:

```json
{"score": 8, "label": "good"}
```

Let me know if you need anything else.''';
      expect(PrismStructuredOutput.extractMap(reply), {
        'score': 8,
        'label': 'good',
      });
    });

    test('parses a fence with no language tag', () {
      expect(PrismStructuredOutput.extractMap('```\n{"a":1}\n```'), {'a': 1});
    });

    test('ignores leading and trailing prose', () {
      expect(
        PrismStructuredOutput.extractMap(
          'The answer is {"ok": true} and that is that.',
        ),
        {'ok': true},
      );
    });

    test('handles nested braces', () {
      const reply = '{"outer":{"inner":{"deep":1}},"other":[1,2]}';
      final parsed = PrismStructuredOutput.extractMap(reply);
      expect(parsed, isNotNull);
      expect((parsed!['outer']! as Map)['inner'], {'deep': 1});
    });

    test('ignores braces inside strings', () {
      const reply = r'{"template":"a {brace} inside","n":1}';
      final parsed = PrismStructuredOutput.extractMap(reply);
      expect(parsed, isNotNull);
      expect(parsed!['template'], 'a {brace} inside');
      expect(parsed['n'], 1);
    });

    test('ignores escaped quotes inside strings', () {
      const reply = r'{"quote":"she said \"hi\"","n":2}';
      final parsed = PrismStructuredOutput.extractMap(reply);
      expect(parsed, isNotNull);
      expect(parsed!['n'], 2);
    });

    test('returns null for prose with no JSON', () {
      expect(PrismStructuredOutput.extract('There is no data here.'), isNull);
    });

    test('returns null for empty input', () {
      expect(PrismStructuredOutput.extract(''), isNull);
      expect(PrismStructuredOutput.extract('   '), isNull);
    });

    test('returns null for malformed JSON rather than throwing', () {
      expect(PrismStructuredOutput.extract('{"a": }'), isNull);
      expect(PrismStructuredOutput.extract('{unquoted: 1}'), isNull);
    });
  });

  group('PrismStructuredOutput.extractMap', () {
    test('unwraps a single-object array', () {
      expect(PrismStructuredOutput.extractMap('[{"only": 1}]'), {'only': 1});
    });

    test('returns null for a multi-element array', () {
      expect(PrismStructuredOutput.extractMap('[{"a":1},{"b":2}]'), isNull);
    });

    test('returns null when the payload is a scalar', () {
      expect(PrismStructuredOutput.extractMap('42'), isNull);
    });
  });

  group('PrismStructuredOutput.extractList', () {
    test('wraps a lone object', () {
      expect(PrismStructuredOutput.extractList('{"a":1}'), [
        {'a': 1},
      ]);
    });

    test('passes an array through', () {
      expect(PrismStructuredOutput.extractList('[1,2]'), [1, 2]);
    });
  });

  group('PrismStructuredOutput.extractMapList', () {
    test('maps every object in an array', () {
      expect(PrismStructuredOutput.extractMapList('[{"a":1},{"b":2}]'), [
        {'a': 1},
        {'b': 2},
      ]);
    });

    test('skips entries that are not objects, keeping the rest', () {
      // A model asked for objects will occasionally emit a stray string; losing
      // the valid entries would be worse than dropping the odd one.
      expect(
        PrismStructuredOutput.extractMapList('[{"a":1},"oops",{"b":2},7]'),
        [
          {'a': 1},
          {'b': 2},
        ],
      );
    });

    test('returns empty for a non-array payload', () {
      expect(PrismStructuredOutput.extractMapList('"just a string"'), isEmpty);
    });
  });

  group('PrismStructuredOutput.instructJson', () {
    test('asks for an object by default', () {
      final prompt = PrismStructuredOutput.instructJson('Summarise this.');
      expect(prompt, contains('Summarise this.'));
      expect(prompt, contains('JSON object'));
      expect(prompt, contains('Do not include prose'));
    });

    test('asks for an array when requested', () {
      expect(
        PrismStructuredOutput.instructJson('List things.', array: true),
        contains('JSON array'),
      );
    });

    test('names the expected keys and shows the shape', () {
      final prompt = PrismStructuredOutput.instructJson(
        'Extract the fields.',
        schema: {'name': 'string', 'age': 0},
      );
      expect(prompt, contains('name, age'));
      expect(prompt, contains('"name"'));
    });
  });

  group('PrismContextBudget', () {
    AiChatMessage user(String content) =>
        AiChatMessage(role: AiRole.user, content: content);
    AiChatMessage system(String content) =>
        AiChatMessage(role: AiRole.system, content: content);

    test('reserves room for the reply', () {
      const budget = PrismContextBudget(maxTokens: 8000, reserveForReply: 1000);
      expect(budget.availableTokens, 7000);
    });

    test('never reports negative availability', () {
      const budget = PrismContextBudget(maxTokens: 100, reserveForReply: 500);
      expect(budget.availableTokens, 0);
    });

    test('estimates tokens conservatively', () {
      const budget = PrismContextBudget(maxTokens: 1000);
      // Four characters per token, rounded up.
      expect(budget.estimateTokens('abcd'), 1);
      expect(budget.estimateTokens('abcde'), 2);
      expect(budget.estimateTokens(''), 0);
    });

    test('counts a message with its framing overhead', () {
      const budget = PrismContextBudget(maxTokens: 1000);
      expect(budget.estimateMessageTokens(user('abcd')) > 4, isTrue);
    });

    test('an empty conversation fits', () {
      const budget = PrismContextBudget(maxTokens: 100);
      expect(budget.fits([]), isTrue);
      expect(budget.fit([]), isEmpty);
    });

    test('leaves a short conversation alone', () {
      const budget = PrismContextBudget(maxTokens: 8000);
      final messages = [system('Be terse.'), user('Hello')];
      expect(budget.fit(messages), messages);
    });

    test('drops the oldest turns first', () {
      const budget = PrismContextBudget(
        maxTokens: 120,
        reserveForReply: 20,
        minimumRecentMessages: 1,
      );
      final messages = [
        user('a' * 200), // oldest, ~50 tokens
        user('b' * 200),
        user('recent'),
      ];

      final fitted = budget.fit(messages);

      expect(fitted, isNotEmpty);
      expect(fitted.last.content, 'recent');
      expect(fitted.length, lessThan(messages.length));
    });

    test(
      'always keeps the newest message even when it alone exceeds the budget',
      () {
        const budget = PrismContextBudget(
          maxTokens: 40,
          reserveForReply: 20,
          minimumRecentMessages: 1,
        );
        final messages = [user('x' * 4000)];
        expect(budget.fit(messages), hasLength(1));
      },
    );

    test('keeps system messages when trimming', () {
      const budget = PrismContextBudget(
        maxTokens: 150,
        reserveForReply: 20,
        minimumRecentMessages: 1,
      );
      final messages = [
        system('You are a careful assistant.'),
        user('a' * 400),
        user('b' * 400),
        user('latest'),
      ];

      final fitted = budget.fit(messages);
      expect(fitted.first.role, AiRole.system);
      expect(fitted.last.content, 'latest');
    });

    test('can be told to drop system messages', () {
      const budget = PrismContextBudget(
        maxTokens: 100,
        reserveForReply: 10,
        keepSystemMessages: false,
        minimumRecentMessages: 1,
      );
      final messages = [system('a' * 400), user('latest')];
      final fitted = budget.fit(messages);
      expect(fitted.where((m) => m.role == AiRole.system), isEmpty);
    });

    test('preserves order after trimming', () {
      const budget = PrismContextBudget(
        maxTokens: 200,
        reserveForReply: 20,
        minimumRecentMessages: 2,
      );
      final messages = [
        user('oldest ' * 50),
        user('middle ' * 20),
        user('newest'),
      ];
      final fitted = budget.fit(messages);
      final contents = fitted.map((m) => m.content).toList();
      expect(contents, equals([...contents]..sort((a, b) => 0)));
      expect(fitted.last.content, 'newest');
    });

    test('usage ratio reports how full the context is', () {
      const budget = PrismContextBudget(maxTokens: 1000, reserveForReply: 500);
      expect(budget.usageRatio([]), 0);
      expect(budget.usageRatio([user('a' * 2000)]), 1.0);
    });

    test('usage ratio is 1 when nothing is available', () {
      const budget = PrismContextBudget(maxTokens: 10, reserveForReply: 100);
      expect(budget.usageRatio([user('hello')]), 1.0);
    });
  });
}
