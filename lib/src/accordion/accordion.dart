import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// One collapsible section of a [PrismAccordion].
@immutable
class PrismAccordionSection {
  /// Creates a section.
  const PrismAccordionSection({
    required this.title,
    required this.child,
    this.subtitle,
    this.icon,
    this.initiallyExpanded = false,
    this.enabled = true,
  });

  /// Header text.
  final String title;

  /// Body revealed when expanded.
  final Widget child;

  /// Optional supporting line under the title.
  final String? subtitle;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether this section starts open.
  final bool initiallyExpanded;

  /// Whether this section can be opened.
  final bool enabled;
}

/// A stack of collapsible sections.
///
/// Two behaviours matter and are easy to get wrong: only one section may be open
/// at a time when [singleExpansion] is set (the settings-screen pattern), and
/// each header must announce whether it is expanded — otherwise a screen reader
/// user hears a list of mysterious buttons.
///
/// ```dart
/// PrismAccordion(
///   singleExpansion: true,
///   sections: const [
///     PrismAccordionSection(title: 'Delivery', child: Text('…')),
///     PrismAccordionSection(title: 'Returns', child: Text('…')),
///   ],
/// )
/// ```
class PrismAccordion extends StatefulWidget {
  /// Creates an accordion.
  const PrismAccordion({
    super.key,
    required this.sections,
    this.singleExpansion = false,
    this.expandedIndices,
    this.onExpansionChanged,
    this.divider = true,
  });

  /// The sections, top to bottom.
  final List<PrismAccordionSection> sections;

  /// Whether opening one section closes the others.
  final bool singleExpansion;

  /// Overrides the initial expansion state. When null, each section's own
  /// [PrismAccordionSection.initiallyExpanded] is used.
  final Set<int>? expandedIndices;

  /// Called with the new set of expanded indices.
  final void Function(Set<int> expanded)? onExpansionChanged;

  /// Whether to draw a hairline between sections.
  final bool divider;

  @override
  State<PrismAccordion> createState() => _PrismAccordionState();
}

class _PrismAccordionState extends State<PrismAccordion> {
  late Set<int> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded =
        widget.expandedIndices ??
        {
          for (var i = 0; i < widget.sections.length; i++)
            if (widget.sections[i].initiallyExpanded) i,
        };
  }

  @override
  void didUpdateWidget(PrismAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.expandedIndices != null &&
        widget.expandedIndices != oldWidget.expandedIndices) {
      _expanded = widget.expandedIndices!;
    }
  }

  void _toggle(int index) {
    if (!widget.sections[index].enabled) return;
    setState(() {
      if (_expanded.contains(index)) {
        _expanded.remove(index);
      } else {
        if (widget.singleExpansion) _expanded.clear();
        _expanded.add(index);
      }
    });
    widget.onExpansionChanged?.call(Set.unmodifiable(_expanded));
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: colors.outline, width: tokens.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < widget.sections.length; i++) ...[
            if (widget.divider && i > 0)
              Divider(height: 1, color: colors.outline),
            _Section(
              section: widget.sections[i],
              index: i,
              expanded: _expanded.contains(i),
              onToggle: () => _toggle(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.section,
    required this.index,
    required this.expanded,
    required this.onToggle,
  });

  final PrismAccordionSection section;
  final int index;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;
    final foreground = section.enabled ? scheme.onSurface : colors.outline;

    return Semantics(
      // `expanded` is what makes this discoverable: without it a screen reader
      // user cannot tell an open section from a closed one.
      expanded: expanded,
      button: true,
      enabled: section.enabled,
      label: section.subtitle == null
          ? section.title
          : '${section.title}. ${section.subtitle}',
      onTap: section.enabled ? onToggle : null,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: section.enabled ? onToggle : null,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.spaceMd,
                  vertical: tokens.spaceMd - tokens.spaceXs,
                ),
                child: Row(
                  children: [
                    if (section.icon != null) ...[
                      Icon(section.icon, size: 20, color: foreground),
                      SizedBox(width: tokens.spaceSm + tokens.spaceXs),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            section.title,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          if (section.subtitle != null) ...[
                            SizedBox(height: tokens.spaceXs / 2),
                            Text(
                              section.subtitle!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: tokens.spaceSm),
                    AnimatedRotation(
                      // Reduced motion: the glyph still changes, it just does
                      // not spin on the way.
                      turns: expanded ? 0.5 : 0,
                      duration: context.prismMotion(tokens.durationFast),
                      child: Icon(Icons.expand_more, color: foreground),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: context.prismMotion(tokens.durationMedium),
              curve: tokens.curveStandard,
              alignment: Alignment.topCenter,
              child: expanded
                  ? Padding(
                      padding: EdgeInsets.fromLTRB(
                        tokens.spaceMd,
                        0,
                        tokens.spaceMd,
                        tokens.spaceMd,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: section.child,
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
    );
  }
}
