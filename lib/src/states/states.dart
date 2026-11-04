import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A full-screen or scoped overlay that blocks interaction while loading.
///
/// Wraps [child] with a translucent scrim, a spinner and an optional message,
/// and only renders when [isLoading] is true. Useful for a network call where
/// the user should not be able to tap anything while it is in flight.
///
/// ```dart
/// PrismLoadingOverlay(
///   isLoading: state.isSubmitting,
///   message: 'Saving…',
///   child: const MyForm(),
/// )
/// ```
class PrismLoadingOverlay extends StatelessWidget {
  /// Creates a loading overlay.
  const PrismLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
    this.color,
    this.backgroundColor,
    this.loadingIcon,
    this.borderRadius,
  });

  /// Whether the overlay is shown.
  final bool isLoading;

  /// The content underneath.
  final Widget child;

  /// Message shown under the spinner.
  final String? message;

  /// Spinner colour. Defaults to the theme's primary.
  final Color? color;

  /// Background of the scrim. Defaults to a translucent surface colour.
  final Color? backgroundColor;

  /// Replaces the spinner with a custom widget.
  final Widget? loadingIcon;

  /// Corner radius, when the overlay is scoped to a box.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final scrim = backgroundColor ?? scheme.surface.withValues(alpha: 0.75);

    final spinner =
        loadingIcon ?? const CircularProgressIndicator(strokeWidth: 2.5);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Semantics(
              liveRegion: true,
              container: true,
              label: message ?? 'Loading',
              child: ExcludeSemantics(
                child: ClipRRect(
                  borderRadius: borderRadius ?? BorderRadius.zero,
                  child: ColoredBox(
                    color: scrim,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          spinner,
                          if (message != null) ...[
                            const SizedBox(height: 14),
                            Text(
                              message!,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: scheme.onSurface),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A friendly empty state with an icon, a title, a subtitle and an action.
///
/// Every list screen needs one. Takes the ambiguity out of whether the list is
/// empty because there is nothing to show, or because it failed to load.
///
/// ```dart
/// PrismEmptyState(
///   icon: Icons.note_add_outlined,
///   title: 'No notes yet',
///   subtitle: 'Tap the + button to add your first note.',
///   actionLabel: 'Add a note',
///   onAction: createNote,
/// )
/// ```
class PrismEmptyState extends StatelessWidget {
  /// Creates an empty state.
  const PrismEmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    this.color,
    this.compact = false,
  });

  /// Icon above the title. Defaults to `Icons.inbox_outlined`.
  final IconData? icon;

  /// Primary message.
  final String title;

  /// Supporting message under the title.
  final String? subtitle;

  /// Label for the action button. Hidden when [onAction] is null.
  final String? actionLabel;

  /// Called when the action button is tapped.
  final VoidCallback? onAction;

  /// Tint for the icon.
  final Color? color;

  /// Whether to render a smaller version, for inline use.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final scheme = Theme.of(context).colorScheme;
    final tint = color ?? scheme.onSurfaceVariant;
    final iconSize = compact ? tokens.spaceXl : tokens.spaceXxl * 1.4;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon ?? Icons.inbox_outlined, size: iconSize, color: tint),
          SizedBox(height: tokens.spaceMd),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style:
              (compact
                      ? Theme.of(context).textTheme.bodyLarge
                      : Theme.of(context).textTheme.titleMedium)
                  ?.copyWith(fontWeight: FontWeight.w600),
        ),
        if (subtitle != null) ...[
          SizedBox(height: tokens.spaceXs),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          SizedBox(height: tokens.spaceLg),
          compact
              ? TextButton(onPressed: onAction, child: Text(actionLabel!))
              : FilledButton.tonal(
                  onPressed: onAction,
                  child: Text(actionLabel!),
                ),
        ],
      ],
    );

    if (compact) {
      return Padding(padding: EdgeInsets.all(tokens.spaceMd), child: content);
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceXl),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: tokens.contentMaxWidth * 0.6),
          child: content,
        ),
      ),
    );
  }
}
