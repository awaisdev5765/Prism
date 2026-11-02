import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../adaptive_scaffold/adaptive_scaffold.dart';

import '../theme/theme.dart';

/// How the detail pane is presented on compact (phone-width) windows.
enum PrismCompactBehavior {
  /// Pushes the detail as a full-screen route onto the Navigator, so the
  /// user gets the platform back gesture/button for free. Default.
  push,

  /// Swaps the master list for the detail view inside this widget — useful
  /// when the widget is embedded in layouts that manage their own
  /// navigation. The built-in back button clears the selection.
  replace,
}

/// An adaptive master-detail layout.
///
/// On compact windows (phones) it shows the master list full-screen and
/// presents the detail when an item is activated — either pushed onto the
/// navigation stack ([PrismCompactBehavior.push]) or swapped in place
/// ([PrismCompactBehavior.replace]). On medium and wider windows it shows
/// both panes side by side, with keyboard navigation (arrow keys + Enter)
/// on desktop.
///
/// ```dart
/// PrismMasterDetail<Mail>(
///   items: mails,
///   masterBuilder: (context, mail, selected) => ListTile(
///     selected: selected,
///     leading: Icon(mail.icon),
///     title: Text(mail.subject),
///   ),
///   detailBuilder: (context, mail) => MailView(mail: mail),
///   empty: (context) => const Center(child: Text('Pick a message')),
/// )
/// ```
///
/// Selection can be uncontrolled (default — the widget manages the selected
/// index) or controlled via [selectedIndex] + [onSelectionChanged].
///
/// Pure Flutter — no platform channels — works on Android, iOS, macOS,
/// Windows, Linux, and web.
class PrismMasterDetail<T> extends StatefulWidget {
  /// Creates a master-detail layout.
  const PrismMasterDetail({
    super.key,
    required this.items,
    required this.masterBuilder,
    required this.detailBuilder,
    this.empty,
    this.selectedIndex,
    this.onSelectionChanged,
    this.compactBehavior = PrismCompactBehavior.push,
    this.masterPaneWidth = 320,
    this.masterPaneWidthExtraLarge,
    this.masterColor,
    this.detailColor,
    this.divider,
    this.transitionDuration,
    this.autoFocus = false,
    this.debugCompactOverride = false,
  });

  /// The items rendered in the master pane.
  final List<T> items;

  /// Builds one row in the master pane. [selected] is true for the item
  /// matching the current selection, so consumers can style it.
  final Widget Function(BuildContext context, T item, bool selected)
  masterBuilder;

  /// Builds the detail pane for the given item.
  final Widget Function(BuildContext context, T item) detailBuilder;

  /// Shown in the detail pane when nothing is selected (wide windows only).
  final WidgetBuilder? empty;

  /// Controls the selection externally. When null the widget manages its own
  /// selection state.
  final int? selectedIndex;

  /// Called when the selection changes. With
  /// [PrismCompactBehavior.replace] on compact windows, the built-in back
  /// button reports `null` when the user dismisses the detail.
  final ValueChanged<int?>? onSelectionChanged;

  /// How the detail is presented on compact windows.
  final PrismCompactBehavior compactBehavior;

  /// Width of the master pane on medium and expanded windows.
  final double masterPaneWidth;

  /// Optional wider master pane used on extra-large windows (1200px+).
  /// Falls back to [masterPaneWidth] when null.
  final double? masterPaneWidthExtraLarge;

  /// Optional background color for the master pane.
  final Color? masterColor;

  /// Optional background color for the detail pane.
  final Color? detailColor;

  /// Divider drawn between the panes. Defaults to a thin border line.
  final Widget? divider;

  /// Duration of the detail-pane transition.
  /// Duration for animated transitions between panes. Defaults to
  /// [PrismTokens.durationMedium].
  final Duration? transitionDuration;

  /// Whether the master list grabs keyboard focus on first build, enabling
  /// arrow-key/Enter navigation without an initial click. Off by default so
  /// the widget doesn't steal focus from text fields.
  final bool autoFocus;

  /// Forces compact layout even on wide windows — useful for previews and
  /// golden tests. Do not use in production code.
  final bool debugCompactOverride;

  @override
  State<PrismMasterDetail<T>> createState() => _PrismMasterDetailState<T>();
}

class _PrismMasterDetailState<T> extends State<PrismMasterDetail<T>> {
  int? _internalSelection;
  bool _compactDetailOpen = false;

  late final FocusNode _focusNode = FocusNode(debugLabel: 'PrismMasterDetail');

