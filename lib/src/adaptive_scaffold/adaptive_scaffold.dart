import 'package:flutter/material.dart';

import '../theme/theme.dart';
import 'breakpoint.dart';

export 'breakpoint.dart';

/// A responsive scaffold that adapts its navigation to the window class.
///
/// - **Compact** (< 600px): bottom navigation bar.
/// - **Medium** (600–839px): navigation rail on the leading edge.
/// - **Expanded / ExtraLarge** (840px+): navigation rail with labels and a
///   wider menu, optionally an [endDrawer]-style secondary panel.
///
/// This is the maintained replacement for the discontinued
/// `flutter_adaptive_scaffold`.
///
/// ```dart
/// PrismAdaptiveScaffold(
///   destinations: [
///     AdaptiveDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
///     AdaptiveDestination(icon: Icons.search_outlined, selectedIcon: Icons.search, label: 'Search'),
///   ],
///   bodyBuilder: (index) => Center(child: Text('Page $index')),
/// )
/// ```
class PrismAdaptiveScaffold extends StatelessWidget {
  /// Creates an adaptive scaffold.
  const PrismAdaptiveScaffold({
    super.key,
    required this.destinations,
    required this.bodyBuilder,
    this.currentIndex = 0,
    this.onDestinationSelected,
    this.appBar,
    this.floatingActionButton,
    this.backgroundColor,
    this.railWidth,
    this.useExtendedRail = true,
    this.railLabelType,
    this.bottomNavLabelType,
    this.transitionDuration,
  });

  /// The list of navigation destinations.
  final List<AdaptiveDestination> destinations;

  /// Builds the body for the currently selected [currentIndex].
  final Widget Function(int index) bodyBuilder;

  /// The index of the currently selected destination.
  final int currentIndex;

  /// Called when the user selects a destination.
  final ValueChanged<int>? onDestinationSelected;

  /// Optional app bar.
  final PreferredSizeWidget? appBar;

  /// Optional floating action button.
  final Widget? floatingActionButton;

  /// Background color for the scaffold and navigation surfaces.
  final Color? backgroundColor;

  /// Width of the navigation rail on medium/expanded layouts.
  final double? railWidth;

  /// Whether the rail expands to show labels (expanded+ only).
  final bool useExtendedRail;

  /// Label behavior for the rail. Defaults based on window class.
  final NavigationRailLabelType? railLabelType;

  /// Label behavior for the bottom navigation bar.
  final NavigationDestinationLabelBehavior? bottomNavLabelType;

  /// Duration for animated transitions between body pages. Defaults to
  /// [PrismTokens.durationMedium].
  final Duration? transitionDuration;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final breakpoint = PrismBreakpoint.resolve(
      width,
      mediumWidth: context.prismTokens.breakpointCompact,
      expanded: context.prismTokens.breakpointExpanded,
    );

    final destinationsList = destinations
        .map(
          (d) => NavigationRailDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon ?? d.icon),
            label: Text(d.label),
          ),
        )
        .toList();

    switch (breakpoint) {
      case PrismBreakpoint.compact:
        return _buildCompact(context, destinationsList);
      case PrismBreakpoint.medium:
        return _buildMedium(context, destinationsList);
      case PrismBreakpoint.expanded:
      case PrismBreakpoint.extraLarge:
        return _buildExpanded(context, destinationsList);
    }
    // Unreachable — PrismBreakpoint.resolve covers every width. The
    // analyzer can't prove exhaustiveness because PrismBreakpoint is a
    // class rather than an enum, so a defensive return is required.
    return _buildCompact(context, destinationsList);
  }

  /// The resolved transition duration: the caller's value, or the token
  /// default.
  Duration _transition(BuildContext context) => context.prismMotion(
    transitionDuration ?? context.prismTokens.durationMedium,
  );

  Widget _buildCompact(
    BuildContext context,
    List<NavigationRailDestination> railDestinations,
  ) {
    final labelBehavior =
        bottomNavLabelType ?? NavigationDestinationLabelBehavior.alwaysShow;
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      body: _AnimatedBody(
        index: currentIndex,
        duration: _transition(context),
        builder: bodyBuilder,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        labelBehavior: labelBehavior,
        destinations: [
          for (final d in destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon ?? d.icon),
              label: d.label,
              tooltip: d.label,
            ),
        ],
      ),
    );
  }

  Widget _buildMedium(
    BuildContext context,
    List<NavigationRailDestination> railDestinations,
  ) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          _buildRail(context, railDestinations, extended: false),
          Expanded(
            child: _AnimatedBody(
              index: currentIndex,
              duration: _transition(context),
              builder: bodyBuilder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded(
    BuildContext context,
    List<NavigationRailDestination> railDestinations,
  ) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      floatingActionButton: floatingActionButton,
      body: Row(
        children: [
          _buildRail(context, railDestinations, extended: useExtendedRail),
          Expanded(
            child: _AnimatedBody(
              index: currentIndex,
              duration: _transition(context),
              builder: bodyBuilder,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRail(
    BuildContext context,
    List<NavigationRailDestination> railDestinations, {
    required bool extended,
  }) {
    Widget rail = LayoutBuilder(
      builder: (context, constraints) {
        // NavigationRail asserts extended and labelType are mutually
        // exclusive — extended rails show labels inline automatically.
        return NavigationRail(
          selectedIndex: currentIndex,
          onDestinationSelected: onDestinationSelected,
          extended:
              extended && railWidth == null && constraints.maxWidth >= 840,
          labelType: extended
              ? NavigationRailLabelType.none
              : (railLabelType ?? NavigationRailLabelType.selected),
          destinations: railDestinations,
        );
      },
    );
    if (railWidth != null) {
      rail = SizedBox(width: railWidth, child: rail);
    }
    return rail;
  }
}

/// A navigation destination for [PrismAdaptiveScaffold].
@immutable
class AdaptiveDestination {
  /// Creates a destination.
  const AdaptiveDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  /// The icon shown when unselected.
  final IconData icon;

  /// The label text.
  final String label;

  /// Optional distinct icon shown when selected. Falls back to [icon].
  final IconData? selectedIcon;
}

/// Cross-fades between body pages for a smooth destination switch.
class _AnimatedBody extends StatelessWidget {
  const _AnimatedBody({
    required this.index,
    required this.duration,
    required this.builder,
  });

  final int index;
  final Duration duration;
  final Widget Function(int index) builder;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      child: KeyedSubtree(key: ValueKey(index), child: builder(index)),
    );
  }
}
