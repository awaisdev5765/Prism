import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A small count or status pill that sits on top of another widget.
///
/// Counts above [maxCount] collapse to `99+`, a zero count hides the badge
/// entirely (the common "no unread items" case), and the result is announced as
/// part of its parent rather than as a stray number.
///
/// ```dart
/// PrismBadge(
///   count: unread,
///   child: Icon(Icons.notifications_outlined),
/// )
///
/// PrismBadge.dot(semantic: PrismSemantic.error, child: Avatar())
/// ```
class PrismBadge extends StatelessWidget {
  /// Creates a count badge.
  const PrismBadge({
    super.key,
    required this.child,
    this.count = 0,
    this.maxCount = 99,
    this.semantic = PrismSemantic.error,
    this.showZero = false,
    this.alignment = Alignment.topRight,
    this.offset,
    this.label,
  }) : _isDot = false;

  /// Creates a small status dot with no count.
  const PrismBadge.dot({
    super.key,
    required this.child,
    this.semantic = PrismSemantic.error,
    this.alignment = Alignment.topRight,
    this.offset,
    this.label,
  }) : count = 0,
       maxCount = 99,
       showZero = false,
       _isDot = true;

  /// The widget the badge is attached to.
  final Widget child;

  /// The number to display. Ignored by [PrismBadge.dot].
  final int count;

  /// Counts above this render as `maxCount+`.
  final int maxCount;

  /// Which semantic role colours the badge.
  final PrismSemantic semantic;

  /// Whether a count of zero still renders. Defaults to hiding it.
  final bool showZero;

  /// Where the badge sits relative to [child].
  final Alignment alignment;

  /// Extra offset applied to the badge.
  final Offset? offset;

  /// Accessibility label. Defaults to `"<count> new"`, or the semantic role
  /// name for a dot.
  final String? label;

  /// Whether this instance renders a dot instead of a count.
  final bool _isDot;

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;
    final role = colors.forRole(semantic);
    final accent = colors.accentForRole(semantic);
    final show = _isDot || showZero || count > 0;
    final semanticLabel = label ?? (_isDot ? semantic.name : '$count new');

    return Semantics(
      container: true,
      label: show ? semanticLabel : null,
      child: ExcludeSemantics(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            child,
            if (show)
              Positioned(
                right: offset?.dx ?? 0,
                top: offset?.dy ?? 0,
                child: Align(
                  alignment: alignment,
                  child: _isDot
                      ? Container(
                          width: tokens.spaceSm,
                          height: tokens.spaceSm,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).colorScheme.surface,
                              width: tokens.borderWidth,
                            ),
                          ),
                        )
                      : Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: tokens.spaceXs + 2,
                            vertical: 1,
                          ),
                          constraints: BoxConstraints(
                            minWidth: tokens.spaceMd,
                            minHeight: tokens.spaceMd,
                          ),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(
                              tokens.radiusXl,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            count > maxCount ? '$maxCount+' : '$count',
                            textScaler: TextScaler.noScaling,
                            style: TextStyle(
                              color: role.foreground,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
