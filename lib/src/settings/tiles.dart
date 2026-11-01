import 'package:flutter/material.dart';

import 'controller.dart';

/// Scope exposing the active [PrismSettingsController] to tiles.
class PrismSettingsScope extends InheritedNotifier<PrismSettingsController> {
  /// Creates a scope.
  const PrismSettingsScope({
    super.key,
    required PrismSettingsController super.notifier,
    required super.child,
  });

  /// Nearest controller; asserts when no [PrismSettingsPage] is above.
  static PrismSettingsController of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<PrismSettingsScope>();
    assert(scope != null, 'Settings tiles must be inside a PrismSettingsPage.');
    return scope!.notifier!;
  }
}

/// Shared tile configuration.
@immutable
class PrismTileCommon {
  /// Creates shared tile configuration.
  const PrismTileCommon({
    required this.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.enabled = true,
  });

  /// Value key inside the controller.
  final String key;

  /// Primary title.
  final String title;

  /// Secondary description under the title.
  final String? subtitle;

  /// Leading icon.
  final IconData? leading;

  /// Whether the tile accepts interaction.
  final bool enabled;
}

/// A titled group of tiles with rounded card styling.
class PrismSettingsSection extends StatelessWidget {
  /// Creates a section.
  const PrismSettingsSection({
    super.key,
    this.title,
    required this.tiles,
    this.maxWidth = 720,
  });

  /// Optional section header.
  final String? title;

  /// The tiles in this group.
  final List<Widget> tiles;

  /// Maximum width on wide windows; content centers beyond it.
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                child: Text(
                  title!,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              elevation: 0,
              color: theme.colorScheme.surfaceContainerLow,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < tiles.length; i++) ...[
                    tiles[i],
                    if (i < tiles.length - 1)
                      const Divider(height: 1, indent: 16, endIndent: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tile that navigates or performs an action on tap.
class PrismActionTile extends StatelessWidget {
  /// Creates an action tile.
  const PrismActionTile({
    super.key,
    required this.common,
    this.onTap,
    this.trailing,
  });

  /// Shared configuration.
  final PrismTileCommon common;

  /// Invoked when tapped.
  final VoidCallback? onTap;

  /// Trailing widget; defaults to a chevron.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: common.leading == null ? null : Icon(common.leading),
      title: Text(common.title),
      subtitle: common.subtitle == null ? null : Text(common.subtitle!),
      enabled: common.enabled,
      trailing: trailing ?? const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// Switch tile bound to the controller by [PrismTileCommon.key].
class PrismSwitchTile extends StatelessWidget {
  /// Creates a switch tile.
  const PrismSwitchTile({super.key, required this.common});

  /// Shared configuration.
  final PrismTileCommon common;

  @override
  Widget build(BuildContext context) {
    final controller = PrismSettingsScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final value = controller.get<bool>(common.key, false);
        return SwitchListTile(
          secondary: common.leading == null ? null : Icon(common.leading),
          title: Text(common.title),
          subtitle: common.subtitle == null ? null : Text(common.subtitle!),
          value: value,
          onChanged: common.enabled
              ? (v) => controller.set(common.key, v)
              : null,
        );
      },
    );
  }
}

/// Checkbox tile variant.
class PrismCheckboxTile extends StatelessWidget {
  /// Creates a checkbox tile.
  const PrismCheckboxTile({super.key, required this.common});

  /// Shared configuration.
  final PrismTileCommon common;

  @override
  Widget build(BuildContext context) {
    final controller = PrismSettingsScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final value = controller.get<bool>(common.key, false);
        return CheckboxListTile(
          secondary: common.leading == null ? null : Icon(common.leading),
          title: Text(common.title),
          subtitle: common.subtitle == null ? null : Text(common.subtitle!),
          value: value,
          onChanged: common.enabled
              ? (v) => controller.set(common.key, v ?? false)
              : null,
        );
      },
    );
  }
}

/// Slider tile for numeric values in [min, max].
class PrismSliderTile extends StatelessWidget {
  /// Creates a slider tile.
  const PrismSliderTile({
    super.key,
    required this.common,
    required this.min,
    required this.max,
    this.divisions,
    this.valueLabel,
  });

  /// Shared configuration.
  final PrismTileCommon common;

  /// Minimum value.
  final double min;

  /// Maximum value.
  final double max;

  /// Optional snap divisions.
  final int? divisions;

  /// Formats the current value shown in the subtitle.
  final String Function(double value)? valueLabel;

  @override
  Widget build(BuildContext context) {
    final controller = PrismSettingsScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final value = controller.get<double>(common.key, min);
        return ListTile(
          leading: common.leading == null ? null : Icon(common.leading),
          title: Text(common.title),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (common.subtitle != null) Text(common.subtitle!),
              Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                divisions: divisions,
                label: valueLabel?.call(value) ?? value.toStringAsFixed(1),
                onChanged: common.enabled
                    ? (v) => controller.set(common.key, v)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Dropdown selection tile.
class PrismDropdownTile<T> extends StatelessWidget {
  /// Creates a dropdown tile.
  const PrismDropdownTile({
    super.key,
    required this.common,
    required this.items,
    required this.itemLabel,
  });

  /// Shared configuration.
  final PrismTileCommon common;

  /// Selectable options.
  final List<T> items;

  /// Display label for an option.
  final String Function(T item) itemLabel;

  @override
  Widget build(BuildContext context) {
    final controller = PrismSettingsScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final value = controller.get<T?>(common.key, null);
        final buttonKey = GlobalKey();
        return ListTile(
          leading: common.leading == null ? null : Icon(common.leading),
          title: Text(common.title),
          subtitle: common.subtitle == null ? null : Text(common.subtitle!),
          // The whole tile opens the menu — not just a cramped trailing
          // button.
          trailing: Text(
            key: buttonKey,
            value == null ? '—' : itemLabel(value),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          onTap: common.enabled
              ? () => _openMenu(context, controller, buttonKey)
              : null,
        );
      },
    );
  }

  Future<void> _openMenu(
    BuildContext context,
    PrismSettingsController controller,
    GlobalKey buttonKey,
  ) async {
    final box = buttonKey.currentContext?.findRenderObject();
    if (box is! RenderBox) return;
    final overlay =
        Overlay.of(context, rootOverlay: true).context.findRenderObject()
            as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero, ancestor: overlay),
        box.localToGlobal(box.size.bottomLeft(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );
    final theme = Theme.of(context);
    final selected = await showMenu<T>(
      context: context,
      position: position,
      constraints: const BoxConstraints(minWidth: 180),
      color: theme.colorScheme.surfaceContainerHighest,
      items: [
        for (final item in items)
          PopupMenuItem<T>(
            value: item,
            child: Row(
              children: [
                if (controller.get<T?>(common.key, null) == item)
                  Icon(Icons.check, size: 18, color: theme.colorScheme.primary)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(itemLabel(item)),
              ],
            ),
          ),
      ],
    );
    if (selected != null) {
      controller.set(common.key, selected);
    }
  }
}
