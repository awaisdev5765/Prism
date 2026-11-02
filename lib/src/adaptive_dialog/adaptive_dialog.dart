import 'package:flutter/material.dart';

import '../adaptive_scaffold/adaptive_scaffold.dart';

import '../theme/theme.dart';

/// How a dialog should be presented on a given window class.
enum PresentationStyle {
  /// Always present as a centered modal dialog.
  dialog,

  /// Always present as a modal bottom sheet.
  bottomSheet,

  /// Adaptive: bottom sheet on compact windows, centered dialog on
  /// medium and larger windows. This is the recommended default.
  adaptive,
}

/// Shows adaptive dialogs: a modal bottom sheet on phones, a centered dialog
/// on tablets and desktops — from a single call.
///
/// ```dart
/// await PrismAdaptiveDialog.show<bool>(
///   context,
///   title: 'Delete item?',
///   builder: (context) => const Text('This cannot be undone.'),
///   actions: [
///     AdaptiveDialogAction.cancel(context),
///     AdaptiveDialogAction.destructive(
///       label: 'Delete',
///       onPressed: () => Navigator.pop(context, true),
///     ),
///   ],
/// );
/// ```
///
/// Pure Flutter — no platform channels — so it works on Android, iOS, macOS,
/// Windows, Linux, and web.
class PrismAdaptiveDialog {
  PrismAdaptiveDialog._();

  /// Shows an adaptive dialog and resolves with the value the content popped
  /// with, or null if it was dismissed.
  ///
  /// [presentation] controls when a bottom sheet is used instead of a
  /// centered dialog (see [PresentationStyle.adaptive] for the default
  /// behavior). All remaining parameters map to the underlying
  /// [showDialog] / [showModalBottomSheet] calls.
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? title,
    List<Widget> actions = const [],
    PresentationStyle presentation = PresentationStyle.adaptive,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = true,
    RouteSettings? routeSettings,
    ShapeBorder? shape,
    double? maxWidth,
    bool useRootNavigator = true,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final breakpoint = PrismBreakpoint.resolve(width);
    final asBottomSheet = switch (presentation) {
      PresentationStyle.dialog => false,
      PresentationStyle.bottomSheet => true,
      PresentationStyle.adaptive => breakpoint == PrismBreakpoint.compact,
    };

    final theme = Theme.of(context);
    final resolvedBarrierColor =
        barrierColor ?? theme.colorScheme.scrim.withValues(alpha: 0.4);

    Widget content(BuildContext innerContext) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: EdgeInsets.only(
              bottom: context.prismTokens.spaceSm + context.prismTokens.spaceXs,
            ),
            child: Text(title, style: theme.textTheme.titleLarge),
          ),
        Flexible(child: builder(innerContext)),
        if (actions.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: context.prismTokens.spaceMd),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                for (final action in actions)
                  Padding(
                    padding: EdgeInsets.only(left: context.prismTokens.spaceSm),
                    child: action,
                  ),
              ],
            ),
          ),
      ],
    );

    if (asBottomSheet) {
      return showModalBottomSheet<T>(
        context: context,
        isDismissible: barrierDismissible,
        barrierColor: resolvedBarrierColor,
        useSafeArea: useSafeArea,
        routeSettings: routeSettings,
        useRootNavigator: useRootNavigator,
        isScrollControlled: true,
        shape:
            shape ??
            const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
        builder: (innerContext) => Padding(
          padding: EdgeInsets.fromLTRB(
            context.prismTokens.spaceLg - context.prismTokens.spaceXs,
            context.prismTokens.spaceLg - context.prismTokens.spaceXs,
            context.prismTokens.spaceLg - context.prismTokens.spaceXs,
            context.prismTokens.spaceLg,
          ),
          child: content(innerContext),
        ),
      );
    }

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: resolvedBarrierColor,
      useSafeArea: useSafeArea,
      routeSettings: routeSettings,
      useRootNavigator: useRootNavigator,
      builder: (innerContext) => Dialog(
        shape:
            shape ??
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(context.prismTokens.radiusLg),
            ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth ?? 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: content(innerContext),
          ),
        ),
      ),
    );
  }
}

/// Pre-styled action buttons for [PrismAdaptiveDialog.show].
class AdaptiveDialogAction {
  AdaptiveDialogAction._();

  /// A neutral action (e.g. "Cancel"). Pops with [result].
  static Widget cancel(
    BuildContext context, {
    Object? result,
    String label = 'Cancel',
  }) => TextButton(
    onPressed: () => Navigator.pop(context, result),
    child: Text(label),
  );

  /// A primary action (e.g. "OK", "Confirm").
  static Widget primary(
    BuildContext context, {
    required String label,
    Object? result,
    VoidCallback? onPressed,
  }) => FilledButton(
    onPressed: onPressed ?? () => Navigator.pop(context, result),
    child: Text(label),
  );

  /// A destructive action (e.g. "Delete") styled with the error color.
  static Widget destructive(
    BuildContext context, {
    required String label,
    Object? result,
    VoidCallback? onPressed,
  }) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.error,
      foregroundColor: Theme.of(context).colorScheme.onError,
    ),
    onPressed: onPressed ?? () => Navigator.pop(context, result),
    child: Text(label),
  );
}
