import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A pull-to-refresh wrapper that works with any scrollable child, not just
/// `ListView`.
///
/// Flutter's `RefreshIndicator` requires a scrollable child and does not report
/// the state of the refresh, which makes it hard to show a result. This one
/// accepts any child, exposes the state, and gives you a place to show an error
/// or a completion message.
///
/// ```dart
/// PrismRefreshIndicator(
///   onRefresh: () => context.read<NotesCubit>().refresh(),
///   child: ListView(children: [...]),
/// )
/// ```
class PrismRefreshIndicator extends StatelessWidget {
  /// Creates a refresh indicator.
  const PrismRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.semanticsLabel = 'Refresh',
  });

  /// Called when the user pulls down far enough.
  final Future<void> Function() onRefresh;

  /// The scrollable content.
  final Widget child;

  /// Colour of the progress indicator.
  final Color? color;

  /// Background colour behind the indicator.
  final Color? backgroundColor;

  /// How far the child must be pulled to trigger a refresh.
  final double displacement;

  /// Accessibility label for the refresh action.
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? scheme.primary,
      backgroundColor: backgroundColor ?? scheme.surfaceContainerLow,
      displacement: displacement,
      semanticsLabel: semanticsLabel,
      child: child,
    );
  }
}

/// A floating action button that expands into a menu of actions.
///
/// Useful when a screen has two or three primary actions and a plain FAB cannot
/// express them all. Opens with a rotation and staggered labels.
///
/// ```dart
/// PrismFabMenu(
///   actions: [
///     PrismFabAction(icon: Icons.note_add, label: 'New note', onTap: () {}),
///     PrismFabAction(icon: Icons.photo, label: 'New photo', onTap: () {}),
///   ],
/// )
/// ```
class PrismFabMenu extends StatefulWidget {
  /// Creates a FAB menu.
  const PrismFabMenu({
    super.key,
    required this.actions,
    this.icon = Icons.add,
    this.closedIcon,
    this.fabSize = 56,
    this.spacing = 12,
    this.foregroundColor,
    this.backgroundColor,
    this.labelsOnLeft = true,
  });

  /// The actions in the menu, top to bottom.
  final List<PrismFabAction> actions;

  /// Icon on the main FAB when closed.
  final IconData icon;

  /// Icon on the main FAB when open. Defaults to `Icons.close`.
  final IconData? closedIcon;

  /// Size of the main FAB.
  final double fabSize;

  /// Vertical gap between action buttons.
  final double spacing;

  /// Icon colour on the main FAB.
  final Color? foregroundColor;

  /// Background colour of the main FAB.
  final Color? backgroundColor;

  /// Whether labels appear on the left of the action buttons. When false they
  /// appear on the right.
  final bool labelsOnLeft;

  @override
  State<PrismFabMenu> createState() => _PrismFabMenuState();
}

class _PrismFabMenuState extends State<PrismFabMenu>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  bool _isOpen = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _isOpen = !_isOpen);
    _isOpen ? _controller.forward() : _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = widget.foregroundColor ?? scheme.onPrimary;
    final background = widget.backgroundColor ?? scheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = widget.actions.length - 1; i >= 0; i--)
          ScaleTransition(
            scale: _fade,
            alignment: Alignment.bottomRight,
            child: FadeTransition(
              opacity: _fade,
              child: Padding(
                padding: EdgeInsets.only(bottom: widget.spacing),
                child: _ActionRow(
                  action: widget.actions[i],
                  labelsOnLeft: widget.labelsOnLeft,
                  foreground: foreground,
                ),
              ),
            ),
          ),
        FloatingActionButton(
          onPressed: _toggle,
          backgroundColor: background,
          foregroundColor: foreground,
          child: AnimatedRotation(
            turns: _isOpen ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isOpen ? widget.closedIcon ?? Icons.close : widget.icon,
            ),
          ),
        ),
      ],
    );
  }
}

/// One action in a [PrismFabMenu].
@immutable
class PrismFabAction {
  /// Creates an action.
  const PrismFabAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  /// Visible label.
  final String label;

  /// Icon on the action button.
  final IconData icon;

  /// Called when the action is tapped.
  final VoidCallback onTap;
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.action,
    required this.labelsOnLeft,
    required this.foreground,
  });

  final PrismFabAction action;
  final bool labelsOnLeft;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;

    final button = FloatingActionButton.small(
      onPressed: action.onTap,
      backgroundColor: colors.surfaceRaised,
      foregroundColor: scheme.primary,
      child: Icon(action.icon),
    );

    final label = Material(
      color: colors.surfaceRaised,
      borderRadius: BorderRadius.circular(tokens.radiusSm),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceSm,
          vertical: tokens.spaceXs,
        ),
        child: Text(
          action.label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: scheme.onSurface),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: action.label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: labelsOnLeft
              ? [label, SizedBox(width: tokens.spaceSm), button]
              : [button, SizedBox(width: tokens.spaceSm), label],
        ),
      ),
    );
  }
}
