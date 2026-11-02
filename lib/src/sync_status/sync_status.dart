import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// The state of a background synchronisation, as [PrismSyncStatus] needs it.
///
/// Prism deliberately does not depend on a sync package, so this is a plain
/// value type rather than an interface to implement. Adapting your engine is a
/// few lines, and because `flutter_local_first`'s `SyncState` is sealed the
/// compiler checks that your adapter handles every case:
///
/// ```dart
/// PrismSyncSnapshot snapshotOf(SyncState state) => switch (state) {
///   Idle() => const PrismSyncSnapshot.idle(),
///   Offline(:final pendingChanges) =>
///     PrismSyncSnapshot(phase: PrismSyncPhase.offline, pendingChanges: pendingChanges),
///   Stopped() => const PrismSyncSnapshot(phase: PrismSyncPhase.paused),
///   Failed(:final error) =>
///     PrismSyncSnapshot(phase: PrismSyncPhase.failed, error: error),
///   Syncing(:final phase, :final completed, :final total) => PrismSyncSnapshot(
///     phase: phase == SyncPhase.pulling
///         ? PrismSyncPhase.pulling
///         : PrismSyncPhase.pushing,
///     completed: completed,
///     total: total,
///   ),
/// };
/// ```
///
/// Any other engine — a queue, a REST client, a Firestore listener — maps onto
/// the same six phases just as easily.
enum PrismSyncPhase {
  /// Nothing to do; everything is up to date.
  idle,

  /// Uploading local changes.
  pushing,

  /// Downloading remote changes.
  pulling,

  /// Waiting for connectivity.
  offline,

  /// The last attempt failed.
  failed,

  /// Synchronisation is paused by the user.
  paused,
}

/// An immutable snapshot of a sync engine's state.
@immutable
class PrismSyncSnapshot {
  /// Creates a snapshot.
  const PrismSyncSnapshot({
    required this.phase,
    this.pendingChanges = 0,
    this.completed = 0,
    this.total,
    this.lastSyncedAt,
    this.error,
  });

  /// An idle snapshot, optionally dated.
  const PrismSyncSnapshot.idle({this.lastSyncedAt})
    : phase = PrismSyncPhase.idle,
      pendingChanges = 0,
      completed = 0,
      total = null,
      error = null;

  /// Which half of the cycle is running, or why it is not.
  final PrismSyncPhase phase;

  /// Local changes waiting to be uploaded.
  final int pendingChanges;

  /// Items handled so far in the current phase.
  final int completed;

  /// Items expected in the current phase, when known.
  final int? total;

  /// When the last fully successful sync finished.
  final DateTime? lastSyncedAt;

  /// The error from the last failure, if any.
  final Object? error;

  /// Progress in 0..1, or null when the total is unknown.
  double? get progress {
    final t = total;
    if (t == null || t == 0) return null;
    return (completed / t).clamp(0.0, 1.0);
  }

  /// Whether a sync is running.
  bool get isBusy =>
      phase == PrismSyncPhase.pushing || phase == PrismSyncPhase.pulling;

  /// Whether everything is up to date.
  bool get isSettled => phase == PrismSyncPhase.idle && pendingChanges == 0;

  /// Whether the engine is waiting for a connection.
  bool get isOffline => phase == PrismSyncPhase.offline;

  /// The semantic role this state should be painted with.
  PrismSemantic get semantic => switch (phase) {
    PrismSyncPhase.idle => PrismSemantic.success,
    PrismSyncPhase.pushing || PrismSyncPhase.pulling => PrismSemantic.info,
    PrismSyncPhase.offline || PrismSyncPhase.paused => PrismSemantic.warning,
    PrismSyncPhase.failed => PrismSemantic.error,
  };

  /// A short human-readable description.
  String get label => switch (phase) {
    PrismSyncPhase.idle =>
      pendingChanges == 0 ? 'Up to date' : '$pendingChanges waiting to sync',
    PrismSyncPhase.pushing => 'Uploading changes',
    PrismSyncPhase.pulling => 'Downloading changes',
    PrismSyncPhase.offline =>
      pendingChanges == 0 ? 'Offline' : 'Offline — $pendingChanges waiting',
    PrismSyncPhase.failed => 'Sync failed',
    PrismSyncPhase.paused => 'Sync paused',
  };

