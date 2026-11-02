import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Which days a [PrismCalendar] lets the user pick.
enum PrismDateSelection {
  /// One day at a time.
  single,

  /// A start and an end, inclusive.
  range,

  /// Any number of days.
  multiple,
}

/// A month-grid calendar with optional range and multi-day selection.
///
/// Built as a grid of real buttons rather than a gesture surface, because a
/// calendar is unusable by keyboard or screen reader otherwise. Each day
/// announces its full date, its selection state, and — in range mode — that it
/// is a range start, end or middle. Days outside [firstDate] and [lastDate] are
/// disabled rather than hidden, so the grid stays stable.
///
/// Deliberately dependency-free: no `intl`, so month and weekday names come from
/// [monthNames] and [weekdayLabels], both of which you can override for
/// localisation.
///
/// ```dart
/// PrismCalendar(
///   month: focusedMonth,
///   selected: selectedDays,
///   onDaySelected: (day) => setState(() => selectedDays = {day}),
///   onMonthChanged: (m) => setState(() => focusedMonth = m),
/// )
/// ```
class PrismCalendar extends StatelessWidget {
  /// Creates a calendar.
  const PrismCalendar({
    super.key,
    required this.month,
    required this.selected,
    required this.onDaySelected,
    this.onMonthChanged,
    this.selection = PrismDateSelection.single,
    this.firstDate,
    this.lastDate,
    this.today,
    this.monthNames = defaultMonthNames,
    this.weekdayLabels = defaultWeekdayLabels,
    this.firstWeekday = DateTime.monday,
    this.markers = const {},
    this.semanticLabel,
  });

  /// The month to display. Only the year and month are significant.
  final DateTime month;

  /// Currently selected days.
  final Set<DateTime> selected;

  /// Called with the day the user chose. In range mode it is called once per
  /// endpoint, with the running selection in [selected].
  final ValueChanged<DateTime> onDaySelected;

  /// Called when the user navigates to another month.
  final ValueChanged<DateTime>? onMonthChanged;

  /// How many days may be selected at once.
  final PrismDateSelection selection;

  /// Earliest selectable day. Defaults to ten years before [month].
  final DateTime? firstDate;

  /// Latest selectable day. Defaults to ten years after [month].
  final DateTime? lastDate;

  /// Overrides what counts as "today" — useful in tests.
  final DateTime? today;

  /// Month names, January first. Override for localisation.
  final List<String> monthNames;

  /// Weekday column headers, in [firstWeekday] order.
  final List<String> weekdayLabels;

  /// Which weekday starts the week.
  final int firstWeekday;

  /// Days to draw a dot under, e.g. days with events.
  final Set<DateTime> markers;

  /// Accessible name for the grid.
  final String? semanticLabel;

