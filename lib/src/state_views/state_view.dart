import 'package:flutter/material.dart';

import 'state.dart';
import 'style.dart';

/// Renders one widget for all four async UI states: loading, error, empty,
/// and success — with built-in retry and smart defaults.
///
/// ```dart
/// PrismStateView<String>(
///   state: viewState, // a PrismViewState<String>
///   emptyMessage: 'No items yet',
///   onRetry: () => refetch(),
///   successBuilder: (data) => ListView(children: [
///     for (final item in data) ListTile(title: Text(item)),
///   ]),
/// )
/// ```
///
/// Because [PrismViewState] is sealed, Dart 3's exhaustiveness checking
/// guarantees the switch inside this widget covers every state — and your
/// code gets the same guarantee when you switch on it yourself.
///
/// Pure Flutter — no platform channels — works on Android, iOS, macOS,
/// Windows, Linux, and web.
class PrismStateView<T> extends StatelessWidget {
  /// Creates a state-driven view.
  const PrismStateView({
    super.key,
    required this.state,
    required this.successBuilder,
    this.style,
    this.loadingMessage,
    this.errorMessage,
    this.emptyMessage,
    this.emptyActionLabel,
    this.onEmptyAction,
    this.onRetry,
    this.loadingIcon,
    this.errorIcon,
    this.emptyIcon,
  });

  /// The current view state.
  final PrismViewState<T> state;

  /// Builds the real UI when [PrismViewSuccess] holds data.
  final Widget Function(T data) successBuilder;

  /// Visual configuration.
  final PrismStateViewStyle? style;

  /// Overrides the default loading text.
  final String? loadingMessage;

  /// Overrides the default error text.
  final String? errorMessage;

  /// Overrides the default empty text.
  final String? emptyMessage;

  /// Label for the optional empty-state action button.
  final String? emptyActionLabel;

  /// Callback for the empty-state action button.
  final VoidCallback? onEmptyAction;

  /// Called when the user taps "Retry" on an error state.
  final VoidCallback? onRetry;

  /// Overrides the loading indicator icon.
  final IconData? loadingIcon;

  /// Overrides the error icon.
  final IconData? errorIcon;

  /// Overrides the empty-state icon.
  final IconData? emptyIcon;

  @override
  Widget build(BuildContext context) {
    final resolved = (style ?? const PrismStateViewStyle()).resolve(context);
    // resolve() fills every field, but the analyzer cannot see through the
    // optional types, so coalesce once here instead of at each use site.
    final iconSize = resolved.iconSize ?? 48;
    final gap = resolved.gap ?? 8;
    final padding = resolved.padding ?? const EdgeInsets.all(24);
    final transition =
        resolved.transitionDuration ?? const Duration(milliseconds: 250);

    final stateView = switch (state) {
      PrismViewLoading(:final message) => _Centered(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(color: resolved.accentColor),
            ),
            if ((loadingMessage ?? message) != null) ...[
              const SizedBox(height: 12),
              Text(
                loadingMessage ?? message!,
                style: resolved.messageStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
      PrismViewError(:final error) => _Centered(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              errorIcon ?? Icons.error_outline,
              size: iconSize,
              color: resolved.errorColor,
            ),
            SizedBox(height: gap),
            Text(
              errorMessage ?? (error?.toString() ?? 'Something went wrong.'),
              style: resolved.messageStyle,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: gap * 2),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(resolved.retryLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
      PrismViewEmpty() => _Centered(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              emptyIcon ?? Icons.inbox_outlined,
              size: iconSize,
              color: resolved.iconColor,
            ),
            SizedBox(height: gap),
            Text(
              emptyMessage ?? 'Nothing here yet.',
              style: resolved.messageStyle,
              textAlign: TextAlign.center,
            ),
            if (emptyActionLabel != null && onEmptyAction != null) ...[
              SizedBox(height: gap * 2),
              FilledButton.tonal(
                onPressed: onEmptyAction,
                child: Text(emptyActionLabel!),
              ),
            ],
          ],
        ),
      ),
      PrismViewSuccess(:final data) => successBuilder(data),
    };

    return AnimatedSwitcher(
      duration: transition,
      child: KeyedSubtree(key: ValueKey(state.runtimeType), child: stateView),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: padding, child: child),
    );
  }
}
