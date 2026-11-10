import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// One bar in a [PrismBarChart].
class PrismBar {
  /// Creates a bar with a [label] and [value].
  const PrismBar({required this.label, required this.value, this.color});
  final String label;
  final double value;
  final Color? color;
}

/// A token-styled vertical bar chart.
///
/// Bars scale against the largest value, labels sit underneath, and the
/// tallest bar picks up the highlight colour by default. Screen readers get
/// the data as a sentence.
///
/// ```dart
/// PrismBarChart(
///   bars: [
///     PrismBar(label: 'Mon', value: 12),
///     PrismBar(label: 'Tue', value: 19, color: Colors.teal),
///   ],
/// )
/// ```
class PrismBarChart extends StatelessWidget {
  /// Creates a bar chart.
  const PrismBarChart({
    super.key,
    required this.bars,
    this.height = 180,
    this.showValues = true,
    this.barColor,
    this.highlightColor,
    this.labelStyle,
  });

  /// The data, in drawing order left to right.
  final List<PrismBar> bars;

  /// Chart height.
  final double height;

  /// Whether to print the value above each bar.
  final bool showValues;

  /// Colour for every bar that is not the maximum.
  final Color? barColor;

  /// Colour for the maximum bar; defaults to the success role colour.
  final Color? highlightColor;

  /// Style for the axis labels.
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final theme = Theme.of(context);
    final highlight = highlightColor ?? colors.success;
    final base = barColor ?? theme.colorScheme.primary;
    final max = bars.fold(0.0, (m, b) => math.max(m, b.value));

