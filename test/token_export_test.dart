import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

import 'support/token_export.dart';

/// `tokens.json` exists so a designer or a stylesheet can read the same numbers
/// the components use. That only helps if it is current, so this test fails when
/// it drifts — otherwise it becomes a second source of truth, which is the
/// problem it was meant to solve.
void main() {
  group('tokens.json matches the package', () {
    test('the committed file is up to date', () {
      final file = File('tokens.json');
      final generated = encodeTokenExport();

      if (Platform.environment['PRISM_UPDATE_TOKENS'] == '1' ||
          !file.existsSync()) {
        file.writeAsStringSync(generated);
        // ignore: avoid_print
        print('wrote ${file.path}');
        return;
      }

      final committed = file.readAsStringSync();

      if (committed != generated) {
        // Show which section moved rather than two blobs of JSON.
        final before = jsonDecode(committed) as Map<String, Object?>;
        final after = jsonDecode(generated) as Map<String, Object?>;
        final changed = <String>[];
        for (final key in {...before.keys, ...after.keys}) {
          if (jsonEncode(before[key]) != jsonEncode(after[key])) {
            changed.add(key);
          }
        }
        fail(
          'tokens.json is out of date in: ${changed.join(', ')}.\n'
          'Run: PRISM_UPDATE_TOKENS=1 flutter test test/token_export_test.dart',
        );
      }
    });
  });

  group('the export is faithful to the source', () {
    test('spacing, radii and motion come from PrismTokens.fallback', () {
      final export = buildTokenExport();
      final spacing = export['spacing']! as Map<String, Object?>;
      final radius = export['radius']! as Map<String, Object?>;
      final motion = export['motion']! as Map<String, Object?>;

      expect(spacing['spaceMd'], PrismTokens.fallback.spaceMd);
      expect(radius['radiusMd'], PrismTokens.fallback.radiusMd);
      expect(
        motion['durationMedium'],
        PrismTokens.fallback.durationMedium.inMilliseconds,
      );
      expect(export['controlHeight'], PrismTokens.fallback.controlHeight);
    });

    test('every semantic role is exported for both brightnesses', () {
      final export = buildTokenExport();
      final semantic = export['semantic']! as Map<String, Object?>;
      for (final brightness in ['light', 'dark']) {
        final roles = semantic[brightness]! as Map<String, Object?>;
        for (final role in PrismSemantic.values) {
          expect(roles.keys, contains(role.name));
        }
      }
    });

    test('success and warning do not depend on the seed', () {
      // They are fixed precisely so they cannot collapse into a brand colour, so
      // the export must show the same values for any seed.
      final export = buildTokenExport();
      final semantic = export['semantic']! as Map<String, Object?>;
      final light = semantic['light']! as Map<String, Object?>;
      expect(
        (light['success']! as Map<String, Object?>)['accent'],
        '#FF1B7A4B',
      );
      expect(
        (light['warning']! as Map<String, Object?>)['accent'],
        '#FF8A5A00',
      );
    });

    test('colours are hex strings a stylesheet can use', () {
      final export = buildTokenExport();
      final semantic = export['semantic']! as Map<String, Object?>;
      final light = semantic['light']! as Map<String, Object?>;

      for (final role in light.values) {
        for (final value in (role as Map<String, Object?>).values) {
          expect(
            value,
            matches(RegExp(r'^#[0-9A-F]{8}$')),
            reason: 'expected an ARGB hex string, got $value',
          );
        }
      }
    });
  });
}
