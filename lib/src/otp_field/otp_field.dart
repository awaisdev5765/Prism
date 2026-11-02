import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// A one-time-code / PIN field with paste, auto-submit and SMS autofill.
///
/// Every friction point of OTP entry is handled for you: typing fills boxes
/// left to right, backspace deletes from the end, pasting a whole code from
/// an SMS fills every box at once, and [onCompleted] fires as soon as the
/// last digit lands. The field advertises the `oneTimeCode` autofill hint, so
/// iOS and Android can offer their native code suggestions.
///
/// ```dart
/// PrismOtpField(
///   length: 6,
///   onCompleted: (code) => verify(code),
/// )
/// ```
///
/// Digit boxes are pure decoration — a single transparent [TextField] behind
/// them owns the text. That keeps platform behaviour (IME, autofill, paste,
/// selection, screen readers) exactly as users expect, instead of fighting it
/// with six separate fields.
class PrismOtpField extends StatefulWidget {
  /// Creates an OTP field.
  const PrismOtpField({
    super.key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
    this.controller,
    this.autofocus = false,
    this.enabled = true,
    this.obscure = false,
    this.boxSize = 48,
    this.gap = 8,
    this.errorText,
    this.helperText,
    this.autofillHints = const [AutofillHints.oneTimeCode],
    this.keyboardType = TextInputType.number,
    this.groupSeparatorAfter,
    this.accentColor,
    this.hasError = false,
    this.semanticLabel = 'Verification code',
    this.boxBuilder,
  });

  /// Number of digits.
  final int length;

  /// Called whenever any digit changes, with the current (possibly partial)
  /// code.
  final ValueChanged<String>? onChanged;

  /// Called when every box is filled.
  final ValueChanged<String>? onCompleted;

  /// Optional external controller.
  final TextEditingController? controller;

  /// Whether to focus the field on mount.
  final bool autofocus;

  /// Whether the field accepts input.
  final bool enabled;

  /// Masks digits as bullets — use for PINs and passcodes.
  final bool obscure;

  /// Width and height of each digit box.
  final double boxSize;

  /// Gap between digit boxes.
  final double gap;

  /// Error text shown below the field.
  final String? errorText;

  /// Helper text shown below the field.
  final String? helperText;

  /// Autofill hints handed to the platform.
  final Iterable<String> autofillHints;

  /// Keyboard type for code entry.
  final TextInputType keyboardType;

  /// Draw a wider gap after this many boxes (3 gives the familiar `123 456`).
  final int? groupSeparatorAfter;

  /// Border/accent color when focused or filled. Defaults to the primary color.
  final Color? accentColor;

  /// Forces error styling on.
  final bool hasError;

  /// Accessibility label for the field.
  final String semanticLabel;

  /// Replaces the default digit box rendering.
  final Widget Function(
    BuildContext context,
    int index,
    String char,
    bool focused,
  )?
  boxBuilder;

  @override
  State<PrismOtpField> createState() => _PrismOtpFieldState();
}

class _PrismOtpFieldState extends State<PrismOtpField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _controller.addListener(_handleChanged);
    _focusNode.addListener(_handleFocus);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChanged);
    _focusNode.removeListener(_handleFocus);
    if (_ownsController) _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocus() => setState(() {});

  void _handleChanged() {
    setState(() {});
    widget.onChanged?.call(_controller.text);
    if (_controller.text.length == widget.length) {
      widget.onCompleted?.call(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;
    final accent = widget.accentColor ?? scheme.primary;
    final error = widget.errorText;
    final isError = widget.hasError || error != null;
    final digits = _controller.text;
    // The "active" box is the one the next keystroke will land in.
    final activeIndex = digits.length.clamp(0, widget.length - 1);
    final focused = _focusNode.hasFocus;

    final boxes = <Widget>[];
    for (var i = 0; i < widget.length; i++) {
      if (i > 0 &&
          widget.groupSeparatorAfter != null &&
          i == widget.groupSeparatorAfter) {
        boxes.add(SizedBox(width: widget.gap * 1.5));
      } else if (i > 0) {
        boxes.add(SizedBox(width: widget.gap));
      }

      final char = i < digits.length ? digits[i] : '';
      final boxFocused = focused && i == activeIndex;

      boxes.add(
        widget.boxBuilder?.call(context, i, char, boxFocused) ??
            _OtpBox(
              char: char,
              obscure: widget.obscure,
              size: widget.boxSize,
              enabled: widget.enabled,
              focused: boxFocused,
              isError: isError,
              accent: accent,
              outline: colors.outline,
              surface: colors.surfaceRaised,
              borderWidth: tokens.borderWidth,
              radius: tokens.radiusMd,
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            ExcludeSemantics(
              child: Wrap(
                alignment: WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: boxes,
              ),
            ),
            // Transparent field on top: owns focus, IME, autofill and paste.
            Positioned.fill(
              child: Opacity(
                opacity: 0,
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: widget.keyboardType,
                  autofillHints: widget.autofillHints,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  enableInteractiveSelection: true,
                  showCursor: false,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  style: const TextStyle(fontSize: 1),
                ),
              ),
            ),
          ],
        ),
        if (error != null || widget.helperText != null) ...[
          SizedBox(height: tokens.spaceSm),
          Text(
            error ?? widget.helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: error != null ? colors.error : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.char,
    required this.obscure,
    required this.size,
    required this.enabled,
    required this.focused,
    required this.isError,
    required this.accent,
    required this.outline,
    required this.surface,
    required this.borderWidth,
    required this.radius,
  });

  final String char;
  final bool obscure;
  final double size;
  final bool enabled;
  final bool focused;
  final bool isError;
  final Color accent;
  final Color outline;
  final Color surface;
  final double borderWidth;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filled = char.isNotEmpty;
    final borderColor = isError
        ? scheme.error
        : focused
        ? accent
        : filled
        ? accent.withValues(alpha: 0.55)
        : outline;

    Widget content = const SizedBox.shrink();
    if (filled) {
      content = obscure
          ? Container(
              width: size * 0.2,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: scheme.onSurface,
                shape: BoxShape.circle,
              ),
            )
          : Text(
              char,
              textScaler: TextScaler.noScaling,
              style: TextStyle(
                fontSize: size * 0.42,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
                height: 1,
              ),
            );
    }

    return AnimatedContainer(
      duration: context.prismMotion(const Duration(milliseconds: 140)),
      curve: Curves.easeOut,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: enabled ? surface : surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: borderColor,
          width: focused || isError ? 2 : borderWidth,
        ),
        boxShadow: focused && !isError
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.16),
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: content,
    );
  }
}
