import 'dart:convert';

import 'package:flutter/services.dart';

/// Parses a Lottie JSON file and reports the metadata needed to size and play
/// it.
///
/// Lottie animations are JSON files that describe vector shapes and keyframes.
/// This class reads the file, extracts the frame rate, duration, dimensions and
/// layer count, and reports whether the animation loops.
///
/// Prism deliberately does not include a Lottie *renderer*. Drawing Lottie
/// compositions requires a physics engine, a text renderer, and a gradient and
/// mask implementation — a large dependency for a component library. Instead,
/// use `lottie` or `flutter_lottie` for rendering, and this class for
/// everything else: preload, size calculation, and knowing when an animation
/// has finished.
///
/// ```dart
/// final animation = await PrismLottie.fromAsset('animations/empty.json');
/// print('${animation.width} x ${animation.height}');
/// print('duration: ${animation.duration}');
/// ```
class PrismLottie {
  /// Creates a Lottie animation from parsed JSON.
  const PrismLottie({
    required this.width,
    required this.height,
    required this.frameRate,
    required this.frameCount,
    required this.loop,
    required this.layers,
    required this.version,
  });

  /// Parses a Lottie JSON string.
  factory PrismLottie.fromJson(String json) {
    final decoded = jsonDecode(json) as Map<String, dynamic>;
    return PrismLottie(
      width: (decoded['w'] as num?)?.toDouble() ?? 0,
      height: (decoded['h'] as num?)?.toDouble() ?? 0,
      frameRate: (decoded['fr'] as num?)?.toDouble() ?? 30,
      frameCount: (decoded['op'] as num?)?.toInt() ?? 0,
      loop: decoded['loop'] as bool? ?? false,
      layers: (decoded['layers'] as List?)?.length ?? 0,
      version: decoded['v'] as String? ?? '',
    );
  }

  /// Loads a Lottie animation from an asset path.
  static Future<PrismLottie> fromAsset(String path) async {
    final json = await rootBundle.loadString(path);
    return PrismLottie.fromJson(json);
  }

  /// Animation width in logical pixels.
  final double width;

  /// Animation height in logical pixels.
  final double height;

  /// Frame rate in frames per second.
  final double frameRate;

  /// Total number of frames in the animation.
  final int frameCount;

  /// Whether the animation loops.
  final bool loop;

  /// Number of layers in the composition.
  final int layers;

  /// Lottie schema version the file was exported with.
  final String version;

  /// Duration of one full playthrough.
  Duration get duration => frameRate <= 0
      ? Duration.zero
      : Duration(milliseconds: (frameCount / frameRate * 1000).round());

  /// Aspect ratio, which is useful for sizing a box around the animation.
  double get aspectRatio => height == 0 ? 1 : width / height;

  @override
  String toString() =>
      'PrismLottie($width x $height, $frameCount frames @ $frameRate fps)';
}

/// Preloads Lottie animations from an asset directory.
///
/// Useful for a splash screen or an onboarding flow, where you want to have the
/// animations ready before the screen is shown.
///
/// ```dart
/// final preloaded = await PrismLottieCache.preload([
///   'animations/success.json',
///   'animations/error.json',
/// ]);
/// final success = preloaded['animations/success.json'];
/// ```
class PrismLottieCache {
  /// Creates a cache.
  PrismLottieCache();

  final Map<String, PrismLottie> _cache = {};

  /// Loads and caches each animation.
  Future<Map<String, PrismLottie>> preload(List<String> paths) async {
    for (final path in paths) {
      if (_cache.containsKey(path)) continue;
      final json = await rootBundle.loadString(path);
      _cache[path] = PrismLottie.fromJson(json);
    }
    return Map.unmodifiable(_cache);
  }

  /// A previously loaded animation, or null.
  PrismLottie? operator [](String path) => _cache[path];

  /// Removes an animation from the cache.
  void evict(String path) => _cache.remove(path);
}
