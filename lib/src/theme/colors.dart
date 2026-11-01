import 'package:flutter/material.dart';

/// The semantic roles Prism components speak in.
///
/// Rather than hard-coding colors, components ask for a role and the theme
/// decides what that means in light mode, dark mode and dynamic color.
enum PrismSemantic {
  /// Something succeeded.
  success,

  /// Something needs attention but is not fatal.
  warning,

  /// Something failed.
  error,

  /// Neutral, informational.
  info,
}

/// Semantic colors derived from the active [ColorScheme].
///
/// Prism components need more meaning than a raw [ColorScheme] provides —
/// "what color is a success state?", "what surface does a toast sit on?".
/// [PrismColors] answers those once, consistently, and adapts automatically
/// to light/dark mode and Material You dynamic color.
///
/// ```dart
/// final colors = PrismColors.of(context);
/// Container(color: colors.forRole(PrismSemantic.success).background);
/// ```
@immutable
class PrismColors {
  /// Creates a semantic color set. Prefer [of] so values track the theme.
  const PrismColors({
    required this.success,
    required this.onSuccess,
    required this.successContainer,
    required this.onSuccessContainer,
    required this.warning,
    required this.onWarning,
    required this.warningContainer,
    required this.onWarningContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.info,
    required this.onInfo,
    required this.infoContainer,
    required this.onInfoContainer,
    required this.surfaceRaised,
    required this.surfaceSunken,
    required this.outline,
    required this.overlay,
  });

  /// Positive/success accent.
  final Color success;

  /// Content color on [success].
  final Color onSuccess;

  /// Success container background.
  final Color successContainer;

  /// Content color on [successContainer].
  final Color onSuccessContainer;

  /// Caution/warning accent.
  final Color warning;

  /// Content color on [warning].
  final Color onWarning;

  /// Warning container background.
  final Color warningContainer;

  /// Content color on [warningContainer].
  final Color onWarningContainer;

  /// Failure accent.
  final Color error;

  /// Content color on [error].
  final Color onError;

  /// Error container background.
  final Color errorContainer;

  /// Content color on [errorContainer].
  final Color onErrorContainer;

  /// Neutral information accent.
  final Color info;

  /// Content color on [info].
  final Color onInfo;

  /// Info container background.
  final Color infoContainer;

  /// Content color on [infoContainer].
  final Color onInfoContainer;

  /// A surface one step above the base surface — cards, banners, sheets.
  final Color surfaceRaised;

  /// A surface one step below the base surface — wells, code blocks.
  final Color surfaceSunken;

  /// Hairline border color.
  final Color outline;

  /// Scrim/tint color for overlays over imagery.
  final Color overlay;

  /// Background/foreground pair for a semantic [role].
  ({Color background, Color foreground}) forRole(PrismSemantic role) {
    switch (role) {
      case PrismSemantic.success:
        return (background: successContainer, foreground: onSuccessContainer);
      case PrismSemantic.warning:
        return (background: warningContainer, foreground: onWarningContainer);
      case PrismSemantic.error:
        return (background: errorContainer, foreground: onErrorContainer);
      case PrismSemantic.info:
        return (background: infoContainer, foreground: onInfoContainer);
    }
  }

  /// Solid accent color for a semantic [role] — use when a filled chip,
  /// dot or badge needs to stand out against the base surface.
  Color accentForRole(PrismSemantic role) {
    switch (role) {
      case PrismSemantic.success:
        return success;
      case PrismSemantic.warning:
        return warning;
      case PrismSemantic.error:
        return error;
      case PrismSemantic.info:
        return info;
    }
  }

  /// The icon conventionally paired with a semantic [role].
  IconData iconForRole(PrismSemantic role) {
    switch (role) {
      case PrismSemantic.success:
        return Icons.check_circle_outline;
      case PrismSemantic.warning:
        return Icons.warning_amber_outlined;
      case PrismSemantic.error:
        return Icons.error_outline;
      case PrismSemantic.info:
        return Icons.info_outline;
    }
  }

  /// Derives semantic colors from the ambient [ThemeData].
  ///
  /// Uses the Material 3 tonal palettes where available, so values stay
  /// legible in both light and dark mode and follow dynamic color.
  static PrismColors of(BuildContext context) =>
      resolve(Theme.of(context).colorScheme, Theme.of(context).brightness);

  /// Derives semantic colors from an explicit scheme and brightness —
  /// useful when you have a theme but no [BuildContext].
  static PrismColors resolve(ColorScheme scheme, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // A hand-tuned green keeps "success" distinct from the primary hue,
    // which is often blue or purple in Material You.
    final success = isDark ? const Color(0xFF7BD8A8) : const Color(0xFF1B7A4B);
    final successContainer =
        isDark ? const Color(0xFF1E4C33) : const Color(0xFFC9F2DC);
    final onSuccessContainer =
        isDark ? const Color(0xFFC9F2DC) : const Color(0xFF06301A);

    // Warning leans amber, again to stay distinct from `tertiary`.
    final warning = isDark ? const Color(0xFFFFCF6B) : const Color(0xFF8A5A00);
    final warningContainer =
        isDark ? const Color(0xFF54401A) : const Color(0xFFFFE7B8);
    final onWarningContainer =
        isDark ? const Color(0xFFFFE7B8) : const Color(0xFF2E1F00);

    return PrismColors(
      success: success,
      onSuccess: isDark ? const Color(0xFF00391F) : Colors.white,
      successContainer: successContainer,
      onSuccessContainer: onSuccessContainer,
      warning: warning,
      onWarning: isDark ? const Color(0xFF3D2C00) : Colors.white,
      warningContainer: warningContainer,
      onWarningContainer: onWarningContainer,
      error: scheme.error,
      onError: scheme.onError,
      errorContainer: scheme.errorContainer,
      onErrorContainer: scheme.onErrorContainer,
      info: scheme.primary,
      onInfo: scheme.onPrimary,
      infoContainer: scheme.primaryContainer,
      onInfoContainer: scheme.onPrimaryContainer,
      surfaceRaised: scheme.surfaceContainerLow,
      surfaceSunken: scheme.surfaceContainerHighest,
      outline: scheme.outlineVariant,
      overlay: scheme.scrim.withValues(alpha: 0.32),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PrismColors &&
          other.success == success &&
          other.onSuccess == onSuccess &&
          other.successContainer == successContainer &&
          other.onSuccessContainer == onSuccessContainer &&
          other.warning == warning &&
          other.onWarning == onWarning &&
          other.warningContainer == warningContainer &&
          other.onWarningContainer == onWarningContainer &&
          other.error == error &&
          other.onError == onError &&
          other.errorContainer == errorContainer &&
          other.onErrorContainer == onErrorContainer &&
          other.info == info &&
          other.onInfo == onInfo &&
          other.infoContainer == infoContainer &&
          other.onInfoContainer == onInfoContainer &&
          other.surfaceRaised == surfaceRaised &&
          other.surfaceSunken == surfaceSunken &&
          other.outline == outline &&
          other.overlay == overlay;

  @override
  int get hashCode => Object.hashAll([
        success,
        onSuccess,
        successContainer,
        onSuccessContainer,
        warning,
        onWarning,
        warningContainer,
        onWarningContainer,
        error,
        onError,
        errorContainer,
        onErrorContainer,
        info,
        onInfo,
        infoContainer,
        onInfoContainer,
        surfaceRaised,
        surfaceSunken,
        outline,
        overlay,
      ]);
}
