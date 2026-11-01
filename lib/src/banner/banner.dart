import 'dart:async';

import 'package:flutter/material.dart';

import 'announcement.dart';
import 'store.dart';

/// Renders the first active, not-yet-dismissed [PrismAnnouncement] as a
/// dismissible banner above your content.
///
/// The banner is hidden while there is nothing to show, so you can drop it at
/// the top of any column. Dismissals are persisted via [BannerDismissStore]
/// (default: `shared_preferences`), and a previously-dismissed banner returns
/// when you bump the announcement's `version`.
///
/// ```dart
/// Column(
///   children: [
///     PrismBanner(
///       announcements: [
///         const PrismAnnouncement(
///           id: 'release-2-1',
///           message: 'New in 2.1: dark mode and faster sync!',
///           actionLabel: 'See what\u2019s new',
///         ),
///       ],
///     ),
///     // …the rest of your page…
///   ],
/// )
/// ```
class PrismBanner extends StatefulWidget {
  /// Creates a banner host.
  const PrismBanner({
    super.key,
    required this.announcements,
    this.store = const SharedPrefsDismissStore(),
    this.priority = PrismBannerPriority.newest,
    this.style,
    this.maxWidth = 720,
  });

  /// Candidate announcements. Only the first scheduled, undismissed one is
  /// shown per [priority].
  final List<PrismAnnouncement> announcements;

  /// Where dismissals are persisted.
  final BannerDismissStore store;

  /// Which announcement wins when several are eligible.
  final PrismBannerPriority priority;

  /// Optional custom styling; falls back to the ambient [ThemeData].
  final PrismBannerStyle? style;

  /// Maximum banner width; wider windows center the banner.
  final double maxWidth;

  @override
  State<PrismBanner> createState() => _PrismBannerState();
}

/// Selection order when multiple announcements are eligible.
enum PrismBannerPriority {
  /// The last announcement in the list wins (most recent first).
  newest,

  /// The first announcement in the list wins.
  oldest,

  /// The highest-severity announcement wins.
  severity,
}

/// Visual configuration for [PrismBanner].
@immutable
class PrismBannerStyle {
  /// Creates a style.
  const PrismBannerStyle({
    this.color,
    this.foregroundColor,
    this.borderRadius = 12,
    this.margin = const EdgeInsets.fromLTRB(12, 8, 12, 0),
    this.padding = const EdgeInsets.fromLTRB(16, 12, 8, 12),
    this.titleStyle,
    this.messageStyle,
  });

  /// Background color; defaults to the severity's container color.
  final Color? color;

  /// Text/icon color; defaults to the severity's on-container color.
  final Color? foregroundColor;

  /// Corner radius of the banner card.
  final double borderRadius;

  /// Outer margin around the banner.
  final EdgeInsetsGeometry margin;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  /// Style for [PrismAnnouncement.title].
  final TextStyle? titleStyle;

  /// Style for [PrismAnnouncement.message].
  final TextStyle? messageStyle;
}

class _PrismBannerState extends State<PrismBanner> {
  Map<String, int> _dismissed = {};

  @override
  void initState() {
    super.initState();
    unawaited(_loadDismissed());
  }

  Future<void> _loadDismissed() async {
    final ids = widget.announcements.map((a) => a.id);
    final entries = <String, int>{};
    for (final id in ids) {
      final v = await widget.store.dismissedVersion(id);
      if (v != null) entries[id] = v;
    }
    if (!mounted) return;
    setState(() => _dismissed = entries);
  }

  Future<void> _dismiss(PrismAnnouncement announcement) async {
    // Optimistic UI update; the store write completes in the background.
    // Filtering is purely version-based, so widget updates (e.g. version
    // bumps) re-show the banner correctly even when the State is reused.
    if (!mounted) return;
    setState(
      () => _dismissed = {..._dismissed, announcement.id: announcement.version},
    );
    await widget.store.dismiss(announcement.id, announcement.version);
    if (!mounted) return;
    setState(
      () => _dismissed = {..._dismissed, announcement.id: announcement.version},
    );
  }

  PrismAnnouncement? _select() {
    final now = DateTime.now();
    final candidates = widget.announcements
        .where((a) => a.isScheduledFor(now))
        .where((a) => (_dismissed[a.id] ?? -1) < a.version)
        .toList();
    if (candidates.isEmpty) return null;
    switch (widget.priority) {
      case PrismBannerPriority.newest:
        return candidates.last;
      case PrismBannerPriority.oldest:
        return candidates.first;
      case PrismBannerPriority.severity:
        return candidates.reduce(
          (a, b) => a.severity.index >= b.severity.index ? a : b,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final announcement = _select();
    final style = widget.style ?? const PrismBannerStyle();
    if (announcement == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (announcement.severity) {
      PrismSeverity.info => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      PrismSeverity.success => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      PrismSeverity.warning => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      PrismSeverity.error => (scheme.errorContainer, scheme.onErrorContainer),
    };

    final content = Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (announcement.title != null)
                Text(
                  announcement.title!,
                  style:
                      (style.titleStyle ??
                              const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ))
                          .copyWith(color: fg),
                ),
              const SizedBox(height: 2),
              Text(
                announcement.message,
                style: (style.messageStyle ?? const TextStyle(fontSize: 13.5))
                    .copyWith(color: fg),
              ),
            ],
          ),
        ),
        if (announcement.actionLabel != null)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton(
              onPressed: () {
                announcement.onAction?.call();
                unawaited(_dismiss(announcement));
              },
              style: TextButton.styleFrom(foregroundColor: fg),
              child: Text(announcement.actionLabel!),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(Icons.close, size: 20),
            color: fg,
            onPressed: () => unawaited(_dismiss(announcement)),
          ),
        ),
      ],
    );

    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        margin: style.margin,
        child: Material(
          color: style.color ?? bg,
          borderRadius: BorderRadius.circular(style.borderRadius),
          child: InkWell(
            borderRadius: BorderRadius.circular(style.borderRadius),
            onTap: announcement.onAction,
            child: Padding(padding: style.padding, child: content),
          ),
        ),
      ),
    );
  }
}
