/// Prism AI — a lean, provider-agnostic streaming client for AI chat
/// completions, with typed events and zero heavyweight dependencies.
///
/// One client implementation covers every OpenAI-compatible endpoint
/// (OpenAI, Ollama, Groq, DeepSeek, Together, LM Studio, vLLM).
///
/// ```dart
/// final client = OpenAiStreamClient(
///   baseUrl: 'http://localhost:11434/v1', // Ollama
/// );
/// await for (final event in client.streamChat(messages, model: 'llama3')) {
///   if (event is AiTextDelta) setState(() => response += event.text);
/// }
/// ```
///
/// Designed to pair with the [Prism](https://pub.dev/packages/prism_markdown)
/// family: stream into `PrismMarkdown` for live AI-response rendering.
library;

export './ai_chat_view.dart';
export './ai_client.dart';
export './ai_events.dart';
export './ai_tool.dart';
export './ai_agent.dart';
export './anthropic_stream_client.dart';
export './chat_message.dart';
export './embeddings.dart';
export './gemini_stream_client.dart';
export './openai_stream_client.dart';
export './sse_parser.dart';
