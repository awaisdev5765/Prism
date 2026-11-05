import 'ai_client.dart';
import 'ai_events.dart';
import 'chat_message.dart';

/// Runs an AI agent loop that persists messages across calls.
class PrismAgentRunner {
  PrismAgentRunner({required this.client, this.maxSteps = 10});
  final AiStreamClient client;
  final int maxSteps;
  final List<AiChatMessage> _messages = [];

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  void addMessage(AiChatMessage message) => _messages.add(message);
  void reset() => _messages.clear();

  Future<String> run({required String model, double? temperature}) async {
    final buffer = StringBuffer();
    await for (final event in client.streamChat(
      _messages,
      model: model,
      temperature: temperature,
      extraBody: const {},
    )) {
      if (event is AiTextDelta) buffer.write(event.text);
      if (event is AiDone) break;
      if (event is AiError) throw event;
    }
    _messages.add(AiChatMessage.assistant(buffer.toString()));
    return buffer.toString();
  }
}
