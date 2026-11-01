import 'dart:async';

import 'package:flutter/material.dart';

/// The visual/semantic type of a toast.
enum PrismToastType {
  /// Positive confirmation — check icon, success colors.
  success,

  /// Failure — error icon, error colors.
  error,

  /// Caution — warning icon, warning colors.
  warning,

  /// Neutral information — info icon, primary colors.
  info,
}

/// One toast shown by [PrismToast.show].
@immutable
class PrismToastMessage {
  /// Creates a toast payload.
  const PrismToastMessage({
    required this.message,
    this.type = PrismToastType.info,
    this.title,
    this.duration = const Duration(seconds: 3),
    this.actionLabel,
    this.onAction,
  });

  /// Main toast text.
  final String message;

  /// Visual/semantic type; drives icon and colors.
  final PrismToastType type;

  /// Optional bold lead-in above [message].
  final String? title;

  /// How long the toast stays visible.
  final Duration duration;

  /// Optional action button label.
  final String? actionLabel;

  /// Invoked when the user taps [actionLabel].
  final VoidCallback? onAction;
}

/// Adaptive, beautiful toast notifications.
///
/// - **Compact windows** (< 600px): toasts slide up from the bottom edge,
///   nearly full width — the mobile pattern.
/// - **Wide windows**: toasts stack in the top-right corner at a fixed card
///   width — the desktop/web notification pattern.
///
/// ```dart
/// PrismToast.show(
///   context,
///   const PrismToastMessage(
///     message: 'Settings saved.',
///     type: PrismToastType.success,
///   ),
/// );
/// ```
class PrismToast {
  PrismToast._();

  static OverlayEntry? _hostEntry;
  static final _ToastManager _manager = _ToastManager();

  /// Shows an adaptive toast. Safe to call from anywhere with a
  /// [BuildContext] below a [Navigator].
  static void show(BuildContext context, PrismToastMessage message) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    assert(overlay != null, 'PrismToast requires a Navigator/Overlay above.');
    if (overlay == null) return;

    _manager.add(_ToastSlot(message));
    if (_hostEntry == null) {
      _hostEntry = OverlayEntry(builder: (_) => _ToastHost(manager: _manager));
      overlay.insert(_hostEntry!);
    }
  }

  /// Shorthand for an info toast.
  static void info(BuildContext context, String message) =>
      show(context, PrismToastMessage(message: message));

  /// Shorthand for a success toast.
  static void success(BuildContext context, String message) => show(
    context,
    PrismToastMessage(message: message, type: PrismToastType.success),
  );

  /// Shorthand for an error toast.
  static void error(BuildContext context, String message) => show(
    context,
    PrismToastMessage(message: message, type: PrismToastType.error),
  );

  /// Shorthand for a warning toast.
  static void warning(BuildContext context, String message) => show(
    context,
    PrismToastMessage(message: message, type: PrismToastType.warning),
  );

  /// Removes every visible toast immediately.
  static void dismissAll() {
    for (final slot in _manager.slots) {
      slot.controller._cancelTimer();
    }
    _manager.clear();
    _removeHost();
  }

  static void _removeHost() {
    _hostEntry?.remove();
    _hostEntry = null;
  }

  static void _onSlotGone(_ToastSlot slot) {
    _manager.remove(slot);
    if (_manager.slots.isEmpty) _removeHost();
  }
}

/// Observable slot list driving the toast host.
class _ToastManager extends ChangeNotifier {
  final List<_ToastSlot> slots = [];

  void add(_ToastSlot slot) {
    slots.add(slot);
    notifyListeners();
  }

  void remove(_ToastSlot slot) {
    if (slots.remove(slot)) notifyListeners();
  }

  void clear() {
    if (slots.isNotEmpty) {
      slots.clear();
      notifyListeners();
    }
  }
}

/// One visible toast: its message plus the animation controller driving its
/// entrance/exit.
class _ToastSlot {
  _ToastSlot(this.message);

  final PrismToastMessage message;
  final _SlotController controller = _SlotController();
}

/// Mutable handle shared between the manager and the card widget.
class _SlotController {
  _CardState? _state;

  void _cancelTimer() {
    _state?._cancelTimer();
  }

  void dismiss() => _state?.beginExit();
}

/// The single overlay host rendering all current toasts.
class _ToastHost extends StatelessWidget {
  const _ToastHost({required this.manager});

  final _ToastManager manager;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: manager,
      builder: (context, _) => _build(context),
    );
  }

  Widget _build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    final slots = List<_ToastSlot>.of(manager.slots);
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final slot in slots.reversed)
          Padding(
            key: ValueKey(slot),
            padding: const EdgeInsets.only(top: 8),
            child: _ToastCard(slot: slot, wide: wide),
          ),
      ],
    );

    if (wide) {
      return Positioned(
        top: 16,
        right: 16,
        width: 380,
        child: IgnorePointer(ignoring: slots.isEmpty, child: column),
      );
    }
    return Positioned(
      left: 16,
      right: 16,
      bottom: MediaQuery.paddingOf(context).bottom + 16,
      child: IgnorePointer(ignoring: slots.isEmpty, child: column),
    );
  }
}

/// One animated toast card.
class _ToastCard extends StatefulWidget {
  const _ToastCard({required this.slot, required this.wide});

  final _ToastSlot slot;
  final bool wide;

  @override
  State<_ToastCard> createState() => _CardState();
}

class _CardState extends State<_ToastCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..forward();
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  Timer? _timer;
  bool _exiting = false;

  _SlotController get _slotController => widget.slot.controller;

  @override
  void initState() {
    super.initState();
    _slotController._state = this;
    _timer = Timer(widget.slot.message.duration, beginExit);
  }

  void beginExit() {
    if (_exiting || !mounted) return;
    _exiting = true;
    _cancelTimer();
    _controller.reverse().whenComplete(() {
      PrismToast._onSlotGone(widget.slot);
    });
  }

  void _cancelTimer() => _timer?.cancel();

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.slot.message;
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (message.type) {
      PrismToastType.success => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.check_circle_rounded,
      ),
      PrismToastType.error => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.error_rounded,
      ),
      PrismToastType.warning => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        Icons.warning_amber_rounded,
      ),
      PrismToastType.info => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
        Icons.info_rounded,
      ),
    };

    final content = Row(
      children: [
        Icon(icon, color: fg, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (message.title != null)
                Text(
                  message.title!,
                  style: TextStyle(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              Text(
                message.message,
                style: TextStyle(color: fg, fontSize: 13.5, height: 1.25),
              ),
            ],
          ),
        ),
        if (message.actionLabel != null)
          TextButton(
            onPressed: () {
              message.onAction?.call();
              beginExit();
            },
            style: TextButton.styleFrom(foregroundColor: fg),
            child: Text(message.actionLabel!),
          ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: 'Dismiss',
          icon: Icon(Icons.close, size: 18, color: fg),
          onPressed: beginExit,
        ),
      ],
    );

    final toast = Material(
      color: bg,
      elevation: 4,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 6, 12),
        child: content,
      ),
    );

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position:
            Tween<Offset>(
              begin: widget.wide ? const Offset(0.2, 0) : const Offset(0, 1),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
            ),
        child: toast,
      ),
    );
  }
}
