import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'style.dart';
import 'tokenizer.dart';

/// Picker for the built-in tokenizers.
enum PrismLanguage {
  /// Dart source code.
  dart(DartTokenizer()),

  /// JSON documents.
  json(JsonTokenizer()),

  /// YAML documents.
  yaml(YamlTokenizer()),

  /// Any other language — renders without highlighting.
  other(null);

  const PrismLanguage(this.tokenizer);

  /// The tokenizer used for this language, or null for no highlighting.
  final LanguageTokenizer? tokenizer;
}

/// A syntax-highlighted, copyable code viewer widget.
///
/// ```dart
/// PrismCodeView(
///   code: 'void main() => print("Hello");',
///   language: PrismLanguage.dart,
///   showLineNumbers: true,
/// )
/// ```
///
/// Pure Flutter — no platform channels — so it runs on Android, iOS, macOS,
/// Windows, Linux, and web. Bring your own tokenizer via [tokenizer] for
/// languages without a built-in one.
class PrismCodeView extends StatefulWidget {
  /// Creates a code viewer.
  const PrismCodeView({
    super.key,
    required this.code,
    this.language = PrismLanguage.other,
    this.tokenizer,
    this.style,
    this.showLineNumbers,
    this.enableCopy,
    this.wrap,
    this.maxHeight,
  });

  /// The source code to display.
  final String code;

  /// Which built-in language to highlight. Ignored when [tokenizer] is set.
  final PrismLanguage language;

  /// A custom tokenizer for languages without built-in support.
  final LanguageTokenizer? tokenizer;

  /// Visual style. Defaults to an adaptive light/dark palette.
  final PrismCodeViewStyle? style;

  /// Overrides [PrismCodeViewStyle.showLineNumbers].
  final bool? showLineNumbers;

  /// Overrides [PrismCodeViewStyle.enableCopy].
  final bool? enableCopy;

  /// Overrides [PrismCodeViewStyle.wrap].
  final bool? wrap;

  /// Constrains the widget height, making the content scrollable.
  final double? maxHeight;

  @override
  State<PrismCodeView> createState() => _PrismCodeViewState();
}

class _PrismCodeViewState extends State<PrismCodeView> {
  @override
  Widget build(BuildContext context) {
    final style = (widget.style ?? const PrismCodeViewStyle()).resolve(context);
    final showLineNumbers = widget.showLineNumbers ?? style.showLineNumbers;
    final enableCopy = widget.enableCopy ?? style.enableCopy;
    final wrap = widget.wrap ?? style.wrap;

    final tokenizer = widget.tokenizer ?? widget.language.tokenizer;
    final tokens =
        tokenizer?.tokenize(widget.code) ??
        [CodeToken(widget.code, TokenKind.plain)];

    final contentSpan = TextSpan(
      children: [
        for (final token in tokens)
          TextSpan(
            text: token.text,
            style: style.tokenStyles[token.kind] ?? style.textStyle,
          ),
      ],
    );
    final content = Text.rich(contentSpan, softWrap: wrap);
    // When not wrapping, allow horizontal panning of long lines.
    final codeArea = wrap
        ? content
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: content,
          );

    Widget block = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: style.borderRadius,
      ),
      padding: style.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (enableCopy) _CopyBar(style: style, code: widget.code),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showLineNumbers)
                _LineGutter(
                  lineCount: widget.code.split('\n').length,
                  style: style,
                ),
              Expanded(child: codeArea),
            ],
          ),
        ],
      ),
    );

    if (widget.maxHeight != null) {
      block = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight!),
        child: SingleChildScrollView(child: block),
      );
    }

    return block;
  }
}

class _CopyBar extends StatelessWidget {
  const _CopyBar({required this.style, required this.code});

  final PrismCodeViewStyle style;
  final String code;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Copy to clipboard',
          icon: const Icon(Icons.copy, size: 18),
          color: Theme.of(context).colorScheme.outline,
          onPressed: () => Clipboard.setData(ClipboardData(text: code)),
        ),
      ),
    );
  }
}

class _LineGutter extends StatelessWidget {
  const _LineGutter({required this.lineCount, required this.style});

  final int lineCount;
  final PrismCodeViewStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 1; i <= lineCount; i++) Text('$i')],
      ),
    );
  }
}
