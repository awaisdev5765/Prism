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

    final stateView = switch (state) {
      PrismViewLoading(:final message) => _Centered(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              errorIcon ?? Icons.error_outline,
              size: 48,
              color: resolved.errorColor,
            ),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? (error?.toString() ?? 'Something went wrong.'),
              style: resolved.messageStyle,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
      PrismViewEmpty() => _Centered(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              emptyIcon ?? Icons.inbox_outlined,
              size: 48,
              color: resolved.iconColor,
            ),
            const SizedBox(height: 12),
            Text(
              emptyMessage ?? 'Nothing here yet.',
              style: resolved.messageStyle,
              textAlign: TextAlign.center,
            ),
            if (emptyActionLabel != null && onEmptyAction != null) ...[
              const SizedBox(height: 16),
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
      duration: resolved.transitionDuration,
      child: KeyedSubtree(key: ValueKey(state.runtimeType), child: stateView),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    );
  }
}
