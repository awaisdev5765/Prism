import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// One column of a [PrismDataTable].
@immutable
class PrismColumn<T> {
  /// Creates a table column.
  const PrismColumn({
    required this.label,
    required this.cell,
    this.width,
    this.flex = 1,
    this.numeric = false,
    this.alwaysVisible = false,
    this.priority = 0,
    this.sortComparator,
  });

  /// Header label.
  final String label;

  /// Renders the cell for a row.
  final Widget Function(BuildContext context, T row, int index) cell;

  /// Fixed column width; when null the column shares space by [flex].
  final double? width;

  /// Share of remaining width when [width] is null. Defaults to 1.
  final int flex;

  /// Right-aligns the column, as numbers should be.
  final bool numeric;

  /// Never hidden on compact windows — useful for the identity column.
  final bool alwaysVisible;

  /// Higher priority columns survive longer when space is scarce.
  final int priority;

  /// Enables sorting on this column when non-null.
  final int Function(T a, T b)? sortComparator;
}

/// A data table that becomes a card list on narrow windows.
///
/// Desktop users get a real table with sticky header, zebra striping and
/// sortable columns. Phone users get the same data as stacked cards, with the
/// column labels rendered as field labels. One widget, two layouts — no
/// horizontal scrolling, no cut-off columns.
///
/// ```dart
/// PrismDataTable<Invoice>(
///   rows: invoices,
///   columns: [
///     PrismColumn(label: 'Invoice', cell: (c, r, i) => Text(r.id), alwaysVisible: true),
///     PrismColumn(label: 'Client',  cell: (c, r, i) => Text(r.client)),
///     PrismColumn(label: 'Total',   numeric: true, cell: (c, r, i) => Text(r.total)),
///   ],
///   onRowTap: (row, index) => open(row),
/// )
/// ```
class PrismDataTable<T> extends StatefulWidget {
  /// Creates a data table.
  const PrismDataTable({
    super.key,
    required this.rows,
    required this.columns,
    this.onRowTap,
    this.emptyMessage = 'No data',
    this.zebraStripes = true,
    this.stickyHeader = true,
    this.dense = false,
    this.rowKey,
    this.trailing,
    this.compactBreakpoint,
  });

  /// The data to display.
  final List<T> rows;

  /// Column definitions, left to right.
  final List<PrismColumn<T>> columns;

  /// Called when a row or card is tapped.
  final void Function(T row, int index)? onRowTap;

  /// Shown when [rows] is empty.
  final String emptyMessage;

  /// Alternating row background on wide layouts.
  final bool zebraStripes;

  /// Whether the header sticks while the body scrolls.
  final bool stickyHeader;

  /// Tightens row height and padding.
  final bool dense;

  /// Identity key per row, keeping sort order stable across rebuilds.
  final Key? Function(T row, int index)? rowKey;

  /// Widget rendered at the end of each row (e.g. a menu button).
  final Widget Function(BuildContext context, T row, int index)? trailing;

  /// Overrides the token breakpoint below which cards are used.
  final double? compactBreakpoint;

  @override
  State<PrismDataTable<T>> createState() => _PrismDataTableState<T>();
}

class _PrismDataTableState<T> extends State<PrismDataTable<T>> {
  int? _sortColumn;
  bool _ascending = true;

  List<T> get _sortedRows {
    final index = _sortColumn;
    if (index == null) return widget.rows;
    final comparator = widget.columns[index].sortComparator;
    if (comparator == null) return widget.rows;
    final sorted = [...widget.rows]..sort(comparator);
    return _ascending ? sorted : sorted.reversed.toList();
  }

