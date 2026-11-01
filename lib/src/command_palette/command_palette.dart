import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/theme.dart';

/// One command shown in a [PrismCommandPalette].
@immutable
class PrismCommand {
  /// Creates a command.
  const PrismCommand({
    required this.label,
    required this.onSelect,
    this.id,
    this.subtitle,
    this.icon,
    this.group = 'General',
    this.shortcut,
    this.keywords = const [],
    this.enabled = true,
    this.trailing,
  });

  /// Primary label shown in the list.
  final String label;

  /// Runs when the command is chosen.
  final VoidCallback onSelect;

  /// Stable identifier, useful for tests and recent-command tracking.
  final String? id;

  /// Secondary description.
  final String? subtitle;

  /// Leading icon.
  final IconData? icon;

  /// Section header this command is grouped under.
  final String group;

  /// Shortcut hint rendered on the right (e.g. `⌘S`).
  final String? shortcut;

  /// Extra search terms that should match this command.
  final List<String> keywords;

  /// Whether the command can be chosen.
  final bool enabled;

  /// Widget rendered at the trailing edge, after [shortcut].
  final Widget? trailing;

  /// Everything searchable about this command, lowercased.
  String get searchText =>
      '${label.toLowerCase()} ${subtitle?.toLowerCase() ?? ''} '
      '${group.toLowerCase()} ${keywords.join(' ').toLowerCase()}';
}

/// A ⌘K-style command palette that can be opened from anywhere.
///
/// Fuzzy-searches a flat list of [PrismCommand]s, groups the results, and
/// supports full keyboard navigation (arrows, Enter, Escape, or a numeric
/// quick-pick). On compact windows it opens as a full-screen sheet; on wide
/// windows it appears as a centred panel near the top of the screen.
///
/// ```dart
/// PrismCommandPalette.show(
///   context: context,
///   commands: [
///     PrismCommand(label: 'New note', icon: Icons.add, onSelect: createNote),
///     PrismCommand(label: 'Toggle theme', icon: Icons.dark_mode, onSelect: toggleTheme),
///   ],
/// );
/// ```
class PrismCommandPalette extends StatefulWidget {
  /// Creates a command palette. Prefer [show] to present it as a route.
  const PrismCommandPalette({
    super.key,
    required this.commands,
    this.placeholder = 'Type a command or search…',
    this.emptyMessage = 'No matching commands',
    this.onCommandSelected,
    this.initialQuery = '',
    this.maxResults = 50,
  });

  /// Every command available.
  final List<PrismCommand> commands;

  /// Placeholder text for the search field.
  final String placeholder;

  /// Shown when nothing matches.
  final String emptyMessage;

  /// Called with the chosen command, before its [PrismCommand.onSelect].
  final ValueChanged<PrismCommand>? onCommandSelected;

  /// Pre-fills the query.
  final String initialQuery;

  /// Caps how many results are rendered at once.
  final int maxResults;

  /// Presents the palette as a route and resolves with the chosen command.
  static Future<PrismCommand?> show({
    required BuildContext context,
    required List<PrismCommand> commands,
    String placeholder = 'Type a command or search…',
    String? initialQuery,
  }) {
    final tokens = PrismTokens.of(context);
    final narrow = MediaQuery.sizeOf(context).width < tokens.breakpointCompact;

    if (narrow) {
      return Navigator.of(context).push<PrismCommand>(
        MaterialPageRoute<PrismCommand>(
          fullscreenDialog: true,
          builder: (routeContext) => Scaffold(
            body: SafeArea(
              child: PrismCommandPalette(
                commands: commands,
                placeholder: placeholder,
                initialQuery: initialQuery ?? '',
                onCommandSelected: (c) => Navigator.of(routeContext).pop(c),
              ),
            ),
          ),
        ),
      );
    }

    return showDialog<PrismCommand>(
      context: context,
      barrierColor: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.35),
      builder: (dialogContext) => Align(
        alignment: const Alignment(0, -0.55),
        child: Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620, maxHeight: 520),
            child: PrismCommandPalette(
              commands: commands,
              placeholder: placeholder,
              initialQuery: initialQuery ?? '',
              onCommandSelected: (c) => Navigator.of(dialogContext).pop(c),
            ),
          ),
        ),
      ),
    );
  }

  @override
  State<PrismCommandPalette> createState() => _PrismCommandPaletteState();
}

