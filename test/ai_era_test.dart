import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

void main() {
  group('PrismRateLimiter', () {
    test('allows calls within limit', () async {
      final limiter = PrismRateLimiter(maxPerSecond: 10);
      await limiter.acquire();
      await limiter.acquire();
    });

    test('throttles when over the limit', () async {
      final limiter = PrismRateLimiter(maxPerSecond: 2);
      final start = DateTime.now();
      for (var i = 0; i < 5; i++) {
        await limiter.acquire();
      }
      final elapsed = DateTime.now().difference(start);
      // 5 calls at 2/sec: the first 2 fire instantly, the rest wait ~500ms each.
      expect(elapsed.inMilliseconds, greaterThan(500));
    });
  });

  group('StreamingJsonParser', () {
    test('parses complete fields from partial JSON', () {
      final parser = StreamingJsonParser();
      parser.consume('{"sentiment": "positive", "conf');
      expect(parser.fields['sentiment'], 'positive');
    });

    test('complete returns null for incomplete JSON', () {
      final parser = StreamingJsonParser();
      parser.consume('{"sentiment": "positive"');
      expect(parser.complete(), isNull);
    });

    test('complete parses when done', () {
      final parser = StreamingJsonParser();
      parser.consume('{"sentiment": "positive"}');
      expect(parser.complete(), {'sentiment': 'positive'});
    });

    test('never throws on malformed input', () {
      final parser = StreamingJsonParser();
      parser.consume('{not valid json');
      expect(parser.fields, isEmpty);
      expect(parser.complete(), isNull);
    });

    test('handles streaming in small chunks', () {
      final parser = StreamingJsonParser();
      for (final char in '{"key": "value"}'.split('')) {
        parser.consume(char);
      }
      expect(parser.fields['key'], 'value');
      expect(parser.complete(), {'key': 'value'});
    });

    test('fields returns empty for no complete pairs', () {
      final parser = StreamingJsonParser();
      parser.consume('{"partial');
      expect(parser.fields, isEmpty);
    });

    test('isComplete reflects brace state', () {
      final parser = StreamingJsonParser();
      parser.consume('{"a": 1');
      expect(parser.isComplete, isFalse);
      parser.consume('}');
      expect(parser.isComplete, isTrue);
    });

    test('reset clears the buffer', () {
      final parser = StreamingJsonParser();
      parser.consume('{"a":1}');
      parser.reset();
      expect(parser.complete(), isNull);
      expect(parser.fields, isEmpty);
    });
  });

  group('PrismMessageMemory', () {
    test('trims oldest messages when over the limit', () {
      final memory = PrismMessageMemory(maxMessages: 3);
      for (var i = 0; i < 5; i++) {
        memory.add(AiChatMessage.user('Message $i'));
      }
      expect(memory.messages, hasLength(3));
      expect(memory.messages.first.content, 'Message 2');
    });

    test('preserves system messages when trimming', () {
      final memory = PrismMessageMemory(maxMessages: 3, keepSystemMessages: true);
      memory.add(AiChatMessage.system('Be helpful'));
      for (var i = 0; i < 5; i++) {
        memory.add(AiChatMessage.user('Message $i'));
      }
      expect(memory.messages.first.role, AiRole.system);
    });

    test('does not preserve system messages when told not to', () {
      final memory = PrismMessageMemory(maxMessages: 3, keepSystemMessages: false);
      memory.add(AiChatMessage.system('Be helpful'));
      for (var i = 0; i < 5; i++) {
        memory.add(AiChatMessage.user('Message $i'));
      }
      expect(memory.messages.first.role, isNot(AiRole.system));
    });

    test('calls onSummarise with removed messages', () {
      final removed = <AiChatMessage>[];
      final memory = PrismMessageMemory(
        maxMessages: 3,
        onSummarise: removed.addAll,
      );
      for (var i = 0; i < 5; i++) {
        memory.add(AiChatMessage.user('Message $i'));
      }
      expect(removed, hasLength(2));
    });

    test('clear empties memory', () {
      final memory = PrismMessageMemory();
      memory.add(AiChatMessage.user('hello'));
      memory.clear();
      expect(memory.messages, isEmpty);
    });

    test('messages is unmodifiable', () {
      final memory = PrismMessageMemory();
      memory.add(AiChatMessage.user('hello'));
      expect(
        () => (memory.messages as List).add(AiChatMessage.user('x')),
        throwsUnsupportedError,
      );
    });
  });

  group('PrismResponseCache', () {
    test('stores and retrieves', () {
      final cache = PrismResponseCache();
      final key = PrismResponseCache.keyFor('hello', model: 'test');
      cache.put(key, 'world');
      expect(cache.get(key), 'world');
    });

    test('different keys do not collide', () {
      final cache = PrismResponseCache();
      final k1 = PrismResponseCache.keyFor('a', model: 'm1');
      final k2 = PrismResponseCache.keyFor('b', model: 'm2');
      cache.put(k1, 'A');
      cache.put(k2, 'B');
      expect(cache.get(k1), 'A');
      expect(cache.get(k2), 'B');
    });

    test('evicts oldest when full', () {
      final cache = PrismResponseCache(maxEntries: 2);
      cache.put('a', '1');
      cache.put('b', '2');
      cache.put('c', '3');
      expect(cache.get('a'), isNull);
      expect(cache.get('b'), '2');
      expect(cache.get('c'), '3');
    });

    test('clear empties the cache', () {
      final cache = PrismResponseCache();
      cache.put('a', '1');
      cache.clear();
      expect(cache.get('a'), isNull);
      expect(cache.length, 0);
    });

    test('same prompt and model produce the same key', () {
      final k1 = PrismResponseCache.keyFor('hello', model: 'gpt-4o');
      final k2 = PrismResponseCache.keyFor('hello', model: 'gpt-4o');
      expect(k1, k2);
    });

    test('different temperature produces a different key', () {
      final k1 = PrismResponseCache.keyFor('hello', model: 'gpt-4o', temperature: 0);
      final k2 = PrismResponseCache.keyFor('hello', model: 'gpt-4o', temperature: 1);
      expect(k1, isNot(k2));
    });
  });

  group('PrismGuard', () {
    test('blocks responses matching a pattern', () {
      final guard = PrismGuard(blockedPatterns: [RegExp('password')]);
      expect(guard.check('my password is 123'), isNotNull);
      expect(guard.check('no secrets here'), isNull);
    });

    test('blocks overly long responses', () {
      final guard = PrismGuard(maxResponseLength: 10);
      expect(guard.check('x' * 100), isNotNull);
      expect(guard.check('short'), isNull);
    });

    test('custom validators run last', () {
      final guard = PrismGuard(customValidators: [
        (r) => r.contains('bad') ? 'Contains bad word' : null,
      ]);
      expect(guard.check('this is bad'), isNotNull);
      expect(guard.check('this is fine'), isNull);
    });

    test('returns null when everything passes', () {
      final guard = PrismGuard(
        blockedPatterns: [RegExp('secret')],
        maxResponseLength: 1000,
      );
      expect(guard.check('a safe response'), isNull);
    });
  });

  group('PrismAgentRunner', () {
    test('adds messages and returns them', () {
      final runner = PrismAgentRunner(client: _FakeClient());
      runner.addMessage(AiChatMessage.system('Be helpful'));
      runner.addMessage(AiChatMessage.user('Hello'));
      expect(runner.messages, hasLength(2));
      runner.reset();
      expect(runner.messages, isEmpty);
    });
  });

  group('PrismPromptChain', () {
    test('interpolates placeholders from context', () async {
      final chain = PrismPromptChain([
        PrismChainStep<String>(
          prompt: 'Step: {{input.text}}',
          outputKey: 'result',
          parse: (r) => r,
        ),
      ]);
      final result = await chain.run(
        _FakeClient(),
        {'text': 'hello'},
        model: 'test',
      );
      expect(result['result'], isNotNull);
    });
  });
}

class _FakeClient implements AiStreamClient {
  @override
  Stream<Object> streamChat(
    List<AiChatMessage> messages, {
    required String model,
    double? temperature,
    int? maxTokens,
    Map<String, Object?> extraBody = const {},
  }) {
    return Stream.value(AiTextDelta('response'));
  }
}
