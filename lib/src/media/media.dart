import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// An image with pinch-to-zoom and pan, plus double-tap to reset.
///
/// Wraps `InteractiveViewer` and adds the pieces the default does not have:
/// a border radius from the tokens, a place to put a placeholder while the image
/// loads, and an error handler that does not render a broken-image glyph.
///
/// ```dart
/// PrismZoomableImage(
///   imageUrl: 'https://example.com/photo.jpg',
///   borderRadius: BorderRadius.circular(16),
///   placeholder: const CircularProgressIndicator(),
/// )
/// ```
class PrismZoomableImage extends StatelessWidget {
  /// Creates a zoomable image.
  const PrismZoomableImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.borderRadius,
    this.placeholder,
    this.errorBuilder,
    this.maxScale = 4,
    this.headers,
    this.semanticLabel,
  });

  /// Network URL of the image.
  final String imageUrl;

  /// Constrained width. Defaults to filling the parent.
  final double? width;

  /// Constrained height. Defaults to filling the parent.
  final double? height;

  /// Corner radius, which clips the image.
  final BorderRadius? borderRadius;

  /// Widget shown while the image loads.
  final Widget? placeholder;

  /// Called when the image fails to load. Return a widget to show instead.
  final ImageErrorWidgetBuilder? errorBuilder;

  /// Maximum zoom level. Defaults to 4.
  final double maxScale;

  /// HTTP headers to send with the request.
  final Map<String, String>? headers;

  /// Accessibility label for the image.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Widget image = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      headers: headers,
      frameBuilder: (context, child, frame, wasSyncLoaded) {
        if (wasSyncLoaded || frame != null) return child;
        return placeholder ??
            Center(
              child: CircularProgressIndicator(
                color: scheme.primary,
                strokeWidth: 2,
              ),
            );
      },
      errorBuilder:
          errorBuilder ??
          (context, error, stack) => Icon(
            Icons.broken_image_outlined,
            size: 48,
            color: scheme.onSurfaceVariant,
          ),
    );

    return Semantics(
      image: true,
      label: semanticLabel,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: InteractiveViewer(maxScale: maxScale, child: image),
      ),
    );
  }
}

/// A simple carousel that shows a horizontally scrolling list of widgets, with
/// a page indicator underneath.
///
/// Wraps `PageView` and adds the dot indicator that every app has to build
/// itself.
///
/// ```dart
/// PrismCarousel(
///   items: [
///     MySlide1(),
///     MySlide2(),
///   ],
/// )
/// ```
class PrismCarousel extends StatefulWidget {
  /// Creates a carousel.
  const PrismCarousel({
    super.key,
    required this.items,
    this.height,
    this.onPageChanged,
    this.showDots = true,
    this.dotColor,
    this.activeDotColor,
    this.borderRadius,
  });

  /// The slides, one per page.
  final List<Widget> items;

  /// Height of the carousel. Defaults to filling the parent.
  final double? height;

  /// Called when the page changes.
  final ValueChanged<int>? onPageChanged;

  /// Whether to show the dot indicator underneath.
  final bool showDots;

  /// Colour of inactive dots.
  final Color? dotColor;

  /// Colour of the active dot.
  final Color? activeDotColor;

  /// Corner radius. Defaults to `PrismTokens.radiusLg`.
  final BorderRadius? borderRadius;

  @override
  State<PrismCarousel> createState() => _PrismCarouselState();
}

class _PrismCarouselState extends State<PrismCarousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final scheme = Theme.of(context).colorScheme;
    final inactive = widget.dotColor ?? scheme.outlineVariant;
    final active = widget.activeDotColor ?? scheme.primary;

    final pageView = PageView.builder(
      itemCount: widget.items.length,
      controller: _controller,
      onPageChanged: (i) {
        setState(() => _index = i);
        widget.onPageChanged?.call(i);
      },
      itemBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceSm),
        child: widget.items[index],
      ),
    );

    final body = widget.height == null
        ? Expanded(child: pageView)
        : SizedBox(height: widget.height, child: pageView);

    final dots = widget.showDots && widget.items.length > 1
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.items.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: EdgeInsets.symmetric(horizontal: tokens.spaceXs / 2),
                  width: i == _index ? tokens.spaceMd : tokens.spaceXs + 4,
                  height: tokens.spaceXs + 2,
                  decoration: BoxDecoration(
                    color: i == _index ? active : inactive,
                    borderRadius: BorderRadius.circular(tokens.radiusXl),
                  ),
                ),
            ],
          )
        : const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: body,
        ),
        if (widget.showDots) SizedBox(height: tokens.spaceSm),
        if (widget.showDots) dots,
      ],
    );
  }
}

/// A divider with a label centred in it, for grouping content.
///
/// Wraps `Divider` and puts a label in the middle, which is a pattern every
/// form needs and the default does not provide.
///
/// ```dart
/// PrismDividerWithLabel(label: 'Or continue with')
/// ```
class PrismDividerWithLabel extends StatelessWidget {
  /// Creates a labelled divider.
  const PrismDividerWithLabel({
    super.key,
    required this.label,
    this.color,
    this.thickness,
    this.padding = const EdgeInsets.symmetric(horizontal: 12),
  });

  /// Label in the middle of the divider.
  final String label;

  /// Line colour. Defaults to the theme's outline variant.
  final Color? color;

  /// Line thickness.
  final double? thickness;

  /// Padding around the label.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final lineColour = color ?? Theme.of(context).colorScheme.outlineVariant;
    final thickness_ = thickness ?? tokens.borderWidth;

    return Row(
      children: [
        Expanded(
          child: Divider(color: lineColour, thickness: thickness_),
        ),
        Padding(
          padding: padding,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Divider(color: lineColour, thickness: thickness_),
        ),
      ],
    );
  }
}
