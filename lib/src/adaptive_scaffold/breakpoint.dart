import 'package:flutter/material.dart';

/// A set of well-known width thresholds that map screen sizes to semantic
/// window classes.
///
/// Mirrors Material Design 3's canonical breakpoints so apps feel native on
/// every device class. A breakpoint value is the *minimum* width required to
/// reach that class.
@immutable
class PrismBreakpoint {
  /// Creates a breakpoint at [minWidth].
  const PrismBreakpoint(this.minWidth);

  /// The minimum viewport width (logical pixels) for this window class.
  final double minWidth;

  /// Compact window: phones in portrait. Width below 600.
  static const PrismBreakpoint compact = PrismBreakpoint(0);

  /// Medium window: phones in landscape, small tablets. Width 600–839.
  static const PrismBreakpoint medium = PrismBreakpoint(600);

  /// Expanded window: tablets, laptops, desktops. Width 840–1199.
  static const PrismBreakpoint expanded = PrismBreakpoint(840);

  /// Extra-large window: large desktops, foldables opened. Width 1200+.
  static const PrismBreakpoint extraLarge = PrismBreakpoint(1200);

  /// All built-in breakpoints in ascending order.
  static const List<PrismBreakpoint> all = [
    compact,
    medium,
    expanded,
    extraLarge,
  ];

  /// Resolves which built-in class [width] falls into.
  static PrismBreakpoint resolve(double width) {
    if (width >= extraLarge.minWidth) return extraLarge;
    if (width >= expanded.minWidth) return expanded;
    if (width >= medium.minWidth) return medium;
    return compact;
  }

  /// Returns true if this breakpoint is exactly [other].
  bool isSameClass(PrismBreakpoint other) => minWidth == other.minWidth;

  @override
  bool operator ==(Object other) =>
      other is PrismBreakpoint && other.minWidth == minWidth;

  @override
  int get hashCode => minWidth.hashCode;

  @override
  String toString() {
    if (minWidth == 0) return 'compact';
    if (minWidth == 600) return 'medium';
    if (minWidth == 840) return 'expanded';
    if (minWidth == 1200) return 'extraLarge';
    return 'PrismBreakpoint($minWidth)';
  }
}
