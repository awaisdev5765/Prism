import 'package:flutter/material.dart';

import 'tokenizer.dart';

/// Visual configuration for [PrismCodeView].
///
/// Includes a ready-made color scheme for built-in languages, or bring your
/// own by mapping each [TokenKind] to a [TextStyle].
@immutable
class PrismCodeViewStyle {
  /// Creates a style.
  const PrismCodeViewStyle({
    this.textStyle,
    this.tokenStyles = defaultTokenStyles,
    this.background,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.padding = const EdgeInsets.all(14),
    this.lineNumberStyle,
    this.showLineNumbers = false,
    this.enableCopy = true,
    this.wrap = false,
  });

  /// Base text style (font, size). Token styles inherit from it.
  final TextStyle? textStyle;

  /// Colors per [TokenKind].
  final Map<TokenKind, TextStyle> tokenStyles;

  /// Code block background color. Defaults to the theme's surface variant.
  final Color? background;

  /// Corner radius of the code block.
  final BorderRadius borderRadius;

  /// Padding inside the code block.
  final EdgeInsets padding;

  /// Style applied to the gutter line numbers.
  final TextStyle? lineNumberStyle;

  /// Whether to render a gutter with line numbers.
  final bool showLineNumbers;

  /// Whether to show a copy-to-clipboard button.
  final bool enableCopy;

  /// Whether long lines wrap instead of scrolling horizontally.
  final bool wrap;

  /// A pleasant default light-theme palette.
  static const defaultTokenStyles = <TokenKind, TextStyle>{
    TokenKind.keyword: TextStyle(
      color: Color(0xFF7F00FF),
      fontWeight: FontWeight.w600,
    ),
    TokenKind.string: TextStyle(color: Color(0xFF0A7D33)),
    TokenKind.number: TextStyle(color: Color(0xFFB45900)),
    TokenKind.comment: TextStyle(
      color: Color(0xFF8A8F98),
      fontStyle: FontStyle.italic,
    ),
    TokenKind.identifier: TextStyle(color: Color(0xFF0B57D0)),
    TokenKind.punctuation: TextStyle(color: Color(0xFF44474E)),
    TokenKind.plain: TextStyle(),
  };

  /// A dark-theme palette (e.g. One-Dark inspired).
  static const darkTokenStyles = <TokenKind, TextStyle>{
    TokenKind.keyword: TextStyle(
      color: Color(0xFFC678DD),
      fontWeight: FontWeight.w600,
    ),
    TokenKind.string: TextStyle(color: Color(0xFF98C379)),
    TokenKind.number: TextStyle(color: Color(0xFFD19A66)),
    TokenKind.comment: TextStyle(
      color: Color(0xFF7F848E),
      fontStyle: FontStyle.italic,
    ),
    TokenKind.identifier: TextStyle(color: Color(0xFF61AFEF)),
    TokenKind.punctuation: TextStyle(color: Color(0xFFABB2BF)),
    TokenKind.plain: TextStyle(color: Color(0xFFABB2BF)),
  };

  /// Returns a copy with unset fields resolved against [context].
  PrismCodeViewStyle resolve(BuildContext context) {
    final theme = Theme.of(context);
    final base =
        textStyle ??
        theme.textTheme.bodyMedium ??
        const TextStyle(fontSize: 14);
    final isDark = theme.brightness == Brightness.dark;
    final resolvedTokens = identical(tokenStyles, defaultTokenStyles)
        ? (isDark ? darkTokenStyles : defaultTokenStyles)
        : tokenStyles;
    return PrismCodeViewStyle(
      textStyle: base.copyWith(fontFamily: base.fontFamily ?? 'monospace'),
      tokenStyles: {
        for (final kind in TokenKind.values)
          kind: base.merge(resolvedTokens[kind] ?? const TextStyle()),
      },
      background:
          background ??
          (isDark
              ? theme.colorScheme.surfaceContainerHighest
              : const Color(0xFFF6F8FA)),
      borderRadius: borderRadius,
      padding: padding,
      lineNumberStyle:
          lineNumberStyle ??
          TextStyle(color: theme.colorScheme.outline, fontSize: base.fontSize),
      showLineNumbers: showLineNumbers,
      enableCopy: enableCopy,
      wrap: wrap,
    );
  }
}