    return Semantics(
      label: 'Bar chart',
      value: bars.map((b) => '${b.label}: ${_num(b.value)}').join(', '),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final bar in bars)
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceXs),
                  child: Column(
                    children: [
                      if (showValues)
                        Text(
                          _num(bar.value),
                          style: theme.textTheme.labelSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            widthFactor: 1,
                            heightFactor: max == 0
                                ? 0.02
                                : (bar.value / max) * 0.92,
                            child: Container(
                              decoration: BoxDecoration(
                                color: bar.value == max && max > 0
                                    ? bar.color ?? highlight
                                    : bar.color ?? base.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(tokens.radiusSm),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: tokens.spaceXs),
                      Text(
                        bar.label,
                        style:
                            labelStyle ??
                            theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

/// A token-styled line chart with optional gradient fill and points.
///
/// Pure CustomPainter — no fl_chart dependency. Provide [labels] to show an
/// x-axis; they are thinned automatically so they never overlap.
///
/// ```dart
/// PrismLineChart(
///   values: weeklyRevenue,
///   labels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
///   semantic: PrismSemantic.success,
/// )
/// ```
class PrismLineChart extends StatelessWidget {
  /// Creates a line chart. Requires at least two values.
  const PrismLineChart({
    super.key,
    required this.values,
    this.labels = const [],
    this.height = 180,
    this.color,
    this.semantic,
    this.fill = true,
    this.showPoints = true,
    this.showGrid = true,
  });

  /// The series, in x order.
  final List<double> values;

  /// Optional x-axis labels, one per value; thinned to fit.
  final List<String> labels;

  /// Chart height, excluding the label strip.
  final double height;

  /// Stroke colour; defaults to the role colour from [semantic], then primary.
  final Color? color;

  /// Semantic role picking the stroke colour when [color] is null.
  final PrismSemantic? semantic;

  /// Whether to fill the area under the line.
  final bool fill;

  /// Whether to draw a dot per point.
  final bool showPoints;

  /// Whether to draw horizontal gridlines.
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final theme = Theme.of(context);
    final lineColor =
        color ??
        switch (semantic) {
          PrismSemantic.success => colors.success,
          PrismSemantic.warning => colors.warning,
          PrismSemantic.error => colors.error,
          PrismSemantic.info => colors.info,
          null => theme.colorScheme.primary,
        };

    final minV = values.fold(values.first, math.min);
    final maxV = values.fold(values.first, math.max);

    return Semantics(
      label: 'Line chart',
      value:
          'first ${values.first}, last ${values.last}, '
          'low ${_fmt(minV)}, high ${_fmt(maxV)}',
      child: Column(
        children: [
          SizedBox(
            height: height,
            width: double.infinity,
            child: CustomPaint(
              painter: _LinePainter(
                values: values,
                color: lineColor,
                fill: fill,
                showPoints: showPoints,
                showGrid: showGrid,
                gridColor: colors.outline,
                radius: tokens.radiusSm,
                strokeWidth: 2,
              ),
            ),
          ),
          if (labels.isNotEmpty)
            Row(
              children: [
                for (final step in _thinnedLabels(labels))
                  Expanded(
                    child: Text(
                      step,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Thins labels so adjacent ones never collide on narrow windows.
  List<String> _thinnedLabels(List<String> labels) {
    if (labels.length <= 2) return labels;
    // Target roughly 40px per label; thin from the middle, keep the ends.
    final keep = <String>[];
    final step = (labels.length / (labels.length ~/ 4 + 1)).ceil();
    for (var i = 0; i < labels.length; i++) {
      if (i == 0 || i == labels.length - 1 || i % step == 0) {
        keep.add(labels[i]);
      } else {
        keep.add('');
      }
    }
    return keep;
  }

  String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.color,
    required this.fill,
    required this.showPoints,
    required this.showGrid,
    required this.gridColor,
    required this.radius,
    required this.strokeWidth,
  });

  final List<double> values;
  final Color color;
  final bool fill;
  final bool showPoints;
  final bool showGrid;
  final Color gridColor;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final minV = values.fold(values.first, math.min);
    final maxV = values.fold(values.first, math.max);
    final range = (maxV - minV) == 0 ? 1.0 : maxV - minV;
    final dx = size.width / (values.length - 1);
    final top = size.height * 0.08;
    final bottom = size.height * 0.92;

    Offset point(int i) =>
        Offset(i * dx, bottom - ((values[i] - minV) / range) * (bottom - top));

    if (showGrid) {
      final grid = Paint()
        ..color = gridColor.withValues(alpha: 0.4)
        ..strokeWidth = 1;
      for (final fraction in [0.25, 0.5, 0.75]) {
        final y = bottom - (bottom - top) * fraction;
        canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
      }
    }

    final line = Path()..moveTo(point(0).dx, point(0).dy);
    for (var i = 1; i < values.length; i++) {
      line.lineTo(point(i).dx, point(i).dy);
    }

    if (fill) {
      final area = Path.from(line)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              color.withValues(alpha: 0.30),
              color.withValues(alpha: 0.02),
            ],
          ).createShader(Offset.zero & size),
      );
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

    if (showPoints) {
      for (var i = 0; i < values.length; i++) {
        canvas.drawCircle(point(i), radius, Paint()..color = color);
      }
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      old.values != values ||
      old.color != color ||
      old.fill != fill ||
      old.showPoints != showPoints;
}

/// One slice of a [PrismDonutChart].
class PrismDonutSlice {
  /// Creates a slice. [color] is optional — slices cycle through a
  /// built-in palette when omitted.
  const PrismDonutSlice({required this.label, required this.value, this.color});
  final String label;
  final double value;
  final Color? color;
}

/// A token-styled donut chart with a centre label and a legend.
class PrismDonutChart extends StatelessWidget {
  /// Creates a donut chart.
  const PrismDonutChart({
    super.key,
    required this.slices,
    this.size = 160,
    this.centreLabel,
    this.centreValue,
  });

  /// The data. Values are normalised, so absolute scale does not matter.
  final List<PrismDonutSlice> slices;

  /// Diameter of the donut.
  final double size;

  /// Static text in the middle, e.g. "Traffic".
  final String? centreLabel;

  /// Emphasised value in the middle, e.g. "12k visits".
  final String? centreValue;

  static const _palette = [
    Color(0xFF4285F4),
    Color(0xFFEA4335),
    Color(0xFFFBBC05),
    Color(0xFF34A853),
    Color(0xFF9C27B0),
    Color(0xFF00ACC1),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final theme = Theme.of(context);
    final total = slices.fold(0.0, (s, e) => s + e.value);
    final resolved = <Color>[
      for (var i = 0; i < slices.length; i++)
        slices[i].color ?? _palette[i % _palette.length],
    ];

    return Semantics(
      label: centreLabel ?? 'Donut chart',
      value: slices
          .map(
            (s) =>
                '${s.label}: '
                '${total == 0 ? 0 : (s.value / total * 100).round()}%',
          )
          .join(', '),
      child: Row(
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _DonutPainter(
                    slices: slices.map((s) => s.value).toList(),
                    colors: resolved,
                    strokeWidth: tokens.spaceLg,
                    gap: tokens.spaceXs / 2,
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (centreValue != null)
                        Text(
                          centreValue!,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      if (centreLabel != null)
                        Text(
                          centreLabel!,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < slices.length; i++)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: tokens.spaceXs / 2),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: resolved[i],
                            borderRadius: BorderRadius.circular(
                              tokens.radiusSm / 2,
                            ),
                          ),
                        ),
                        SizedBox(width: tokens.spaceSm),
                        Expanded(
                          child: Text(
                            slices[i].label,
                            style: theme.textTheme.bodyMedium,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${total == 0 ? 0 : (slices[i].value / total * 100).round()}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.colors,
    required this.strokeWidth,
    required this.gap,
  });

  final List<double> slices;
  final List<Color> colors;
  final double strokeWidth;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final total = slices.fold(0.0, (s, e) => s + e);
    if (total == 0) return;
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    var start = -math.pi / 2;
    const sweepFull = 2 * math.pi;
    final sweepGap = slices.length > 1 ? gap / radius : 0.0;

    for (var i = 0; i < slices.length; i++) {
      final sweep = slices[i] / total * sweepFull;
      final draw = math.max(0.0, sweep - sweepGap);
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: radius),
        start,
        draw,
        false,
        paint..color = colors[i],
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.slices != slices || old.colors != colors;
}