  /// The icon this state should be shown with.
  IconData get icon => switch (phase) {
    PrismSyncPhase.idle =>
      pendingChanges == 0
          ? Icons.cloud_done_outlined
          : Icons.cloud_upload_outlined,
    PrismSyncPhase.pushing => Icons.cloud_upload_outlined,
    PrismSyncPhase.pulling => Icons.cloud_download_outlined,
    PrismSyncPhase.offline => Icons.cloud_off_outlined,
    PrismSyncPhase.failed => Icons.cloud_off_outlined,
    PrismSyncPhase.paused => Icons.pause_circle_outline,
  };

  /// A copy with selected fields replaced.
  PrismSyncSnapshot copyWith({
    PrismSyncPhase? phase,
    int? pendingChanges,
    int? completed,
    int? total,
    DateTime? lastSyncedAt,
    Object? error,
  }) {
    return PrismSyncSnapshot(
      phase: phase ?? this.phase,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      completed: completed ?? this.completed,
      total: total ?? this.total,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      error: error ?? this.error,
    );
  }
}

/// A compact, always-on-screen indicator of sync state.
///
/// Pairs with any sync engine that can produce a [PrismSyncSnapshot]. With
/// `flutter_local_first` that is one `ValueListenableBuilder` and the adapter
/// shown on [PrismSyncPhase]:
///
/// ```dart
/// ValueListenableBuilder(
///   valueListenable: syncEngine.state,
///   builder: (context, state, _) =>
///       PrismSyncStatus(snapshot: snapshotOf(state)),
/// )
/// ```
///
/// It is a live region, so a screen reader hears a sync fail without the user
/// having to hunt for it, and it collapses to a single icon when idle so it does
/// not add noise to a toolbar.
class PrismSyncStatus extends StatelessWidget {
  /// Creates a sync status indicator.
  const PrismSyncStatus({
    super.key,
    required this.snapshot,
    this.showLabel = true,
    this.onRetry,
    this.retryLabel = 'Retry',
    this.compact = false,
  });

  /// The current state.
  final PrismSyncSnapshot snapshot;

  /// Whether to show the text label beside the icon. When false, the label is
  /// still announced to assistive tech.
  final bool showLabel;

  /// Called when retry is tapped. A retry action is only offered with a failure.
  final VoidCallback? onRetry;

  /// Label for the retry action.
  final String retryLabel;

  /// Renders an icon-only chip with a smaller footprint.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final role = colors.forRole(snapshot.semantic);
    final showRetry =
        onRetry != null && snapshot.phase == PrismSyncPhase.failed;

    final semanticsLabel = StringBuffer(snapshot.label);
    final error = snapshot.error;
    if (error != null) semanticsLabel.write(': $error');

    return Semantics(
      liveRegion: true,
      container: true,
      label: semanticsLabel.toString(),
      child: ExcludeSemantics(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.spaceSm,
            vertical: tokens.spaceXs + 1,
          ),
          decoration: BoxDecoration(
            color: role.background,
            borderRadius: BorderRadius.circular(tokens.radiusXl),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IndicatorIcon(snapshot: snapshot, color: role.foreground),
              if (showLabel && !compact) ...[
                SizedBox(width: tokens.spaceSm),
                Text(
                  snapshot.label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: role.foreground,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              if (showRetry) ...[
                SizedBox(width: tokens.spaceXs),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: role.foreground,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.symmetric(horizontal: tokens.spaceSm),
                    minimumSize: Size(0, tokens.spaceXl),
                  ),
                  child: Text(retryLabel),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _IndicatorIcon extends StatelessWidget {
  const _IndicatorIcon({required this.snapshot, required this.color});

  final PrismSyncSnapshot snapshot;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final icon = Icon(snapshot.icon, size: 16, color: color);
    if (!snapshot.isBusy) return icon;

    // A spinner communicates "still working" in a way a static cloud cannot.
    return SizedBox(
      width: 16,
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 2,
            color: color,
            value: snapshot.progress,
          ),
          icon,
        ],
      ),
    );
  }
}