  @override
  void initState() {
    super.initState();
    if (widget.autoFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _isControlled => widget.selectedIndex != null;

  int? get _selection =>
      _isControlled ? widget.selectedIndex : _internalSelection;

  bool get _isCompact =>
      widget.debugCompactOverride ||
      PrismBreakpoint.resolve(MediaQuery.sizeOf(context).width) ==
          PrismBreakpoint.compact;

  void _select(int index, {required bool activate}) {
    widget.onSelectionChanged?.call(index);
    if (!_isControlled) {
      setState(() => _internalSelection = index);
    }
    if (!activate || !_isCompact) return;

    switch (widget.compactBehavior) {
      case PrismCompactBehavior.push:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (context) => _DetailPage(
              detailBuilder: widget.detailBuilder,
              item: widget.items[index],
            ),
          ),
        );
      case PrismCompactBehavior.replace:
        setState(() => _compactDetailOpen = true);
    }
  }

  void _handleTap(int index) => _select(index, activate: true);

  /// Arrow-key navigation: moves the selection without opening the detail.
  void _moveSelection(int delta) {
    if (widget.items.isEmpty) return;
    final current = _selection ?? -1;
    final next = (current + delta).clamp(0, widget.items.length - 1);
    if (next == current) return;
    _select(next, activate: false);
  }

  void _dismissCompactDetail() {
    // Report null in both modes so apps can react to dismissal uniformly.
    widget.onSelectionChanged?.call(null);
    if (!_isControlled) {
      setState(() => _compactDetailOpen = false);
    }
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      _moveSelection(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _moveSelection(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final selection = _selection;
      if (selection != null && selection < widget.items.length) {
        _select(selection, activate: true);
      } else if (widget.items.isNotEmpty) {
        _select(0, activate: true);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final list = Focus(
      focusNode: _focusNode,
      onKeyEvent: _handleKey,
      child: _MasterList(
        items: widget.items,
        masterBuilder: widget.masterBuilder,
        selection: _selection,
        onTap: _handleTap,
      ),
    );

    if (_isCompact) {
      final selection = _selection;
      final showDetail =
          widget.compactBehavior == PrismCompactBehavior.replace &&
          selection != null &&
          selection < widget.items.length &&
          (_isControlled || _compactDetailOpen);
      if (showDetail) {
        return Scaffold(
          appBar: AppBar(leading: BackButton(onPressed: _dismissCompactDetail)),
          body: widget.detailBuilder(context, widget.items[selection]),
        );
      }
      return Material(type: MaterialType.transparency, child: list);
    }

    final width = MediaQuery.sizeOf(context).width;
    final paneWidth =
        (PrismBreakpoint.resolve(width) == PrismBreakpoint.extraLarge &&
            widget.masterPaneWidthExtraLarge != null)
        ? widget.masterPaneWidthExtraLarge!
        : widget.masterPaneWidth;

    final selection = _selection;
    final T? selectedItem =
        (selection != null && selection < widget.items.length)
        ? widget.items[selection]
        : null;

    return Material(
      type: MaterialType.transparency,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(width: paneWidth, color: widget.masterColor, child: list),
          widget.divider ?? const VerticalDivider(width: 1),
          Expanded(
            child: Container(
              color: widget.detailColor,
              child: AnimatedSwitcher(
                duration:
                    widget.transitionDuration ??
                    context.prismTokens.durationMedium,
                child: selectedItem == null
                    ? KeyedSubtree(
                        key: const ValueKey('empty'),
                        child:
                            widget.empty?.call(context) ??
                            const Center(child: Text('Select an item')),
                      )
                    : KeyedSubtree(
                        key: ValueKey(selection),
                        child: widget.detailBuilder(context, selectedItem),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable list of master rows.
class _MasterList<T> extends StatelessWidget {
  const _MasterList({
    required this.items,
    required this.masterBuilder,
    required this.selection,
    required this.onTap,
  });

  final List<T> items;
  final Widget Function(BuildContext, T, bool) masterBuilder;
  final int? selection;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    // The scrollable inside ListView owns a focus node that would otherwise
    // become the primary focus and consume arrow keys for scrolling. A
    // non-focusable scope keeps this widget's node as the primary focus so
    // keyboard navigation works; touch/trackpad scrolling is unaffected.
    return FocusScope(
      canRequestFocus: false,
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => onTap(index),
            child: masterBuilder(context, items[index], index == selection),
          );
        },
      ),
    );
  }
}

/// Full-screen detail page pushed in compact mode, with automatic back
/// gesture/button support from the Navigator.
class _DetailPage<T> extends StatelessWidget {
  const _DetailPage({required this.detailBuilder, required this.item});

  final Widget Function(BuildContext, T) detailBuilder;
  final T item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: detailBuilder(context, item));
  }
}