class _PrismCommandPaletteState extends State<PrismCommandPalette> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  int _highlighted = 0;
  late List<PrismCommand> _matches;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialQuery);
    _matches = _computeMatches(widget.initialQuery);
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    setState(() {
      _matches = _computeMatches(_controller.text);
      _highlighted = 0;
    });
  }

  List<PrismCommand> _computeMatches(String query) {
    final trimmed = query.trim().toLowerCase();
    final enabled = widget.commands.where((c) => c.enabled).toList();
    if (trimmed.isEmpty) return enabled.take(widget.maxResults).toList();

    // Rank: exact-prefix of label > word-prefix > substring > fuzzy.
    final scored = <(int, PrismCommand)>[];
    for (final command in enabled) {
      final label = command.label.toLowerCase();
      final haystack = command.searchText;
      int? score;
      if (label.startsWith(trimmed)) {
        score = 0;
      } else if (label.split(RegExp(r'\s+')).any((w) => w.startsWith(trimmed))) {
        score = 1;
      } else if (label.contains(trimmed)) {
        score = 2;
      } else if (haystack.contains(trimmed)) {
        score = 3;
      } else if (_fuzzyMatches(haystack, trimmed)) {
        score = 4;
      }
      if (score != null) scored.add((score, command));
    }
    scored.sort((a, b) => a.$1.compareTo(b.$1));
    return scored.take(widget.maxResults).map((e) => e.$2).toList();
  }

  /// Subsequence match — lets "tn" find "Toggle theme".
  static bool _fuzzyMatches(String haystack, String needle) {
    var i = 0;
    for (final ch in haystack.split('')) {
      if (ch == needle[i]) {
        i++;
        if (i == needle.length) return true;
      }
    }
    return false;
  }

  void _move(int delta) {
    if (_matches.isEmpty) return;
    setState(() {
      _highlighted = (_highlighted + delta) % _matches.length;
      if (_highlighted < 0) _highlighted += _matches.length;
    });
  }

  void _select(PrismCommand command) {
    widget.onCommandSelected?.call(command);
    command.onSelect();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_matches.isNotEmpty) _select(_matches[_highlighted]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;

    // Group the matches while preserving ranking within each group.
    final groups = <String, List<PrismCommand>>{};
    for (final command in _matches) {
      groups.putIfAbsent(command.group, () => []).add(command);
    }

    var flatIndex = 0;
    final rows = <Widget>[];
    for (final entry in groups.entries) {
      rows.add(
        Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.spaceMd,
            tokens.spaceSm,
            tokens.spaceMd,
            tokens.spaceXs,
          ),
          child: Text(
            entry.key.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      );
      for (final command in entry.value) {
        final index = flatIndex++;
        rows.add(
          _CommandTile(
            command: command,
            highlighted: index == _highlighted,
            onTap: () => _select(command),
            onHover: () => setState(() => _highlighted = index),
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.radiusXl),
        border: Border.all(color: colors.outline, width: tokens.borderWidth),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMd,
              vertical: tokens.spaceSm,
            ),
            child: Row(
              children: [
                Icon(Icons.search, color: scheme.onSurfaceVariant),
                SizedBox(width: tokens.spaceSm),
                Expanded(
                  child: Focus(
                    onKeyEvent: _onKey,
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      autofocus: true,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.placeholder,
                      ),
                      onSubmitted: (_) {
                        if (_matches.isNotEmpty) _select(_matches[_highlighted]);
                      },
                    ),
                  ),
                ),
                if (_controller.text.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear',
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => _controller.clear(),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.outline),
          Flexible(
            child: _matches.isEmpty
                ? Padding(
                    padding: EdgeInsets.all(tokens.spaceXl),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 32,
                          color: scheme.onSurfaceVariant,
                        ),
                        SizedBox(height: tokens.spaceSm),
                        Text(
                          widget.emptyMessage,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController,
                    child: ListView(
                      controller: _scrollController,
                      shrinkWrap: true,
                      padding: EdgeInsets.only(bottom: tokens.spaceSm),
                      children: rows,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CommandTile extends StatelessWidget {
  const _CommandTile({
    required this.command,
    required this.highlighted,
    required this.onTap,
    required this.onHover,
  });

  final PrismCommand command;
  final bool highlighted;
  final VoidCallback onTap;
  final VoidCallback onHover;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => onHover(),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: highlighted
            ? scheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMd,
              vertical: tokens.spaceSm,
            ),
            child: Row(
              children: [
                if (command.icon != null) ...[
                  Icon(
                    command.icon,
                    size: 18,
                    color: highlighted
                        ? scheme.primary
                        : scheme.onSurfaceVariant,
                  ),
                  SizedBox(width: tokens.spaceSm),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        command.label,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(
                              fontWeight:
                                  highlighted ? FontWeight.w600 : FontWeight.w400,
                            ),
                      ),
                      if (command.subtitle != null)
                        Text(
                          command.subtitle!,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                if (command.shortcut != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: context.prismColors.surfaceSunken,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      command.shortcut!,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                if (command.trailing != null) ...[
                  const SizedBox(width: 8),
                  command.trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
