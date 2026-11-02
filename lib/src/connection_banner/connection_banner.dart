import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// How a [PrismConnectionBanner] learns about connectivity.
///
/// Prism deliberately ships no network dependency: you plug in whatever
/// source your app already has (a repository stream, `connectivity_plus`, a
/// heartbeat) and the widget handles pacing, animation and semantics.
typedef PrismConnectionSource = Stream<bool> Function();

/// A slim banner that appears while the app is offline and disappears the
/// moment connectivity returns.
///
/// It respects a settle delay so a two-second network blip does not flash a
/// banner, and it announces itself with `Assertiveness.polite` so screen
/// readers hear the change without being interrupted mid-sentence.
///
/// ```dart
/// Column(
///   children: [
///     PrismConnectionBanner(
///       source: () => Connectivity().onConnectivityChanged.map((r) => r != ConnectivityResult.none),
///     ),
///     Expanded(child: content),
///   ],
/// )
/// ```
class PrismConnectionBanner extends StatefulWidget {
  /// Creates a connection banner.
  const PrismConnectionBanner({
    super.key,
    required this.source,
    this.offlineMessage =
        'You are offline — changes will sync when you reconnect',
    this.onlineMessage,
    this.onlineDuration = const Duration(seconds: 2),
    this.settleDelay = const Duration(milliseconds: 700),
    this.assumeOnline = true,
    this.compact = false,
    this.retryLabel,
    this.onRetry,
    this.margin,
  });

  /// Produces a stream of `true` (online) / `false` (offline) events.
  final PrismConnectionSource source;

  /// Message shown while offline.
  final String offlineMessage;

  /// Optional message flashed briefly when connectivity returns.
  final String? onlineMessage;

  /// How long the "reconnected" message stays visible.
  final Duration onlineDuration;

  /// Delay before showing the offline state, dampening brief blips.
  final Duration settleDelay;

  /// Whether the widget starts in the online state.
  final bool assumeOnline;

  /// Renders a shorter, denser banner.
  final bool compact;

  /// Label for the retry action shown while offline.
  final String? retryLabel;

  /// Called when retry is tapped.
  final VoidCallback? onRetry;

  /// Outer margin; defaults to a small inset.
  final EdgeInsetsGeometry? margin;

  @override
  State<PrismConnectionBanner> createState() => _PrismConnectionBannerState();
}

class _PrismConnectionBannerState extends State<PrismConnectionBanner> {
  StreamSubscription<bool>? _subscription;
  Timer? _settleTimer;
  Timer? _onlineTimer;

  late bool _online;
  bool _wasOffline = false;

  @override
  void initState() {
    super.initState();
    _online = widget.assumeOnline;
    _subscription = widget.source().listen(_onEvent, onError: (Object _) {});
  }

  @override
  void didUpdateWidget(PrismConnectionBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      _subscription?.cancel();
      _subscription = widget.source().listen(_onEvent, onError: (Object _) {});
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _settleTimer?.cancel();
    _onlineTimer?.cancel();
    super.dispose();
  }

  void _onEvent(bool online) {
    _settleTimer?.cancel();
    _onlineTimer?.cancel();

    if (online) {
      // Reconnecting is good news — show it immediately, briefly.
      if (!mounted) return;
      setState(() {
        _online = true;
      });
      if (_wasOffline && widget.onlineMessage != null) {
        _onlineTimer = Timer(widget.onlineDuration, () {
          if (mounted) setState(() => _wasOffline = false);
        });
      } else {
        _wasOffline = false;
      }
      return;
    }

    // Going offline waits out short blips before alarming the user.
    _settleTimer = Timer(widget.settleDelay, () {
      if (!mounted) return;
      setState(() {
        _online = false;
        _wasOffline = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final showReconnected =
        _online && _wasOffline && widget.onlineMessage != null;
    final visible = !_online || showReconnected;

    return AnimatedSize(
      duration: tokens.durationMedium,
      curve: tokens.curveStandard,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: tokens.durationMedium,
        switchInCurve: tokens.curveEmphasized,
        switchOutCurve: tokens.curveExit,
        child: !visible
            ? const SizedBox.shrink()
            : _banner(context: context, colors: colors, tokens: tokens),
      ),
    );
  }

  Widget _banner({
    required BuildContext context,
    required PrismColors colors,
    required PrismTokens tokens,
  }) {
    final semantic = _online ? PrismSemantic.success : PrismSemantic.warning;
    final role = colors.forRole(semantic);
    final icon = _online ? Icons.cloud_done_outlined : Icons.cloud_off_outlined;
    final message = _online ? widget.onlineMessage! : widget.offlineMessage;

    return Semantics(
      liveRegion: true,
      container: true,
      label: message,
      child: Container(
        key: ValueKey('prism-connection-${_online ? 'on' : 'off'}'),
        width: double.infinity,
        margin:
            widget.margin ??
            EdgeInsets.only(
              left: tokens.spaceSm,
              right: tokens.spaceSm,
              top: tokens.spaceSm,
            ),
        padding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: widget.compact ? tokens.spaceXs + 2 : tokens.spaceSm,
        ),
        decoration: BoxDecoration(
          color: role.background,
          borderRadius: BorderRadius.circular(tokens.radiusMd),
        ),
        child: Row(
          children: [
            Icon(icon, size: widget.compact ? 16 : 18, color: role.foreground),
            SizedBox(width: tokens.spaceSm),
            Expanded(
              child: Text(
                message,
                style:
                    (widget.compact
                            ? Theme.of(context).textTheme.bodySmall
                            : Theme.of(context).textTheme.bodyMedium)
                        ?.copyWith(color: role.foreground),
              ),
            ),
            if (!_online && widget.onRetry != null)
              TextButton(
                onPressed: widget.onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: role.foreground,
                  visualDensity: VisualDensity.compact,
                ),
                child: Text(widget.retryLabel ?? 'Retry'),
              ),
          ],
        ),
      ),
    );
  }
}
