import 'ai_client.dart';
import 'ai_events.dart';
import 'chat_message.dart';
import 'structured_output.dart';

/// A single step in a [PrismPromptChain].
///
/// [prompt] can reference the output of previous steps using named
/// placeholders: `{{step1.field}}` or `{{input.field}}`.
///
/// [parse] extracts a typed value from the model's response, so the next step
/// can reference it by the step's [outputKey].
class PrismChainStep<T> {
  /// Creates a chain step.
  const PrismChainStep({
    required this.prompt,
    required this.outputKey,
    required this.parse,
  });

  /// The prompt template. `{{…}}` placeholders are replaced with values from
  /// the context.
  final String prompt;

  /// The key this step's parsed output is stored under.
  final String outputKey;

  /// Parses the raw model response into the value stored under [outputKey].
  final Object Function(String response) parse;
}

/// Runs a sequence of prompts where each step's output feeds the next.
///
/// Steps run in order. Each step's prompt has its `{{…}}` placeholders replaced
/// with values from the context, which starts with the caller's [input] and
/// accumulates each step's output. A step that throws aborts the chain and
/// re-throws.
///
/// ```dart
/// final chain = PrismPromptChain([
///   PrismChainStep<Map<String, Object?>>(
///     prompt: 'Extract the sentiment from: {{input.text}}',
///     outputKey: 'sentiment',
///     parse: (r) => PrismStructuredOutput.extractMap(r) ?? {},
///   ),
///   PrismChainStep<String>(
///     prompt: 'Given the sentiment {{sentiment.sentiment}}, write a reply.',
///     outputKey: 'reply',
///     parse: (r) => r,
///   ),
/// ]);
///
/// final result = await chain.run(
///   client,
///   {'text': 'This product is amazing!'},
///   model: 'gpt-4o-mini',
/// );
/// print(result['reply']);
/// ```
class PrismPromptChain {
  /// Creates a prompt chain.
  const PrismPromptChain(this.steps, {this.systemPrompt});

  /// The steps, run in order.
  final List<PrismChainStep> steps;

  /// Optional system message sent with every step.
  final String? systemPrompt;

  /// Runs all steps and returns the accumulated context.
  Future<Map<String, Object?>> run(
    AiStreamClient client,
    Map<String, Object?> input, {
    required String model,
    double? temperature,
    int? maxTokens,
  }) async {
    final context = <String, Object?>{'input': input};

    for (final step in steps) {
      final prompt = _interpolate(step.prompt, context);
      final response = await _complete(
        client,
        prompt,
        model: model,
        temperature: temperature,
        maxTokens: maxTokens,
      );
      context[step.outputKey] = step.parse(response);
    }

    return context;
  }

  String _interpolate(String template, Map<String, Object?> context) {
    return template.replaceAllMapped(RegExp(r'\{\{(\w+)(?:\.(\w+))?\}\}'), (
      match,
    ) {
      final key = match.group(1)!;
      final field = match.group(2);
      final value = context[key];
      if (value == null) return match.group(0)!;
      if (field != null && value is Map) {
        return value[field]?.toString() ?? '';
      }
      return value.toString();
    });
  }

  Future<String> _complete(
    AiStreamClient client,
    String prompt, {
    required String model,
    double? temperature,
    int? maxTokens,
  }) async {
    final messages = <AiChatMessage>[
      if (systemPrompt != null) AiChatMessage.system(systemPrompt!),
      AiChatMessage.user(prompt),
    ];

    final buffer = StringBuffer();
    await for (final event in client.streamChat(
      messages,
      model: model,
      temperature: temperature,
      maxTokens: maxTokens,
      extraBody: const {},
    )) {
      if (event is AiTextDelta) buffer.write(event.text);
      if (event is AiError) throw event;
    }
    return buffer.toString();
  }
}