  void _toggleSort(int index) {
    setState(() {
      if (_sortColumn == index) {
        _ascending = !_ascending;
      } else {
        _sortColumn = index;
        _ascending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final breakpoint = widget.compactBreakpoint ?? tokens.breakpointCompact;
    final isCompact = MediaQuery.sizeOf(context).width < breakpoint;
    final rows = _sortedRows;

    if (rows.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(tokens.spaceLg),
        child: Center(
          child: Text(
            widget.emptyMessage,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    return isCompact ? _buildCards(context, rows) : _buildTable(context, rows);
  }

  // ── Wide layout: a real table ──────────────────────────────────────────────

  Widget _buildTable(BuildContext context, List<T> rows) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;
    final rowHeight = widget.dense ? 40.0 : 52.0;

    Widget buildRow(int index, T row, {required bool header}) {
      return SizedBox(
        height: rowHeight,
        child: Row(
          children: [
            for (var c = 0; c < widget.columns.length; c++)
              Expanded(
                flex: widget.columns[c].flex,
                child: SizedBox(
                  width: widget.columns[c].width,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: tokens.spaceMd),
                    child: Align(
                      alignment: widget.columns[c].numeric
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: header
                          ? _HeaderCell(
                              label: widget.columns[c].label,
                              sortable: widget.columns[c].sortComparator != null,
                              ascending: _sortColumn == c && _ascending,
                              sorted: _sortColumn == c,
                              onTap: () => _toggleSort(c),
                            )
                          : DefaultTextStyle.merge(
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              child: widget.columns[c].cell(context, row, index),
                            ),
                    ),
                  ),
                ),
              ),
            if (!header && widget.trailing != null)
              Padding(
                padding: EdgeInsets.only(right: tokens.spaceSm),
                child: widget.trailing!(context, row, index),
              ),
          ],
        ),
      );
    }

    final body = ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rows.length,
      itemBuilder: (context, index) {
        final row = rows[index];
        final decorated = DecoratedBox(
          decoration: BoxDecoration(
            color: widget.zebraStripes && index.isOdd
                ? colors.surfaceSunken.withValues(alpha: 0.4)
                : null,
          ),
          child: buildRow(index, row, header: false),
        );
        if (widget.onRowTap == null) return decorated;
        return InkWell(
          key: widget.rowKey?.call(row, index),
          onTap: () => widget.onRowTap!(row, index),
          child: decorated,
        );
      },
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceRaised,
        borderRadius: BorderRadius.circular(tokens.radiusLg),
        border: Border.all(color: colors.outline, width: tokens.borderWidth),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: colors.surfaceSunken.withValues(alpha: 0.6),
              border: Border(
                bottom: BorderSide(color: colors.outline, width: tokens.borderWidth),
              ),
            ),
            child: DefaultTextStyle.merge(
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
              child: buildRow(-1, rows.first, header: true),
            ),
          ),
          Flexible(child: body),
        ],
      ),
    );
  }

  // ── Compact layout: stacked cards ─────────────────────────────────────────

  Widget _buildCards(BuildContext context, List<T> rows) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;
    // Cards have room for everything, so every column is shown — the first
    // acts as the card title and the rest become labelled field rows.
    final shown = widget.columns;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < rows.length; index++)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.spaceSm),
            child: Material(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(tokens.radiusLg),
              child: InkWell(
                key: widget.rowKey?.call(rows[index], index),
                borderRadius: BorderRadius.circular(tokens.radiusLg),
                onTap: widget.onRowTap == null
                    ? null
                    : () => widget.onRowTap!(rows[index], index),
                child: Container(
                  padding: EdgeInsets.all(tokens.spaceMd),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(tokens.radiusLg),
                    border: Border.all(
                      color: colors.outline,
                      width: tokens.borderWidth,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // First visible column acts as the card title.
                      DefaultTextStyle.merge(
                        style: Theme.of(context).textTheme.titleSmall,
                        child: shown.first.cell(context, rows[index], index),
                      ),
                      for (final column in shown.skip(1))
                        Padding(
                          padding: EdgeInsets.only(top: tokens.spaceSm),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 96,
                                child: Text(
                                  column.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ),
                              Expanded(
                                child: DefaultTextStyle.merge(
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  child: column.cell(context, rows[index], index),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (widget.trailing != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: widget.trailing!(context, rows[index], index),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.label,
    required this.sortable,
    required this.sorted,
    required this.ascending,
    required this.onTap,
  });

  final String label;
  final bool sortable;
  final bool sorted;
  final bool ascending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        if (sortable) ...[
          const SizedBox(width: 4),
          Icon(
            !sorted
                ? Icons.unfold_more
                : ascending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
            size: 14,
          ),
        ],
      ],
    );
    if (!sortable) return row;
    return InkWell(onTap: onTap, child: row);
  }
}
