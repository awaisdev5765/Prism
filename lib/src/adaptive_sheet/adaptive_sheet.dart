import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Shows a surface that adapts to the window: a bottom sheet on compact
/// windows, a centred dialog on wide ones.
///
/// The same call site works everywhere. On a phone the user swipes it up from
/// the bottom; on a desktop window it becomes a polite dialog that does not
/// stretch across a 27-inch monitor.
///
/// ```dart
/// final confirmed = await PrismAdaptiveSheet.show<bool>(
///   context: context,
///   title: 'Delete note?',
///   child: const Text('This cannot be undone.'),
///   actions: [
///     PrismSheetAction(label: 'Cancel', value: false),
///     PrismSheetAction(label: 'Delete', value: true, isDestructive: true),
///   ],
/// );
/// ```
class PrismAdaptiveSheet {
  PrismAdaptiveSheet._();

  /// Shows the adapted surface and resolves with the value passed to
  /// [Navigator.pop] — either from an action, a drag-dismiss (null) or the
  /// barrier (null).
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    String? subtitle,
    List<PrismSheetAction<T>> actions = const [],
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool useSafeArea = true,
    double maxDialogWidth = 460,
    Widget? header,
    bool showDragHandle = true,
    Color? backgroundColor,
  }) {
    final tokens = PrismTokens.of(context);
    final wide = MediaQuery.sizeOf(context).width >= tokens.breakpointCompact;

    if (wide) {
      return showDialog<T>(
        context: context,
        barrierDismissible: isDismissible,
        builder: (dialogContext) => Dialog(
          backgroundColor: backgroundColor,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(tokens.radiusXl),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxDialogWidth),
            child: _SheetContent<T>(
              title: title,
              subtitle: subtitle,
              actions: actions,
              header: header,
              showDragHandle: false,
              child: child,
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      useSafeArea: useSafeArea,
      showDragHandle: showDragHandle,
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(tokens.radiusXl),
        ),
      ),
      builder: (sheetContext) => _SheetContent<T>(
        title: title,
        subtitle: subtitle,
        actions: actions,
        header: header,
        showDragHandle: false,
        child: child,
      ),
    );
  }
}

/// A labelled button at the bottom of a [PrismAdaptiveSheet].
@immutable
class PrismSheetAction<T> {
  /// Creates a sheet action.
  const PrismSheetAction({
    required this.label,
    this.value,
    this.onPressed,
    this.isDestructive = false,
    this.isPrimary = false,
    this.icon,
    this.closeOnTap = true,
  });

  /// Button label.
  final String label;

  /// Value resolved by the future when tapped.
  final T? value;

  /// Extra work to run before the sheet closes.
  final VoidCallback? onPressed;

  /// Renders in the error color — use for delete/removal.
  final bool isDestructive;

  /// Renders as a filled button instead of a text button.
  final bool isPrimary;

  /// Optional leading icon.
  final IconData? icon;

  /// Whether tapping closes the sheet. Set false for actions that validate.
  final bool closeOnTap;
}

class _SheetContent<T> extends StatelessWidget {
  const _SheetContent({
    required this.child,
    required this.actions,
    this.title,
    this.subtitle,
    this.header,
    this.showDragHandle = true,
  });

  final Widget child;
  final List<PrismSheetAction<T>> actions;
  final String? title;
  final String? subtitle;
  final Widget? header;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final media = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: media.size.height * 0.86,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ?header,
              if (title != null || subtitle != null)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spaceLg,
                    tokens.spaceLg,
                    tokens.spaceLg,
                    tokens.spaceSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (title != null)
                        Semantics(
                          header: true,
                          child: Text(
                            title!,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      if (subtitle != null) ...[
                        SizedBox(height: tokens.spaceXs),
                        Text(
                          subtitle!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: tokens.spaceLg),
                  child: child,
                ),
              ),
              if (actions.isNotEmpty)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.spaceLg,
                    tokens.spaceLg,
                    tokens.spaceLg,
                    tokens.spaceMd,
                  ),
                  child: Wrap(
                    alignment: WrapAlignment.end,
                    spacing: tokens.spaceSm,
                    runSpacing: tokens.spaceSm,
                    children: [
                      for (final action in actions)
                        _ActionButton<T>(
                          action: action,
                          destructiveColor: colors.error,
                        ),
                    ],
                  ),
                )
              else
                SizedBox(height: tokens.spaceMd),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton<T> extends StatelessWidget {
  const _ActionButton({required this.action, required this.destructiveColor});

  final PrismSheetAction<T> action;
  final Color destructiveColor;

  @override
  Widget build(BuildContext context) {
    final foreground = action.isDestructive ? destructiveColor : null;
    final icon = action.icon == null ? null : Icon(action.icon, size: 18);
    final label = Text(action.label);

    void handle() {
      action.onPressed?.call();
      if (action.closeOnTap) {
        Navigator.of(context).pop(action.value);
      }
    }

    if (action.isPrimary) {
      return FilledButton.icon(
        onPressed: handle,
        icon: icon,
        label: label,
        style: action.isDestructive
            ? FilledButton.styleFrom(backgroundColor: destructiveColor)
            : null,
      );
    }
    return TextButton.icon(
      onPressed: handle,
      icon: icon,
      label: label,
      style: foreground == null
          ? null
          : TextButton.styleFrom(foregroundColor: foreground),
    );
  }
}
