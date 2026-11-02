import 'package:flutter/material.dart';

import '../adaptive_scaffold/adaptive_scaffold.dart';
import '../theme/theme.dart';
import 'controller.dart';
import 'tiles.dart';

/// A ready-made settings page.
///
/// Owns a [PrismSettingsController] (or adopts yours), centers content at a
/// comfortable width on wide windows, and optionally filters sections/tiles
/// by a built-in search field.
///
/// ```dart
/// PrismSettingsPage(
///   controller: controller,
///   searchable: true,
///   sections: [
///     PrismSettingsSection(
///       title: 'Appearance',
///       tiles: [
///         PrismSwitchTile(
///           common: PrismTileCommon(
///             key: 'darkMode',
///             title: 'Dark mode',
///             leading: Icons.dark_mode,
///           ),
///         ),
///       ],
///     ),
///   ],
/// )
/// ```
class PrismSettingsPage extends StatefulWidget {
  /// Creates a settings page.
  const PrismSettingsPage({
    super.key,
    this.controller,
    required this.sections,
    this.searchable = false,
    this.searchHint = 'Search settings…',
    this.maxWidth = 720,
  });

  /// Optional externally-owned controller.
  final PrismSettingsController? controller;

  /// The settings groups.
  final List<PrismSettingsSection> sections;

  /// Whether to show a filter field above the content.
  final bool searchable;

  /// Placeholder for the search field.
  final String searchHint;

  /// Maximum content width.
  final double maxWidth;

  @override
  State<PrismSettingsPage> createState() => _PrismSettingsPageState();
}

class _PrismSettingsPageState extends State<PrismSettingsPage> {
  PrismSettingsController? _internal;
  final _searchController = TextEditingController();
  String _query = '';

  PrismSettingsController get _effective =>
      widget.controller ?? (_internal ??= PrismSettingsController());

  @override
  void dispose() {
    _searchController.dispose();
    _internal?.dispose();
    super.dispose();
  }

  List<Widget> _filteredTiles(PrismSettingsSection section) {
    if (_query.isEmpty) return section.tiles;
    final q = _query.toLowerCase();
    final matches = <Widget>[];
    for (final tile in section.tiles) {
      final common = _commonOf(tile);
      if (common == null) continue;
      final haystack = '${common.title} ${common.subtitle ?? ''}'.toLowerCase();
      if (haystack.contains(q)) matches.add(tile);
    }
    return matches;
  }

  /// Reads the common config out of a tile via its runtime type.
  PrismTileCommon? _commonOf(Widget tile) => switch (tile) {
    final PrismActionTile t => t.common,
    final PrismSwitchTile t => t.common,
    final PrismCheckboxTile t => t.common,
    final PrismSliderTile t => t.common,
    final PrismDropdownTile<dynamic> t => t.common,
    _ => null,
  };

  @override
  Widget build(BuildContext context) {
    final isWide =
        PrismBreakpoint.resolve(MediaQuery.sizeOf(context).width) !=
        PrismBreakpoint.compact;

    return PrismSettingsScope(
      notifier: _effective,
      child: Scaffold(
        body: SingleChildScrollView(
          padding:
              EdgeInsets.symmetric(vertical: context.prismTokens.spaceSm),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: widget.maxWidth),
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? context.prismTokens.spaceLg : 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.searchable)
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        context.prismTokens.spaceMd,
                        context.prismTokens.spaceSm,
                        context.prismTokens.spaceMd,
                        context.prismTokens.spaceXs,
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: widget.searchHint,
                          prefixIcon: const Icon(Icons.search),
                          isDense: true,
                          border: const OutlineInputBorder(),
                          suffixIcon: _query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                        ),
                        onChanged: (value) => setState(() => _query = value),
                      ),
                    ),
                  for (final section in widget.sections)
                    Builder(
                      builder: (context) {
                        final tiles = _filteredTiles(section);
                        if (tiles.isEmpty && _query.isNotEmpty) {
                          return const SizedBox.shrink();
                        }
                        return PrismSettingsSection(
                          title: section.title,
                          maxWidth: widget.maxWidth,
                          tiles: tiles,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
