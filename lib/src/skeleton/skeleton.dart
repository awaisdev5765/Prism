import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A shimmering placeholder shown while content loads.
///
/// Skeletons communicate structure better than a spinner: the page keeps its
/// shape and simply "fills in". Every Prism skeleton animation is driven by a
/// single [AnimationController] per widget, is disabled automatically when
/// the platform requests reduced motion, and never runs off-screen.
///
/// ```dart
/// if (loading)
///   const PrismSkeleton.card()
/// else
///   NoteCard(note);
/// ```
///
/// See also [PrismSkeletonList], which lays out several skeletons for the
/// common "list is loading" case.
class PrismSkeleton extends StatefulWidget {
  /// Creates a skeleton block.
  const PrismSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
    this.shape = PrismSkeletonShape.rounded,
    this.baseColor,
    this.highlightColor,
    this.animate = true,
  });

  /// A skeleton circle, sized by [diameter].
  const PrismSkeleton.circle({
    super.key,
    required double diameter,
    this.baseColor,
    this.highlightColor,
    this.animate = true,
  }) : width = diameter,
       height = diameter,
       borderRadius = null,
       shape = PrismSkeletonShape.circle;

  /// Fixed width; stretches to the parent when null.
  final double? width;

  /// Fixed height.
  final double height;

  /// Corner radius override; defaults to [PrismTokens.radiusSm].
  final BorderRadius? borderRadius;

  /// Overall shape.
  final PrismSkeletonShape shape;

  /// Base (unlit) color; defaults to the theme's surface-container.
  final Color? baseColor;

  /// Shimmer highlight color; defaults to a lightened surface.
  final Color? highlightColor;

  /// Whether to run the shimmer. Set false for a static placeholder.
  final bool animate;

  @override
  State<PrismSkeleton> createState() => _PrismSkeletonState();
}

/// The shape of a [PrismSkeleton].
enum PrismSkeletonShape {
  /// Rounded rectangle (default).
  rounded,

  /// Fully rounded pill — good for chips and buttons.
  pill,

  /// Circle — good for avatars and icons.
  circle,

  /// Sharp rectangle.
  square,
}

class _PrismSkeletonState extends State<PrismSkeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.animate) _start();
  }

  @override
  void didUpdateWidget(PrismSkeleton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && _controller == null) {
      _start();
    } else if (!widget.animate && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  void _start() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  BorderRadius _radius(PrismTokens tokens) {
    if (widget.borderRadius != null) return widget.borderRadius!;
    switch (widget.shape) {
      case PrismSkeletonShape.circle:
        return BorderRadius.circular(widget.height / 2);
      case PrismSkeletonShape.pill:
        return BorderRadius.circular(widget.height / 2);
      case PrismSkeletonShape.square:
        return BorderRadius.zero;
      case PrismSkeletonShape.rounded:
        return BorderRadius.circular(tokens.radiusSm);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final base = widget.baseColor ?? colors.surfaceSunken;
    final highlight =
        widget.highlightColor ??
        Color.alphaBlend(
          Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
          base,
        );

    Widget block(Color color) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(color: color, borderRadius: _radius(tokens)),
    );

    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final controller = _controller;
    if (controller == null || reduceMotion) return block(base);

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        // Sweep a soft gradient highlight from left to right.
        final t = controller.value;
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t) + 1, 0),
              colors: [base, highlight, base],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: block(base),
        );
      },
    );
  }
}

/// A paragraph-shaped skeleton — several lines with a shorter last line.
class PrismSkeletonText extends StatelessWidget {
  /// Creates a text-shaped skeleton.
  const PrismSkeletonText({
    super.key,
    this.lines = 3,
    this.spacing = 8,
    this.lastLineFraction = 0.6,
    this.lineHeight = 14,
  });

  /// How many lines to draw.
  final int lines;

  /// Vertical gap between lines.
  final double spacing;

  /// Width of the final line, as a fraction of the full width.
  final double lastLineFraction;

  /// Height of each line.
  final double lineHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < lines; i++) ...[
          if (i > 0) SizedBox(height: spacing),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: i == lines - 1 ? lastLineFraction : 1,
            child: PrismSkeleton(height: lineHeight),
          ),
        ],
      ],
    );
  }
}

/// A card-shaped skeleton: media block plus body copy.
class PrismSkeletonCard extends StatelessWidget {
  /// Creates a card-shaped skeleton.
  const PrismSkeletonCard({
    super.key,
    this.mediaHeight = 160,
    this.lines = 3,
    this.padding = const EdgeInsets.all(16),
  });

  /// Height of the leading media area. Set to 0 to omit it.
  final double mediaHeight;

  /// Body lines under the media.
  final int lines;

  /// Padding inside the card.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    return Container(
      decoration: BoxDecoration(
        color: context.prismColors.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (mediaHeight > 0)
            PrismSkeleton(height: mediaHeight, borderRadius: BorderRadius.zero),
          Padding(
            padding: padding,
            child: PrismSkeletonText(lines: lines),
          ),
        ],
      ),
    );
  }
}

/// A vertical list of [count] skeletons — the standard "list is loading" state.
///
/// ```dart
/// PrismSkeletonList.tiles(count: 6)   // ListTile-shaped rows
/// PrismSkeletonList.cards(count: 3)   // Card-shaped rows
/// ```
class PrismSkeletonList extends StatelessWidget {
  /// Creates a list of card-shaped skeletons.
  const PrismSkeletonList.cards({
    super.key,
    this.count = 3,
    this.mediaHeight = 160,
    this.spacing = 16,
    this.padding = const EdgeInsets.all(16),
  }) : kind = PrismSkeletonListKind.card,
       itemHeight = null;

  /// Creates a list of tile-shaped skeletons (avatar + two lines).
  const PrismSkeletonList.tiles({
    super.key,
    this.count = 6,
    this.itemHeight = 72,
    this.spacing = 8,
    this.padding = const EdgeInsets.all(16),
  }) : kind = PrismSkeletonListKind.tile,
       mediaHeight = 0;

  /// How many items to render.
  final int count;

  /// Gap between items.
  final double spacing;

  /// Outer padding.
  final EdgeInsetsGeometry padding;

  /// Card media height (cards variant only).
  final double mediaHeight;

  /// Fixed row height (tiles variant only).
  final double? itemHeight;

  /// Which layout to draw.
  final PrismSkeletonListKind kind;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) SizedBox(height: spacing),
            switch (kind) {
              PrismSkeletonListKind.card => PrismSkeletonCard(
                mediaHeight: mediaHeight,
              ),
              PrismSkeletonListKind.tile => _TileSkeleton(height: itemHeight!),
            },
          ],
        ],
      ),
    );
  }
}

/// Which skeleton layout [PrismSkeletonList] renders.
enum PrismSkeletonListKind {
  /// Card-shaped rows with a media area.
  card,

  /// ListTile-shaped rows with an avatar.
  tile,
}

class _TileSkeleton extends StatelessWidget {
  const _TileSkeleton({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    return Container(
      height: height,
      padding: EdgeInsets.symmetric(horizontal: tokens.spaceMd),
      decoration: BoxDecoration(
        color: context.prismColors.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Row(
        children: [
          const PrismSkeleton.circle(diameter: 40),
          SizedBox(width: tokens.spaceMd),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PrismSkeleton(height: 12, width: 160),
                SizedBox(height: tokens.spaceSm),
                const PrismSkeleton(height: 10, width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
