import 'dart:async';

import 'package:flutter/foundation.dart';

/// A sealed view-state that drives [PrismStateView] rendering.
///
/// Dart 3 exhaustive switching means the compiler forces you to handle every
/// state — no more forgotten error branches:
///
/// ```dart
/// final state = switch (fetch()) {
///   PrismViewLoading() => const CircularProgressIndicator(),
///   PrismViewError(:final error) => Text('Failed: $error'),
///   PrismViewEmpty() => const Text('Nothing here yet'),
///   PrismViewSuccess(:final data) => Text(data),
/// };
/// ```
sealed class PrismViewState<T> {
  /// Creates a view state.
  const PrismViewState();

  /// Something is in progress.
  const factory PrismViewState.loading({String? message}) = PrismViewLoading<T>;

  /// Something went wrong. Carries the [error] and optional [stackTrace].
  const factory PrismViewState.error([Object? error, StackTrace? stackTrace]) =
      PrismViewError<T>;

  /// The operation succeeded but produced no data (e.g. an empty list).
  const factory PrismViewState.empty() = PrismViewEmpty<T>;

  /// The operation succeeded and produced [data].
  const factory PrismViewState.success(T data) = PrismViewSuccess<T>;
}

/// In-progress state.
class PrismViewLoading<T> extends PrismViewState<T> {
  /// Creates a loading state with an optional [message].
  const PrismViewLoading({this.message});

  /// Optional human-readable progress message.
  final String? message;
}

/// Failure state.
class PrismViewError<T> extends PrismViewState<T> {
  /// Creates an error state.
  const PrismViewError([this.error, this.stackTrace]);

  /// The thrown error, if any.
  final Object? error;

  /// The stack trace, if captured.
  final StackTrace? stackTrace;
}

/// Success-with-no-data state.
class PrismViewEmpty<T> extends PrismViewState<T> {
  /// Creates an empty state.
  const PrismViewEmpty();
}

/// Success state carrying [data].
class PrismViewSuccess<T> extends PrismViewState<T> {
  /// Creates a success state.
  const PrismViewSuccess(this.data);

  /// The produced data.
  final T data;
}

/// Converts a [Future] into a [ValueNotifier] of [PrismViewState]s, for apps
/// not using a state-management package.
///
/// ```dart
/// final state = PrismViewStateNotifier.fromFuture(loadItems());
/// ```
class PrismViewStateNotifier<T> extends ValueNotifier<PrismViewState<T>> {
  /// Creates a notifier starting in the loading state and tracking [future].
  PrismViewStateNotifier.fromFuture(Future<T> future)
    : super(const PrismViewLoading()) {
    future.then(
      (data) {
        final isEmpty = data is Iterable && data.isEmpty;
        value = isEmpty ? const PrismViewEmpty() : PrismViewSuccess(data);
      },
      onError: (Object error, StackTrace stackTrace) {
        value = PrismViewError(error, stackTrace);
      },
    );
  }
}
