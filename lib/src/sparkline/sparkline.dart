import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A tiny inline trend line for lists, tables and stat cards.
///
/// Draws the [values] as a polyline in the ambient primary colour (or
/// [color]/[semantic] if given), with an optional gradient fill underneath.
/// Deliberately label-free — pass a [semanticLabel] so screen readers get the
/// trend in words instead.
///
/// ```dart
/// PrismSparkline(values: weekRevenue, semantic: PrismSemantic.success)
/// ```
class PrismSparkline extends StatelessWidget {
  /// Creates a sparkline. Requires at least two values.
  const PrismSparkline({
    super.key,
    required this.values,
    this.width = 96,
    this.height = 28,
    this.color,
    this.semantic,
    this.fill = true,
    this.strokeWidth = 2,
    this.semanticLabel,
  });

  /// The data to plot, in order. Deltas are drawn left-to-right.
  final List<double> values;

  /// Rendered width.
  final double width;

  /// Rendered height.
  final double height;

  /// Stroke colour; defaults to the role colour from [semantic], then the
  /// ambient primary.
  final Color? color;

  /// Semantic role picking the stroke colour when [color] is null.
  final PrismSemantic? semantic;

  /// Whether to draw a gradient fill under the line.
  final bool fill;

  /// Line thickness.
  final double strokeWidth;

  /// Screen-reader description of the trend, e.g. "Trending up 12% this week".
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final lineColor =
        color ??
        switch (semantic) {
          PrismSemantic.success => colors.success,
          PrismSemantic.warning => colors.warning,
          PrismSemantic.error => colors.error,
          PrismSemantic.info => colors.info,
          null => theme.colorScheme.primary,
        };

    return Semantics(
      label: semanticLabel ?? 'Trend chart',
      value: _describe(),
      child: CustomPaint(
        size: Size(width, height),
        painter: _SparklinePainter(
          values: values,
          color: lineColor,
          fill: fill,
          strokeWidth: strokeWidth,
          radius: tokens.radiusSm,
        ),
      ),
    );
  }

  String _describe() {
    final first = values.first;
    final last = values.last;
    if (first == 0) return last > 0 ? 'rising from zero' : 'flat';
    final delta = (last - first) / first.abs() * 100;
    if (delta.abs() < 1) return 'flat';
    return delta > 0 ? 'up $delta percent' : 'down ${delta.abs()} percent';
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.color,
    required this.fill,
    required this.strokeWidth,
    required this.radius,
  });

  final List<double> values;
  final Color color;
  final bool fill;
  final double strokeWidth;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final minV = values.reduce(math.min);
    final maxV = values.reduce(math.max);
    final range = (maxV - minV) == 0 ? 1.0 : maxV - minV;
    final dx = size.width / (values.length - 1);

    Offset point(int i) => Offset(
      i * dx,
      size.height -
          ((values[i] - minV) / range) * size.height * 0.9 -
          size.height * 0.05,
    );

    final line = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(point(i).dx, point(i).dy);
    }

    if (fill) {
      final area = Path.from(line)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      // Gradient that hugs the line via a clip of the area under it.
      canvas.save();
      canvas.clipPath(area);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.25),
              color.withValues(alpha: 0.0),
            ],
          ).createShader(Offset.zero & size),
      );
      canvas.restore();
    }

    canvas.drawPath(
      line,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) =>
      old.values != values ||
      old.color != color ||
      old.fill != fill ||
      old.strokeWidth != strokeWidth;
}
