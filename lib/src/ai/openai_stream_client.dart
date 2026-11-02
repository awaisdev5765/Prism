import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'ai_client.dart';
import 'ai_events.dart';
import 'chat_message.dart';
import 'sse_parser.dart';

/// Streams chat completions from any OpenAI-compatible endpoint.
///
/// One implementation covers OpenAI, Azure OpenAI, Ollama (`/v1`),
/// Groq, DeepSeek, Together, LM Studio, vLLM and every other server that
/// speaks the `/chat/completions` protocol.
///
/// ```dart
/// final client = OpenAiStreamClient(
///   baseUrl: 'https://api.openai.com/v1',
///   apiKey: 'sk-...',
/// );
/// await for (final event in client.streamChat(messages, model: 'gpt-4o')) {
///   if (event is AiTextDelta) stdout.write(event.text);
/// }
/// ```
final class OpenAiStreamClient implements AiStreamClient {
  OpenAiStreamClient({
    required this.baseUrl,
    this.apiKey,
    http.Client? client,
    Map<String, String>? extraHeaders,
  })  : _client = client ?? http.Client(),
        _extraHeaders = extraHeaders ?? const {};

  /// Base URL of the OpenAI-compatible API, e.g.
  /// `https://api.openai.com/v1` or `http://localhost:11434/v1` (Ollama).
  final String baseUrl;

  /// Bearer token, when the endpoint requires one (Ollama doesn't).
  final String? apiKey;

  final http.Client _client;
  final Map<String, String> _extraHeaders;

  /// Streams a chat completion as a sequence of typed events.
  ///
  /// Emits [AiTextDelta] for each content chunk, [AiToolCall] when the model
  /// invokes tools, and terminates with [AiDone]. Errors surface as
  /// [AiError] (the stream does not throw — UI code can just switch on
  /// event types).
  @override
  Stream<Object> streamChat(
    List<AiChatMessage> messages, {
    required String model,
    double? temperature,
    int? maxTokens,
    Map<String, Object?> extraBody = const {},
  }) async* {
    final uri = Uri.parse('$baseUrl/chat/completions');
    final body = jsonEncode({
      'model': model,
      'messages': [for (final m in messages) m.toJson()],
      'stream': true,
      ?temperature: temperature,
      ?maxTokens: maxTokens,
      ...extraBody,
    });

    final request = http.Request('POST', uri)
      ..headers['Content-Type'] = 'application/json'
      ..headers['Accept'] = 'text/event-stream';
    if (apiKey != null && apiKey!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $apiKey';
    }
    _extraHeaders.forEach((name, value) {
      request.headers[name] = value;
    });
    request.body = body;

    final response = await _client.send(request);
    if (response.statusCode != 200) {
      final errorBody = await response.stream.bytesToString();
      yield AiError(
        'Request failed with HTTP ${response.statusCode}: $errorBody',
        statusCode: response.statusCode,
      );
      return;
    }

    final parser = SseParser();
    final usageCollector = _UsageCollector();
    final toolAssembler = _ToolCallAssembler();

    await for (final chunk
        in response.stream.transform(const Utf8Decoder(allowMalformed: true))) {
      for (final event in parser.addChunk(chunk)) {
        for (final parsed
            in _parseEvent(event, usageCollector, toolAssembler)) {
          if (parsed is _DoneSignal) {
            // Tool-call fragments are complete once the stream signals a
            // finish reason — emit the assembled calls before terminating.
            for (final call in toolAssembler.flush()) {
          yield call;
        }
            yield AiDone(
              finishReason: parsed.finishReason ?? 'stop',
              usage: usageCollector.snapshot(),
            );
            return;
          }
          yield parsed;
        }
      }
    }

    // Stream ended without [DONE] — still terminate cleanly.
    for (final call in toolAssembler.flush()) {
          yield call;
        }
    yield AiDone(finishReason: 'stop', usage: usageCollector.snapshot());
  }

