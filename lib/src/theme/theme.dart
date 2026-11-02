/// The Prism design system: shared tokens and semantic colors.
///
/// Prism components work out of the box with zero configuration. Register
/// [PrismTokens] to align every component on screen with your own spacing,
/// radii and motion language:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     colorSchemeSeed: Colors.teal,
///     extensions: const [
///       PrismTokens(spaceMd: 20, radiusMd: 16),
///     ],
///   ),
/// )
/// ```
///
/// Then read them with the context extension:
///
/// ```dart
/// Padding(padding: EdgeInsets.all(context.prismTokens.spaceMd), child: …)
/// Container(color: context.prismColors.surfaceRaised)
/// ```
///
/// Both accessors are null-safe and fall back to Prism defaults, so a
/// half-configured app never crashes and never looks broken.
library;

export 'colors.dart';
export 'motion.dart';
export 'presets.dart';
export 'tokens.dart';
