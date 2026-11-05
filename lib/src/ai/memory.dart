import 'chat_message.dart';

/// Conversation memory that trims old turns and can summarise them.
///
/// Wraps a `List<AiChatMessage>` and keeps the most recent turns within a
/// token budget. When the budget is exceeded, the oldest turns are removed.
/// Optionally, a summarise callback is invoked with the removed turns so the
/// caller can store a summary and inject it as a system message.
///
/// ```dart
/// final memory = PrismMessageMemory(
///   maxMessages: 20,
///   onSummarise: (removed) => print('${removed.length} turns dropped'),
/// );
/// memory.add(AiChatMessage.user('Hello'));
/// memory.add(AiChatMessage.assistant('Hi!'));
///
/// // Pass to the client:
/// client.streamChat(memory.messages, model: 'gpt-4o-mini');
/// ```
class PrismMessageMemory {
  /// Creates conversation memory.
  ///
  /// [maxMessages] caps how many messages are kept. When the list exceeds this,
  /// the oldest messages are removed and passed to [onSummarise] (if set).
  /// [keepSystemMessages] prevents system messages from being removed.
  PrismMessageMemory({
    this.maxMessages = 20,
    this.onSummarise,
    this.keepSystemMessages = true,
  });

  /// Maximum number of messages kept.
  final int maxMessages;

  /// Called with the removed messages when trimming.
  final void Function(List<AiChatMessage> removed)? onSummarise;

  /// Whether system messages are excluded from trimming.
  final bool keepSystemMessages;

  final List<AiChatMessage> _messages = [];

  /// All messages currently in memory.
  List<AiChatMessage> get messages => List.unmodifiable(_messages);

  /// Adds a message and trims if necessary.
  void add(AiChatMessage message) {
    _messages.add(message);
    _trim();
  }

  /// Adds several messages and trims if necessary.
  void addAll(Iterable<AiChatMessage> messages) {
    _messages.addAll(messages);
    _trim();
  }

  /// Clears all messages.
  void clear() => _messages.clear();

  void _trim() {
    if (_messages.length <= maxMessages) return;

    final removed = <AiChatMessage>[];
    var overflow = _messages.length - maxMessages;

    for (var i = 0; i < _messages.length && overflow > 0; i++) {
      final message = _messages[i];
      if (keepSystemMessages && message.role == AiRole.system) continue;
      removed.add(message);
      overflow--;
    }

    if (removed.isNotEmpty) {
      for (final message in removed) {
        _messages.remove(message);
      }
      onSummarise?.call(removed);
    }
  }
}