  /// Normalizes one SSE frame into zero or more provider-agnostic events.
  ///
  /// Streaming tool calls arrive as fragments across chunks (first chunk
  /// carries `id`/`name`, later chunks carry `arguments` pieces indexed by
  /// `tool_calls[i].index`), so fragments are fed to [toolAssembler] and
  /// assembled calls are emitted later — at the finish signal or stream end.
  static List<Object> _parseEvent(
    SseEvent event,
    _UsageCollector usageCollector,
    _ToolCallAssembler toolAssembler,
  ) {
    if (event.isDoneSentinel) return [const _DoneSignal()];
    if (event.data.trim().isEmpty) return const [];

    final Map<String, Object?> json;
    try {
      json = jsonDecode(event.data) as Map<String, Object?>;
    } on FormatException {
      return const []; // keep-alive or non-JSON frame — skip
    }

    // Error payload (OpenAI shape: {"error": {"message": ...}}).
    final error = json['error'];
    if (error is Map<String, Object?>) {
      return [
        AiError(
          (error['message'] as String?) ?? 'Unknown provider error',
          statusCode: (error['code'] is int) ? error['code'] as int : null,
        ),
      ];
    }

    final events = <Object>[];
    final choices = json['choices'] as List<Object?>? ?? const [];
    for (final choice in choices) {
      if (choice is! Map<String, Object?>) continue;

      final delta = choice['delta'] as Map<String, Object?>? ??
          choice['message'] as Map<String, Object?>?;
      if (delta != null) {
        final content = delta['content'];
        if (content is String && content.isNotEmpty) {
          events.add(AiTextDelta(content));
        }
        final toolCalls = delta['tool_calls'] as List<Object?>?;
        if (toolCalls != null) {
          for (final call in toolCalls) {
            if (call is! Map<String, Object?>) continue;
            final function = call['function'] as Map<String, Object?>? ?? {};
            toolAssembler.addFragment(_ToolCallFragment(
              index: (call['index'] as num?)?.toInt() ?? 0,
              id: call['id'] as String?,
              name: function['name'] as String?,
              argumentsChunk: (function['arguments'] as String?) ?? '',
            ));
          }
        }
      }

      final finishReason = choice['finish_reason'];
      if (finishReason is String && finishReason.isNotEmpty) {
        events.add(_DoneSignal(finishReason: finishReason));
      }
    }

    final usageJson = json['usage'] as Map<String, Object?>?;
    if (usageJson != null) {
      usageCollector.absorb(_usageFromJson(usageJson));
    }
    return events;
  }

  static AiUsage _usageFromJson(Map<String, Object?> json) => AiUsage(
        inputTokens: (json['prompt_tokens'] as num?)?.toInt() ?? 0,
        outputTokens: (json['completion_tokens'] as num?)?.toInt() ??
            (json['output_tokens'] as num?)?.toInt() ??
            0,
      );
}

/// One streamed piece of a tool call (OpenAI `delta.tool_calls[i]`).
final class _ToolCallFragment {
  const _ToolCallFragment({
    required this.index,
    this.id,
    this.name,
    this.argumentsChunk = '',
  });
  final int index;
  final String? id;
  final String? name;
  final String argumentsChunk;
}

/// Assembles streamed tool-call fragments into complete [AiToolCall]s.
///
/// OpenAI (and every compatible host) streams a tool call as fragments:
/// the first carries `id` + function `name`, subsequent ones append
/// `arguments` JSON pieces, all keyed by `index`. Calls are complete when
/// the finish reason arrives — [flush] emits one [AiToolCall] per index.
final class _ToolCallAssembler {
  final Map<int, _ToolBuffer> _buffers = {};

  void addFragment(_ToolCallFragment fragment) {
    final buffer =
        _buffers.putIfAbsent(fragment.index, () => _ToolBuffer());
    if (fragment.id != null && fragment.id!.isNotEmpty) buffer.id = fragment.id!;
    if (fragment.name != null && fragment.name!.isNotEmpty) {
      buffer.name = fragment.name!;
    }
    buffer.arguments.write(fragment.argumentsChunk);
  }

  /// Returns every assembled call in index order and resets state.
  List<AiToolCall> flush() {
    final indexes = _buffers.keys.toList()..sort();
    final calls = [
      for (final index in indexes)
        AiToolCall(
          id: _buffers[index]!.id,
          name: _buffers[index]!.name,
          argumentsJson: _buffers[index]!.arguments.toString(),
        ),
    ];
    _buffers.clear();
    return calls;
  }
}

final class _ToolBuffer {
  String id = '';
  String name = '';
  final StringBuffer arguments = StringBuffer();
}

final class _UsageCollector {
  AiUsage? _usage;
  void absorb(AiUsage usage) => _usage = usage;
  AiUsage? snapshot() => _usage;
}

final class _DoneSignal {
  const _DoneSignal({this.finishReason});
  final String? finishReason;
}
