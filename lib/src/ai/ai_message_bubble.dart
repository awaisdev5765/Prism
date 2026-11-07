import 'package:flutter/material.dart';

import '../markdown/markdown.dart';
import '../theme/theme.dart';
import 'chat_message.dart';
import 'thinking_indicator.dart';

/// One conversation turn as a token-styled chat bubble.
///
/// User messages render as an aligned filled bubble; assistant messages render
/// as markdown with optional tool-call collapsibles. While [isStreaming] is
/// true the bubble shows a [PrismAiThinkingIndicator] instead of content.
///
/// Every interactive affordance is optional: pass [onCopy] to show a copy
/// action, [onRegenerate] to show a regenerate button on the last assistant
/// turn, and [onToolCallTap] to react to tool-call taps.
///
/// ```dart
/// PrismAiMessageBubble(
///   message: lastMessage,
///   isStreaming: controller.isStreaming,
///   onRegenerate: () => controller.resend(),
/// )
/// ```
class PrismAiMessageBubble extends StatelessWidget {
  /// Creates a chat bubble for [message].
  const PrismAiMessageBubble({
    super.key,
    required this.message,
    this.isStreaming = false,
    this.markdownAssistant = true,
    this.thinkingLabel,
    this.maxWidth = 560,
    this.onCopy,
    this.onRegenerate,
    this.onToolCallTap,
  });

  /// The message to render.
  final AiChatMessage message;

  /// When true, shows a thinking indicator instead of the message body (only
  /// meaningful for assistant turns that have no content yet).
  final bool isStreaming;

  /// Whether assistant text is rendered as markdown (defaults to true).
  final bool markdownAssistant;

  /// Label shown by the thinking indicator while [isStreaming] is true.
  final String? thinkingLabel;

  /// Maximum bubble width before text wraps.
  final double maxWidth;

  /// Copy affordance; omit to hide.
  final VoidCallback? onCopy;

  /// Regenerate affordance; omit to hide.
  final VoidCallback? onRegenerate;

  /// Called when a tool-call chip is tapped.
  final void Function(AiToolCallRequest call)? onToolCallTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final theme = Theme.of(context);
    final isUser = message.role == AiRole.user;

    final bubbleColor = isUser
        ? theme.colorScheme.primary
        : colors.surfaceRaised;
    final foreground = isUser
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.spaceMd,
        vertical: tokens.spaceSm,
      ),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(tokens.radiusLg).copyWith(
          bottomLeft: isUser ? Radius.circular(tokens.radiusLg) : Radius.zero,
          bottomRight: isUser ? Radius.zero : Radius.circular(tokens.radiusLg),
        ),
      ),
      child: _content(context, foreground),
    );

    return Semantics(
      label: isUser ? 'Your message' : 'Assistant message',
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            bubble,
            if (!isUser && message.toolCalls.isNotEmpty) ...[
              for (final call in message.toolCalls)
                _ToolCallChip(call: call, onTap: onToolCallTap),
            ],
            if (!isUser &&
                (onCopy != null || onRegenerate != null) &&
                !isStreaming)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onCopy != null)
                    IconButton(
                      tooltip: 'Copy message',
                      icon: const Icon(Icons.copy_outlined, size: 18),
                      onPressed: onCopy,
                    ),
                  if (onRegenerate != null)
                    IconButton(
                      tooltip: 'Regenerate response',
                      icon: const Icon(Icons.refresh, size: 18),
                      onPressed: onRegenerate,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, Color foreground) {
    // While streaming with no content yet, show the thinking indicator.
    if (isStreaming && message.content.isEmpty) {
      return PrismAiThinkingIndicator(label: thinkingLabel);
    }
    if (message.role == AiRole.user || !markdownAssistant) {
      return Text(
        message.content,
        style: TextStyle(color: foreground, height: 1.35),
      );
    }
    return PrismMarkdown(
      message.content,
      style: PrismMarkdownStyle(textStyle: TextStyle(color: foreground)),
    );
  }
}

class _ToolCallChip extends StatelessWidget {
  const _ToolCallChip({required this.call, this.onTap});

  final AiToolCallRequest call;
  final void Function(AiToolCallRequest)? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    return Padding(
      padding: EdgeInsets.only(top: tokens.spaceXs),
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.radiusSm),
        onTap: onTap == null ? null : () => onTap!(call),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceSm,
            vertical: tokens.spaceXs,
          ),
          decoration: BoxDecoration(
            color: colors.infoContainer,
            borderRadius: BorderRadius.circular(tokens.radiusSm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.construction_outlined,
                size: 14,
                color: colors.onInfoContainer,
              ),
              SizedBox(width: tokens.spaceXs / 2),
              Text(
                call.name,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colors.onInfoContainer),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
