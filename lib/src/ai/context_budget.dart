import 'chat_message.dart';

/// Keeps a conversation inside a model's context window.
///
/// Every chat app eventually hits the same bug: a long thread is sent whole, the
/// provider rejects it or silently truncates the middle, and the assistant starts
/// forgetting the system prompt. This class estimates the cost, trims the
/// oldest turns first, and always keeps the system message and the most recent
/// exchange.
///
/// ```dart
/// final trimmed = PrismContextBudget(
///   maxTokens: 8000,
///   reserveForReply: 1000,
/// ).fit(history);
/// ```
///
/// The estimate is a heuristic, not a tokenizer: roughly four characters per
/// token for English prose. It is deliberately pessimistic (it rounds up), so it
/// under-fills rather than over-fills. Swap in a real tokenizer by overriding
/// [estimateTokens] if your provider exposes one.
class PrismContextBudget {
  /// Creates a context budget.
  const PrismContextBudget({
    required this.maxTokens,
    this.reserveForReply = 1024,
    this.keepSystemMessages = true,
    this.minimumRecentMessages = 2,
  });

  /// The model's context window, in tokens.
  final int maxTokens;

  /// Tokens to leave free for the model's reply. A budget that consumes the
  /// whole window leaves no room to answer.
  final int reserveForReply;

  /// Whether system messages are always kept, even when trimming aggressively.
  /// Losing the system prompt changes the model's behaviour entirely, which is
  /// worse than losing an old turn.
  final bool keepSystemMessages;

  /// The most recent messages that are never dropped.
  final int minimumRecentMessages;

  /// Tokens actually available for the conversation.
  int get availableTokens => (maxTokens - reserveForReply).clamp(0, maxTokens);

  /// Estimates the token count of [text].
  ///
  /// A conservative heuristic: four characters per token, rounded up, with a
  /// floor of one for non-empty text. Real tokenizers vary between roughly 3 and
  /// 5 characters per token depending on language and content, so this errs
  /// toward over-counting.
  int estimateTokens(String text) {
    if (text.isEmpty) return 0;
    return (text.length / 4).ceil();
  }

  /// Estimates the token count of one message.
  int estimateMessageTokens(AiChatMessage message) {
    // A few tokens of role/turn overhead, as providers charge for framing.
    return estimateTokens(message.content) + 4;
  }

  /// Estimates the total for a conversation.
  int estimateConversationTokens(Iterable<AiChatMessage> messages) =>
      messages.fold(0, (sum, m) => sum + estimateMessageTokens(m));

  /// Whether [messages] fit inside [availableTokens].
  bool fits(Iterable<AiChatMessage> messages) =>
      estimateConversationTokens(messages) <= availableTokens;

  /// Trims [messages] to fit, dropping the oldest turns first.
  ///
  /// Order is preserved and the newest messages are always kept, because a
  /// conversation without its most recent turn is useless. Returns the input
  /// unchanged when it already fits.
  List<AiChatMessage> fit(List<AiChatMessage> messages) {
    if (messages.isEmpty) return const [];
    if (fits(messages)) return List.of(messages);

    final system = <AiChatMessage>[
      if (keepSystemMessages)
        for (final m in messages)
          if (m.role == AiRole.system) m,
    ];
    final rest = [
      for (final m in messages)
        if (!(keepSystemMessages && m.role == AiRole.system)) m,
    ];

    final systemCost = estimateConversationTokens(system);
    var budget = availableTokens - systemCost;

    // Walk backwards from the newest message, keeping whatever fits.
    final kept = <AiChatMessage>[];
    for (var i = rest.length - 1; i >= 0; i--) {
      final cost = estimateMessageTokens(rest[i]);
      final isProtected = kept.length < minimumRecentMessages;
      if (cost <= budget || isProtected) {
        kept.insert(0, rest[i]);
        budget -= cost;
      } else {
        // Everything older than this is dropped.
        break;
      }
    }

    return [...system, ...kept];
  }

  /// How much of the budget the conversation is using, in 0..1.
  ///
  /// Useful for a context meter in a chat UI: users are far less frustrated by
  /// trimming when they can see it coming.
  double usageRatio(Iterable<AiChatMessage> messages) {
    final available = availableTokens;
    if (available == 0) return 1;
    return (estimateConversationTokens(messages) / available).clamp(0.0, 1.0);
  }
}
