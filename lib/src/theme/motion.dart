import 'package:flutter/material.dart';

/// Motion that respects the user's accessibility settings.
///
/// Roughly one in three people who enable "reduce motion" do so because
/// animation causes them dizziness, nausea or migraine. A component library
/// that ignores that setting is unusable for them, so every animated Prism
/// component asks for its duration through here rather than reading it straight
/// from the theme.
///
/// ```dart
/// AnimatedSwitcher(
///   duration: context.prismMotion(tokens.durationMedium),
///   child: child,
/// );
/// ```
extension PrismMotionContext on BuildContext {
  /// Returns [preferred], or [Duration.zero] when the platform asks for reduced
  /// motion.
  ///
  /// Read this instead of `MediaQuery.disableAnimationsOf` directly: it also
  /// handles the "no MediaQuery above me" case, which happens in tests and in
  /// widgets rendered outside a `MaterialApp`.
  Duration prismMotion(Duration preferred) =>
      MediaQuery.maybeDisableAnimationsOf(this) ?? false
      ? Duration.zero
      : preferred;

  /// Whether the platform currently asks for reduced motion.
  bool get prismReduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(this) ?? false;
}
