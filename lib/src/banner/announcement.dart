import 'package:flutter/material.dart';

/// An in-app announcement shown by [PrismBanner].
///
/// A banner combines a message with display rules: when it may appear, for
/// whom, and how it is dismissed. Banners are identified by [id] — changing
/// the id (or bumping [version] on the same id) makes the banner show again
/// for users who already dismissed it.
///
/// ```dart
/// const PrismAnnouncement(
///   id: 'release-2-1',
///   message: 'New in 2.1: dark mode, faster sync, and keyboard shortcuts!',
///   severity: PrismSeverity.info,
/// )
/// ```
@immutable
class PrismAnnouncement {
  /// Creates an announcement.
  const PrismAnnouncement({
    required this.id,
    required this.message,
    this.version = 1,
    this.severity = PrismSeverity.info,
    this.actionLabel,
    this.onAction,
    this.startsAt,
    this.endsAt,
    this.title,
  });

  /// Stable identifier used for dismiss persistence. Reuse the id and bump
  /// [version] when you edit the copy so previously-dismissed users see the
  /// updated banner again.
  final String id;

  /// Main banner text. Keep it to one or two lines.
  final String message;

  /// Optional bold lead-in rendered above [message].
  final String? title;

  /// Bump when the copy changes under the same [id].
  final int version;

  /// Visual severity — drives the default color scheme.
  final PrismSeverity severity;

  /// Label for an optional action button (e.g. "What's new").
  final String? actionLabel;

  /// Invoked when the user taps the [actionLabel] button.
  final VoidCallback? onAction;

  /// Earliest time the banner may appear (defaults to immediately).
  final DateTime? startsAt;

  /// Latest time the banner may appear (defaults to no end).
  final DateTime? endsAt;

  /// Whether this announcement is currently within its schedule.
  bool isScheduledFor(DateTime now) {
    final start = startsAt;
    if (start != null && now.isBefore(start)) return false;
    final end = endsAt;
    if (end != null && now.isAfter(end)) return false;
    return true;
  }
}

/// Visual severity levels for [PrismAnnouncement].
enum PrismSeverity {
  /// Neutral informational banner (theme primary container).
  info,

  /// Positive announcement (theme tertiary container).
  success,

  /// Caution — maintenance windows, deprecations (theme secondary container).
  warning,

  /// Critical — requires attention (theme error container).
  error,
}