  /// English month names, used when [monthNames] is not supplied.
  static const List<String> defaultMonthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Short weekday labels, Monday first.
  static const List<String> defaultWeekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  /// A date-only key, so two `DateTime`s on the same day compare equal.
  static DateTime dayKey(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final scheme = Theme.of(context).colorScheme;

    final todayKey = dayKey(today ?? DateTime.now());
    final first = dayKey(firstDate ?? DateTime(month.year - 10));
    final last = dayKey(lastDate ?? DateTime(month.year + 10));
    final monthStart = DateTime(month.year, month.month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;

    // How many blank leading cells before the 1st.
    final leading = (monthStart.weekday - firstWeekday + 7) % 7;
    final orderedWeekdays = [
      for (var i = 0; i < 7; i++) weekdayLabels[(firstWeekday - 1 + i) % 7],
    ];

    final sortedSelection = selected.map(dayKey).toList()..sort();
    final rangeStart =
        selection == PrismDateSelection.range && sortedSelection.isNotEmpty
        ? sortedSelection.first
        : null;
    final rangeEnd =
        selection == PrismDateSelection.range && sortedSelection.length > 1
        ? sortedSelection.last
        : null;

    return Semantics(
      container: true,
      label: semanticLabel ?? '${monthNames[month.month - 1]} ${month.year}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            label: '${monthNames[month.month - 1]} ${month.year}',
            onPrevious: onMonthChanged == null
                ? null
                : () => onMonthChanged!(DateTime(month.year, month.month - 1)),
            onNext: onMonthChanged == null
                ? null
                : () => onMonthChanged!(DateTime(month.year, month.month + 1)),
          ),
          SizedBox(height: tokens.spaceSm),
          Row(
            children: [
              for (final label in orderedWeekdays)
                Expanded(
                  child: Semantics(
                    header: true,
                    child: ExcludeSemantics(
                      child: Center(
                        child: Text(
                          label,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: tokens.spaceXs),
          for (
            var week = 0;
            week < ((leading + daysInMonth) / 7).ceil();
            week++
          )
            Row(
              children: [
                for (var slot = 0; slot < 7; slot++)
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final dayNumber = week * 7 + slot - leading + 1;
                        if (dayNumber < 1 || dayNumber > daysInMonth) {
                          return const SizedBox(height: 44);
                        }
                        final date = DateTime(
                          month.year,
                          month.month,
                          dayNumber,
                        );
                        final disabled =
                            date.isBefore(first) || date.isAfter(last);
                        return _DayCell(
                          date: date,
                          isToday: date == todayKey,
                          disabled: disabled,
                          selected: selected.map(dayKey).contains(date),
                          rangeStart: rangeStart == date,
                          rangeEnd: rangeEnd == date,
                          inRange:
                              rangeStart != null &&
                              rangeEnd != null &&
                              date.isAfter(rangeStart) &&
                              date.isBefore(rangeEnd),
                          marked: markers.map(dayKey).contains(date),
                          onTap: disabled
                              ? null
                              : () => onDaySelected(dayKey(date)),
                          colors: colors,
                          scheme: scheme,
                          tokens: tokens,
                        );
                      },
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Semantics(
          button: true,
          label: 'Previous month',
          enabled: onPrevious != null,
          child: ExcludeSemantics(
            child: IconButton(
              onPressed: onPrevious,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
            ),
          ),
        ),
        Expanded(
          child: Semantics(
            header: true,
            child: ExcludeSemantics(
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: 'Next month',
          enabled: onNext != null,
          child: ExcludeSemantics(
            child: IconButton(
              onPressed: onNext,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
            ),
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isToday,
    required this.disabled,
    required this.selected,
    required this.rangeStart,
    required this.rangeEnd,
    required this.inRange,
    required this.marked,
    required this.onTap,
    required this.colors,
    required this.scheme,
    required this.tokens,
  });

  final DateTime date;
  final bool isToday;
  final bool disabled;
  final bool selected;
  final bool rangeStart;
  final bool rangeEnd;
  final bool inRange;
  final bool marked;
  final VoidCallback? onTap;
  final PrismColors colors;
  final ColorScheme scheme;
  final PrismTokens tokens;

  @override
  Widget build(BuildContext context) {
    final filled = selected || rangeStart || rangeEnd;
    final background = filled
        ? scheme.primary
        : inRange
        ? scheme.primaryContainer
        : null;
    final foreground = filled
        ? scheme.onPrimary
        : inRange
        ? scheme.onPrimaryContainer
        : disabled
        ? colors.outline
        : scheme.onSurface;

    // A full spoken date, so the announcement is not just "17".
    final label =
        '${date.day} '
        '${PrismCalendar.defaultMonthNames[date.month - 1]} ${date.year}'
        '${isToday ? ', today' : ''}'
        '${rangeStart ? ', range start' : ''}'
        '${rangeEnd ? ', range end' : ''}'
        '${marked ? ', has events' : ''}';

    return Semantics(
      button: true,
      selected: selected || inRange,
      enabled: !disabled,
      label: label,
      onTap: onTap,
      child: ExcludeSemantics(
        child: SizedBox(
          height: 44,
          child: Padding(
            padding: EdgeInsets.all(tokens.borderWidth),
            child: Material(
              color: background ?? Colors.transparent,
              borderRadius: BorderRadius.circular(tokens.radiusMd),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(tokens.radiusMd),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: foreground,
                        fontWeight: filled || isToday
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    if (isToday && !filled)
                      Positioned(
                        bottom: tokens.spaceXs,
                        child: Container(
                          width: tokens.spaceXs,
                          height: tokens.spaceXs,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    if (marked && !isToday)
                      Positioned(
                        bottom: tokens.spaceXs,
                        child: Container(
                          width: tokens.spaceXs,
                          height: tokens.spaceXs,
                          decoration: BoxDecoration(
                            color: foreground,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
