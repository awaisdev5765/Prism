import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// A free-form tag/chip input: type, press Enter or comma, get a chip.
///
/// Handles the awkward parts of tag entry so you don't have to: paste of
/// comma- or newline-separated lists, backspace-to-delete-last, duplicate
/// rejection, an optional maximum, and validation feedback.
///
/// ```dart
/// PrismChipInput(
///   label: 'Labels',
///   value: labels,
///   suggestions: const ['work', 'personal', 'urgent'],
///   onChanged: (next) => setState(() => labels = next),
/// )
/// ```
class PrismChipInput extends StatefulWidget {
  /// Creates a chip input.
  const PrismChipInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.suggestions = const [],
    this.maxChips,
    this.allowDuplicates = false,
    this.enabled = true,
    this.textInputAction = TextInputAction.done,
    this.chipBuilder,
    this.validator,
    this.delimiters = const {',', '\n', ';'},
    this.leadingIcon,
  });

  /// Current chips. The widget never mutates this list — it calls
  /// [onChanged] with a new one.
  final List<String> value;

  /// Called with the updated list whenever a chip is added or removed.
  final ValueChanged<List<String>> onChanged;

  /// Field label rendered above the input.
  final String? label;

  /// Placeholder shown when the field is empty.
  final String? hint;

  /// Helper text under the field.
  final String? helperText;

  /// Error text under the field; overrides [helperText] when non-null.
  final String? errorText;

  /// Optional suggestion list offered as overlay chips when the field is
  /// focused and the query matches.
  final List<String> suggestions;

  /// Reject new chips once this many exist.
  final int? maxChips;

  /// Whether the same label may appear twice.
  final bool allowDuplicates;

  /// Whether the field accepts input.
  final bool enabled;

  /// Keyboard action for the text field.
  final TextInputAction textInputAction;

  /// Replaces the default chip rendering.
  final Widget Function(
    BuildContext context,
    String label,
    VoidCallback remove,
  )?
  chipBuilder;

  /// Validates an individual entry before it is accepted. Return an error
  /// message to reject it.
  final String? Function(String value)? validator;

  /// Characters that commit the current entry when typed.
  final Set<String> delimiters;

  /// Optional leading icon.
  final IconData? leadingIcon;

  @override
  State<PrismChipInput> createState() => _PrismChipInputState();
}

class _PrismChipInputState extends State<PrismChipInput> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Commits any delimiter typed inside the text (e.g. pasted lists).
  void _onTextChanged() {
    final text = _controller.text;
    if (!text.contains(RegExp(r'[,\n;]'))) return;
    final parts = text.split(RegExp(r'[,\n;]'));
    final trailing = parts.removeLast();
    for (final part in parts) {
      _commit(part);
    }
    _controller.value = TextEditingValue(
      text: trailing,
      selection: TextSelection.collapsed(offset: trailing.length),
    );
  }

  void _commit(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return;

    final rejected = widget.validator?.call(value);
    if (rejected != null) {
      setState(() => _error = rejected);
      return;
    }
    if (!widget.allowDuplicates &&
        widget.value.any((v) => v.toLowerCase() == value.toLowerCase())) {
      setState(() => _error = '"$value" is already added');
      return;
    }
    if (widget.maxChips != null && widget.value.length >= widget.maxChips!) {
      setState(() => _error = 'Maximum of ${widget.maxChips} reached');
      return;
    }

    setState(() => _error = null);
    widget.onChanged([...widget.value, value]);
    _controller.clear();
    HapticFeedback.selectionClick();
  }

  void _removeAt(int index) {
    final next = [...widget.value]..removeAt(index);
    setState(() => _error = null);
    widget.onChanged(next);
  }

  List<String> get _visibleSuggestions {
    final query = _controller.text.trim().toLowerCase();
    return widget.suggestions
        .where(
          (s) => !widget.value.any((v) => v.toLowerCase() == s.toLowerCase()),
        )
        .where((s) => query.isEmpty || s.toLowerCase().contains(query))
        .take(8)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;
    final error = widget.errorText ?? _error;
    final atMax =
        widget.maxChips != null && widget.value.length >= widget.maxChips!;
    final suggestions = _focusNode.hasFocus
        ? _visibleSuggestions
        : const <String>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(widget.label!, style: Theme.of(context).textTheme.labelLarge),
          SizedBox(height: tokens.spaceSm),
        ],
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceSm,
            vertical: tokens.spaceSm,
          ),
          decoration: BoxDecoration(
            color: widget.enabled ? colors.surfaceRaised : colors.surfaceSunken,
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            border: Border.all(
              color: error != null ? colors.error : colors.outline,
              width: error != null ? 1.5 : tokens.borderWidth,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.value.isNotEmpty)
                Wrap(
                  spacing: tokens.spaceSm,
                  runSpacing: tokens.spaceSm,
                  children: [
                    for (var i = 0; i < widget.value.length; i++)
                      widget.chipBuilder?.call(
                            context,
                            widget.value[i],
                            () => _removeAt(i),
                          ) ??
                          _DefaultChip(
                            label: widget.value[i],
                            onRemove: widget.enabled
                                ? () => _removeAt(i)
                                : null,
                          ),
                  ],
                ),
              if (widget.value.isNotEmpty) SizedBox(height: tokens.spaceSm),
              Row(
                children: [
                  if (widget.leadingIcon != null) ...[
                    Icon(
                      widget.leadingIcon,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                    SizedBox(width: tokens.spaceSm),
                  ],
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: widget.enabled && !atMax,
                      textInputAction: widget.textInputAction,
                      style: Theme.of(context).textTheme.bodyMedium,
                      decoration: InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        hintText: atMax
                            ? 'Maximum reached'
                            : (widget.hint ?? 'Add a tag…'),
                      ),
                      onSubmitted: _commit,
                      onEditingComplete: () => _commit(_controller.text),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (error != null || widget.helperText != null) ...[
          SizedBox(height: tokens.spaceXs),
          Text(
            error ?? widget.helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: error != null ? colors.error : scheme.onSurfaceVariant,
            ),
          ),
        ],
        if (suggestions.isNotEmpty) ...[
          SizedBox(height: tokens.spaceSm),
          Wrap(
            spacing: tokens.spaceSm,
            runSpacing: tokens.spaceSm,
            children: [
              for (final suggestion in suggestions)
                ActionChip(
                  label: Text(suggestion),
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _commit(suggestion),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _DefaultChip extends StatelessWidget {
  const _DefaultChip({required this.label, this.onRemove});

  final String label;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    return Container(
      padding: EdgeInsets.only(
        left: tokens.spaceMd,
        right: onRemove == null ? tokens.spaceMd : tokens.spaceSm,
        top: tokens.spaceXs + 2,
        bottom: tokens.spaceXs + 2,
      ),
      decoration: BoxDecoration(
        color: colors.infoContainer,
        borderRadius: BorderRadius.circular(tokens.radiusXl),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.onInfoContainer,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 2),
            Semantics(
              button: true,
              label: 'Remove $label',
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close,
                    size: 15,
                    color: colors.onInfoContainer,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
