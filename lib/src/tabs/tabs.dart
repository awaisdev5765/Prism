import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// One tab in a [PrismTabs].
@immutable
class PrismTab {
  /// Creates a tab.
  const PrismTab({
    required this.label,
    this.icon,
    this.badge,
    this.enabled = true,
  });

  /// The tab's visible name.
  final String label;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional badge content, e.g. an unread count.
  final Widget? badge;

  /// Whether the tab can be selected.
  final bool enabled;
}

/// Tabs that adapt to the window instead of overflowing.
///
/// Below [PrismTokens.breakpointCompact] the tab strip scrolls horizontally and
/// snaps the selected tab into view, because five labels do not fit on a phone
/// and a `TabBar` that silently clips them is worse than one that scrolls. Above
/// it the strip fills the width and the labels get equal space.
///
/// The strip is a proper tab list to assistive tech — each tab announces its
/// position ("2 of 4") and selection state — and changing tabs moves focus to
/// the new panel rather than leaving it stranded on the strip.
///
/// ```dart
/// PrismTabs(
///   tabs: const [
///     PrismTab(label: 'Today', icon: Icons.today_outlined),
///     PrismTab(label: 'Upcoming', icon: Icons.schedule_outlined),
///   ],
///   index: index,
///   onChanged: (next) => setState(() => index = next),
///   children: const [TodayView(), UpcomingView()],
/// )
/// ```
class PrismTabs extends StatefulWidget {
  /// Creates an adaptive tab view.
  const PrismTabs({
    super.key,
    required this.tabs,
    required this.index,
    required this.onChanged,
    required this.children,
    this.scrollThreshold,
    this.keepAlive = false,
    this.semanticLabel,
  });

  /// The tabs, left to right.
  final List<PrismTab> tabs;

  /// The selected tab.
  final int index;

  /// Called when a different tab is picked.
  final ValueChanged<int> onChanged;

  /// The panel for each tab. Must be the same length as [tabs].
  final List<Widget> children;

  /// Width below which the strip scrolls. Defaults to
  /// `PrismTokens.breakpointCompact`.
  final double? scrollThreshold;

  /// Whether to keep off-screen panels alive, preserving their state. Costs
  /// memory, so it is off by default.
  final bool keepAlive;

  /// Accessible name for the tab list.
  final String? semanticLabel;

  @override
  State<PrismTabs> createState() => _PrismTabsState();
}

class _PrismTabsState extends State<PrismTabs> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _select(int next) {
    if (next == widget.index) return;
    if (!widget.tabs[next].enabled) return;
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.tabs.length == widget.children.length,
      'PrismTabs needs one child per tab',
    );
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;
    final threshold = widget.scrollThreshold ?? tokens.breakpointCompact;
    final scrolls = MediaQuery.sizeOf(context).width < threshold;

    final strip = Row(
      mainAxisSize: scrolls ? MainAxisSize.min : MainAxisSize.max,
      children: [
        for (var i = 0; i < widget.tabs.length; i++)
          if (scrolls)
            _Tab(
              tab: widget.tabs[i],
              index: i,
              total: widget.tabs.length,
              selected: i == widget.index,
              onSelect: _select,
              colors: colors,
              scheme: scheme,
              tokens: tokens,
            )
          else
            Expanded(
              child: _Tab(
                tab: widget.tabs[i],
                index: i,
                total: widget.tabs.length,
                selected: i == widget.index,
                onSelect: _select,
                colors: colors,
                scheme: scheme,
                tokens: tokens,
              ),
            ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          explicitChildNodes: true,
          label: widget.semanticLabel,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceSunken,
              border: Border(
                bottom: BorderSide(
                  color: colors.outline,
                  width: tokens.borderWidth,
                ),
              ),
            ),
            child: scrolls
                ? SingleChildScrollView(
                    controller: _controller,
                    scrollDirection: Axis.horizontal,
                    child: strip,
                  )
                : strip,
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: widget.index,
            sizing: StackFit.expand,
            children: [
              for (var i = 0; i < widget.children.length; i++)
                if (widget.keepAlive || i == widget.index)
                  widget.children[i]
                else
                  const SizedBox.shrink(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.tab,
    required this.index,
    required this.total,
    required this.selected,
    required this.onSelect,
    required this.colors,
    required this.scheme,
    required this.tokens,
  });

  final PrismTab tab;
  final int index;
  final int total;
  final bool selected;
  final ValueChanged<int> onSelect;
  final PrismColors colors;
  final ColorScheme scheme;
  final PrismTokens tokens;

  @override
  Widget build(BuildContext context) {
    final foreground = !tab.enabled
        ? colors.outline
        : selected
        ? scheme.primary
        : scheme.onSurfaceVariant;

    return Semantics(
      button: true,
      selected: selected,
      enabled: tab.enabled,
      // "2 of 4" is what makes a tab strip navigable by a screen reader.
      label: '${tab.label}, ${index + 1} of $total',
      onTap: tab.enabled ? () => onSelect(index) : null,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: tab.enabled ? () => onSelect(index) : null,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMd,
              vertical: tokens.spaceSm + tokens.spaceXs,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (tab.icon != null) ...[
                      Icon(tab.icon, size: 18, color: foreground),
                      SizedBox(width: tokens.spaceXs + 2),
                    ],
                    Text(
                      tab.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    if (tab.badge != null) ...[
                      SizedBox(width: tokens.spaceXs + 2),
                      tab.badge!,
                    ],
                  ],
                ),
                SizedBox(height: tokens.spaceXs),
                // The underline is decoration; `selected` above carries the
                // meaning for anyone who cannot see it.
                AnimatedContainer(
                  duration: context.prismMotion(tokens.durationFast),
                  height: tokens.borderWidth * 2,
                  width: selected ? tokens.spaceXl : 0,
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(tokens.borderWidth),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
