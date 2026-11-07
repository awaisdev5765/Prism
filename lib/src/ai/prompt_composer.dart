import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// An input row for prompting an AI assistant.
///
/// A token-styled text field with a send button, optional suggestion chips
/// shown above the field, and an optional busy state that disables the send
/// button and shows a spinner. Wire it to your own `AiChatController` or any
/// `AiStreamClient` — the composer never touches the network itself.
///
/// ```dart
/// PrismPromptComposer(
///   suggestions: const ['Summarise', 'Translate to Urdu'],
///   busy: controller.isStreaming,
///   onSend: controller.send,
/// )
/// ```
class PrismPromptComposer extends StatefulWidget {
  /// Creates a prompt composer.
  const PrismPromptComposer({
    super.key,
    required this.onSend,
    this.suggestions = const [],
    this.busy = false,
    this.hint = 'Ask anything…',
    this.sendTooltip = 'Send message',
    this.maxLines = 5,
    this.controller,
    this.onSuggestionTap,
  });

  /// Called with the composed text when the user sends. The composer clears
  /// its field afterwards.
  final ValueChanged<String> onSend;

  /// Optional one-tap prompts rendered as chips above the field.
  final List<String> suggestions;

  /// Disables the send button and shows a spinner while a reply streams.
  final bool busy;

  /// Hint text for the field.
  final String hint;

  /// Tooltip/semantics label for the send button.
  final String sendTooltip;

  /// Maximum lines the field grows to.
  final int maxLines;

  /// Optional external controller; the composer owns one otherwise.
  final TextEditingController? controller;

  /// Called when a suggestion chip is tapped instead of sending immediately.
  /// When null, tapping a chip sends it right away.
  final ValueChanged<String>? onSuggestionTap;

  @override
  State<PrismPromptComposer> createState() => _PrismPromptComposerState();
}

class _PrismPromptComposerState extends State<PrismPromptComposer> {
  late final TextEditingController _controller =
      widget.controller ?? TextEditingController();
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller.addListener(() => setState(() {}));
  }

  @override
  void didUpdateWidget(PrismPromptComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.busy != oldWidget.busy && !widget.busy) {
      // A finished turn is a good moment to clear a consumed prompt.
      if (_ownsController && oldWidget.busy) _controller.clear();
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty || widget.busy) return;
    _controller.clear();
    widget.onSend(text);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final theme = Theme.of(context);
    final colors = context.prismColors;
    final canSend = _controller.text.trim().isNotEmpty && !widget.busy;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.suggestions.isNotEmpty)
          SizedBox(
            height: tokens.controlHeight * 0.7,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(bottom: tokens.spaceSm),
              itemCount: widget.suggestions.length,
              separatorBuilder: (_, _) => SizedBox(width: tokens.spaceXs),
              itemBuilder: (context, i) {
                final label = widget.suggestions[i];
                return ActionChip(
                  label: Text(label),
                  onPressed: () {
                    if (widget.onSuggestionTap != null) {
                      widget.onSuggestionTap!(label);
                    } else {
                      widget.onSend(label);
                    }
                  },
                );
              },
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: widget.maxLines,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  filled: true,
                  fillColor: colors.surfaceRaised,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceMd,
                    vertical: tokens.spaceSm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusLg),
                    borderSide: BorderSide(color: colors.outline),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(tokens.radiusLg),
                    borderSide: BorderSide(color: colors.outline),
                  ),
                ),
              ),
            ),
            SizedBox(width: tokens.spaceSm),
            Semantics(
              button: true,
              label: widget.sendTooltip,
              child: IconButton.filled(
                tooltip: widget.sendTooltip,
                onPressed: canSend ? _send : null,
                icon: widget.busy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.arrow_upward),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
