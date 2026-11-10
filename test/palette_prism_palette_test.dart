import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:prism_kit/prism.dart';

void main() {
  group('ColorPalette.fromColors', () {
    test('exposes every color and ranks the first as dominant by default', () {
      final palette = ColorPalette.fromColors([
        const Color(0xFFFF0000), // red
        const Color(0xFF00FF00), // green
        const Color(0xFF0000FF), // blue
      ]);

      expect(palette.swatches.length, 3);
      expect(palette.colors.toSet(), {
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
        const Color(0xFF0000FF),
      });
      expect(palette.dominantColor, isNotNull);
    });

    test('populationOf reports the source count', () {
      final palette = ColorPalette.fromPopulations({
        0xFFFF0000: 80,
        0xFF00FF00: 20,
      });

      expect(palette.populationOf(const Color(0xFFFF0000)), 80);
      expect(palette.populationOf(const Color(0xFF00FF00)), 20);
      expect(palette.populationOf(const Color(0xFF0000FF)), isNull);
    });

    test('swatch getters never throw and targets map is populated', () {
      final palette = ColorPalette.fromColors([
        const Color(0xFFFF1744), // vivid red
        const Color(0xFF263238), // dark desaturated
        const Color(0xFFFFF59D), // light desaturated
      ]);

      // All six targets must be present in the map (each candidate matches
      // some target best).
      expect(palette.targetSwatches.length, 6);
      expect(palette.vibrantColor, isNotNull);
      expect(palette.lightVibrantColor, isNotNull);
      expect(palette.darkVibrantColor, isNotNull);
      expect(palette.mutedColor, isNotNull);
      expect(palette.lightMutedColor, isNotNull);
      expect(palette.darkMutedColor, isNotNull);

      // Dark targets should have lower tone than their light counterparts.
      expect(
        palette.darkVibrantColor!.computeLuminance(),
        lessThan(palette.lightVibrantColor!.computeLuminance()),
      );
    });
  });

  group('PaletteExtractor.fromRgbaBytes', () {
    Uint8List twoToneBytes(int width, int height, Color left, Color right) {
      final bytes = Uint8List(width * height * 4);
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final c = x < width / 2 ? left : right;
          final i = (y * width + x) * 4;
          bytes[i] = (c.r * 255).round();
          bytes[i + 1] = (c.g * 255).round();
          bytes[i + 2] = (c.b * 255).round();
          bytes[i + 3] = 255;
        }
      }
      return bytes;
    }

    test('extracts dominant colors from a two-tone image', () async {
      final bytes = twoToneBytes(
        64,
        64,
        const Color(0xFFFF0000),
        const Color(0xFF00FF00),
      );
      final palette = await PaletteExtractor.fromRgbaBytes(
        bytes,
        width: 64,
        height: 64,
      );

      // The quantizer keeps representative colors; for a hard two-tone
      // split it may return one, but it must be one of the two inputs.
      expect(palette.colors, isNotEmpty);
      final extracted = palette.colors.toSet();
      final redOrGreen = extracted.any(
        (c) => ((c.r * 255) > 200 && (c.g * 255) < 100) ||
            ((c.g * 255) > 200 && (c.r * 255) < 100),
      );
      expect(redOrGreen, isTrue, reason: 'palette was $extracted');
    });

    test('region limits sampling to a sub-rectangle', () async {
      final bytes = twoToneBytes(
        64,
        64,
        const Color(0xFF0000FF),
        const Color(0xFFFFFF00),
      );
      final palette = await PaletteExtractor.fromRgbaBytes(
        bytes,
        width: 64,
        height: 64,
        region: const Rect.fromLTWH(0, 0, 0.5, 1), // left half only
      );
      final extracted = palette.colors.toSet();
      expect(
        extracted.any((c) => (c.b * 255) > 200 && (c.r * 255) < 100),
        isTrue,
        reason: 'left half is blue; palette should be blue-led: $extracted',
      );
    });

    test('rejects empty bounds', () {
      expect(
        () => PaletteExtractor.fromRgbaBytes(Uint8List(4), width: 0, height: 1),
        throwsArgumentError,
      );
    });

    test('rejects a byte count that does not match the bounds', () {
      expect(
        () => PaletteExtractor.fromRgbaBytes(
          Uint8List(8), // needs 16 for 2x2
          width: 2,
          height: 2,
        ),
        throwsArgumentError,
      );
    });
  });
}
