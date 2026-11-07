import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A compact HSV colour picker with hue/saturation/value drag surfaces and a
/// hex text field.
///
/// Two orthogonal surfaces: a saturation/value square for the currently
/// selected hue, and a hue bar below it. A hex field mirrors the current
/// colour, so users can paste a brand colour exactly.
///
/// ```dart
/// PrismColorPicker(
///   color: theme.colorScheme.primary,
///   onChanged: (c) => setState(() => accent = c),
/// )
/// ```
class PrismColorPicker extends StatefulWidget {
  /// Creates a colour picker.
  const PrismColorPicker({
    super.key,
    required this.color,
    required this.onChanged,
    this.showHex = true,
  });

  /// The currently selected colour.
  final Color color;

  /// Called as the user drags or types. Reports opaque sRGB colours.
  final ValueChanged<Color> onChanged;

  /// Whether the hex input row is shown.
  final bool showHex;

  @override
  State<PrismColorPicker> createState() => _PrismColorPickerState();
}

class _PrismColorPickerState extends State<PrismColorPicker> {
  HSV? _hsv;

  HSV get _current => _hsv ?? HSV.fromColor(widget.color);

  void _report(HSV hsv) {
    widget.onChanged(hsv.toColor());
    setState(() => _hsv = hsv);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final hsv = _current;

    return Semantics(
      label: 'Colour picker',
      value: '#${_hex(hsv.toColor())}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusMd),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _SaturationValueBox(
                hue: hsv.h,
                saturation: hsv.s,
                value: hsv.v,
                onChanged: _report,
              ),
            ),
          ),
          SizedBox(height: tokens.spaceSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(tokens.radiusSm),
            child: SizedBox(
              height: 28,
              child: _HueBar(
                hue: hsv.h,
                onChanged: (h) => _report(HSV(h, hsv.s, hsv.v)),
              ),
            ),
          ),
          if (widget.showHex) ...[
            SizedBox(height: tokens.spaceSm),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: hsv.toColor(),
                    borderRadius: BorderRadius.circular(tokens.radiusSm),
                    border: Border.all(color: colors.outline),
                  ),
                ),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: TextFormField(
                    key: ValueKey('#${_hex(hsv.toColor())}'),
                    initialValue: '#${_hex(hsv.toColor())}',
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Hex',
                      prefixText: '#',
                    ),
                    onFieldSubmitted: (text) {
                      final parsed = int.tryParse(
                        text.replaceAll('#', ''),
                        radix: 16,
                      );
                      if (parsed != null && parsed >= 0 && parsed <= 0xFFFFFF) {
                        _report(HSV.fromColor(Color(parsed | 0xFF000000)));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

String _hex(Color c) =>
    (c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0');

/// Hue/saturation/value triple.
@immutable
class HSV {
  const HSV(this.h, this.s, this.v);

  final double h; // 0..360
  final double s; // 0..1
  final double v; // 0..1

  static HSV fromColor(Color c) {
    final r = c.r, g = c.g, b = c.b;
    final max = [r, g, b].reduce((a, e) => e > a ? e : a);
    final min = [r, g, b].reduce((a, e) => e < a ? e : a);
    final d = max - min;
    final h = d == 0
        ? 0.0
        : max == r
        ? 60 * (((g - b) / d) % 6)
        : max == g
        ? 60 * ((b - r) / d + 2)
        : 60 * ((r - g) / d + 4);
    return HSV(h < 0 ? h + 360 : h, max == 0 ? 0 : d / max, max);
  }

  Color toColor() {
    final chroma = v * s;
    final hp = (h % 360) / 60;
    final x = chroma * (1 - ((hp % 2) - 1).abs());
    double r = 0, g = 0, b = 0;
    if (hp < 1) {
      r = chroma;
      g = x;
    } else if (hp < 2) {
      r = x;
      g = chroma;
    } else if (hp < 3) {
      g = chroma;
      b = x;
    } else if (hp < 4) {
      g = x;
      b = chroma;
    } else if (hp < 5) {
      r = x;
      b = chroma;
    } else {
      r = chroma;
      b = x;
    }
    final m = v - chroma;
    return Color.fromRGBO(
      ((r + m) * 255).round(),
      ((g + m) * 255).round(),
      ((b + m) * 255).round(),
      1,
    );
  }
}

class _SaturationValueBox extends StatelessWidget {
  const _SaturationValueBox({
    required this.hue,
    required this.saturation,
    required this.value,
    required this.onChanged,
  });

  final double hue;
  final double saturation;
  final double value;
  final void Function(HSV) onChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        void handle(Offset local) {
          onChanged(
            HSV(
              hue,
              (local.dx / constraints.maxWidth).clamp(0, 1).toDouble(),
              (1 - local.dy / constraints.maxHeight).clamp(0, 1).toDouble(),
            ),
          );
        }

        return GestureDetector(
          onPanStart: (d) => handle(d.localPosition),
          onPanUpdate: (d) => handle(d.localPosition),
          onPanEnd: (_) {},
          onTapDown: (d) => handle(d.localPosition),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Hue base
              ColoredBox(color: HSV(hue, 1, 1).toColor()),
              // White -> transparent horizontal (saturation)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.transparent],
                  ),
                ),
              ),
              // Transparent -> black vertical (value)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black],
                  ),
                ),
              ),
              // Thumb
              Positioned(
                left: (saturation * constraints.maxWidth - 12).clamp(
                  -12.0,
                  constraints.maxWidth - 12,
                ),
                top: ((1 - value) * constraints.maxHeight - 12).clamp(
                  -12.0,
                  constraints.maxHeight - 12,
                ),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Colors.black38, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _HueBar extends StatelessWidget {
  const _HueBar({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  static const _stops = [
    Color(0xFFFF0000),
    Color(0xFFFFFF00),
    Color(0xFF00FF00),
    Color(0xFF00FFFF),
    Color(0xFF0000FF),
    Color(0xFFFF00FF),
    Color(0xFFFF0000),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onPanStart: (d) =>
              onChanged(d.localPosition.dx / constraints.maxWidth * 360),
          onPanUpdate: (d) =>
              onChanged(d.localPosition.dx / constraints.maxWidth * 360),
          onTapDown: (d) =>
              onChanged(d.localPosition.dx / constraints.maxWidth * 360),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: _stops),
                ),
              ),
              Positioned(
                left: (hue / 360 * constraints.maxWidth - 6).clamp(
                  -6.0,
                  constraints.maxWidth - 12,
                ),
                top: 4,
                child: Container(
                  width: 12,
                  height: 20,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 3),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
