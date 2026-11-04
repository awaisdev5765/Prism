import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures the visual properties a Prism component actually resolved, as a
/// reviewable JSON snapshot.
///
/// ## Why not image goldens
///
/// Flutter's `matchesGoldenFile` compares rendered pixels, which differ between
/// platforms and engine versions. A golden generated on macOS fails on CI's
/// Linux runner, so the usual workarounds are to tag the tests and only run them
/// on one platform, or to tolerate a pixel difference -- both of which weaken the
/// check until it stops catching the thing you wanted it to catch.
///
/// This captures the values that make a design system a design system instead:
/// the resolved corner radii, paddings, colours, durations and text styles. Those
/// are platform-independent, they diff as readable JSON rather than as a binary
/// blob nobody reviews, and they fail for exactly the change that matters -- a
/// token default moving, or a component quietly hard-coding a value.
///
/// ## What it does not cover
///
/// **Layout geometry.** A `Row` that overflows, or a widget in the wrong place.
/// `component_matrix_test.dart` covers that by pumping every component at 320 px
/// and 1600 px and failing on any exception.
///
/// **Chrome Flutter draws itself.** A `TextField`'s border comes from
/// `InputDecorator`, which paints rather than composing `Container` or
/// `DecoratedBox`, so there is nothing for this walker to read. A component whose
/// visuals are delegated that way gets no snapshot rather than a snapshot that
/// asserts a Flutter-internal animation duration -- an assertion that would break
/// on a Flutter upgrade for reasons unrelated to Prism. `PrismForm` is in that
/// category; its behaviour is covered by `form_prism_form_test.dart`.
///
/// ## Updating
///
/// ```bash
/// PRISM_UPDATE_SNAPSHOTS=1 flutter test test/style_snapshot_test.dart
/// ```
///
/// Read the resulting diff before committing it. A snapshot updated without being
/// read is a snapshot that has stopped testing anything.
class StyleSnapshot {
  StyleSnapshot._();

  /// Whether to rewrite snapshots instead of comparing.
  static bool get updating =>
      Platform.environment['PRISM_UPDATE_SNAPSHOTS'] == '1';

  /// The key a test wraps its component in, so the snapshot covers the
  /// component rather than Flutter's own chrome.
  ///
  /// Walking from the root would fold `Scaffold`, `AppBar` and every framework
  /// default into the snapshot, which makes it large and makes it fail whenever
  /// Flutter changes an internal default -- a false alarm that has nothing to do
  /// with Prism.
  static const rootKey = ValueKey('prism-snapshot-root');

  /// Walks the widget tree under [tester]'s snapshot root and collects the visual
  /// properties Prism is responsible for.
  static Map<String, Object?> capture(WidgetTester tester) {
    final entries = <String, List<Object?>>{};

    void record(String kind, Object? value) {
      if (value == null) return;
      entries.putIfAbsent(kind, () => <Object?>[]).add(value);
    }

    void recordDecoration(Decoration? decoration) {
      if (decoration is! BoxDecoration) return;
      final radius = decoration.borderRadius;
      if (radius is BorderRadius) record('radius', _radius(radius));
      if (decoration.color != null) record('fill', _colour(decoration.color!));
      if (decoration.border != null) {
        final border = decoration.border! as Border;
        record('border', {
          'width': border.top.width,
          'color': _colour(border.top.color),
        });
      }
    }

    void visit(Element element) {
      final widget = element.widget;

      switch (widget) {
        case Container(:final decoration, :final padding):
          recordDecoration(decoration);
          if (padding != null) record('padding', _insets(padding));
        case DecoratedBox(:final decoration):
          // Covers surfaces Prism draws through DecoratedBox rather than
          // Container, which is the shape several components use.
          recordDecoration(decoration);
        case Padding(:final padding):
          record('padding', _insets(padding));
        case AnimatedContainer(:final duration, :final decoration):
          record('motion', duration.inMilliseconds);
          recordDecoration(decoration);
        case AnimatedSwitcher(:final duration):
          record('motion', duration.inMilliseconds);
        case AnimatedSize(:final duration):
          record('motion', duration.inMilliseconds);
        case AnimatedOpacity(:final duration):
          record('motion', duration.inMilliseconds);
        case Icon(:final size, :final color):
          record('icon', {'size': size, 'color': _colour(color)});
        case Text(:final style):
          if (style != null) record('text', _textStyle(style));
        case Material(:final borderRadius, :final color):
          if (borderRadius is BorderRadius) {
            record('radius', _radius(borderRadius));
          }
          if (color != null) record('fill', _colour(color));
        case SizedBox(:final height, :final width):
          if (height != null || width != null) {
            record('box', {'w': width, 'h': height});
          }
      }

      element.visitChildren(visit);
    }

    final root = find.byKey(rootKey).evaluate().first;
    root.visitChildren(visit);

    // Sort every bucket and de-duplicate, so the snapshot records which values
    // the component resolved rather than the order it built them in.
    final stable = <String, Object?>{};
    for (final key in entries.keys.toList()..sort()) {
      final values = entries[key]!
          .map((v) => jsonEncode(v))
          .toSet()
          .toList()
        ..sort();
      stable[key] = values.map(jsonDecode).toList();
    }
    return stable;
  }

  /// Compares [capture] against `test/snapshots/[name].json`.
  ///
  /// Creates the file on first run, and rewrites it when [updating] is set.
  static void expectMatches(
    WidgetTester tester,
    String name, {
    Set<String> ignore = const {},
  }) {
    final actual = capture(tester)..removeWhere((k, _) => ignore.contains(k));
    final file = File('test/snapshots/$name.json');
    final encoded = const JsonEncoder.withIndent('  ').convert(actual);

    if (updating || !file.existsSync()) {
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('$encoded\n');
      // ignore: avoid_print
      print('${file.existsSync() ? 'updated' : 'created'} ${file.path}');
      return;
    }

    final expected = file.readAsStringSync().trimRight();
    if (encoded == expected) return;

    // Print what changed rather than two JSON blobs. A failure that says
    // "radiusMd 12 -> 14" is a fix; one that dumps 800 characters of snapshot is
    // a scroll hunt.
    expect(
      _describeChanges(expected, encoded),
      isEmpty,
      reason:
          'The resolved style of $name changed. If that was intended, re-run '
          'with PRISM_UPDATE_SNAPSHOTS=1 and read the diff before committing it.',
    );
  }

  /// A line-per-change description of how two snapshots differ.
  static List<String> _describeChanges(String expected, String actual) {
    final before = jsonDecode(expected) as Map<String, Object?>;
    final after = jsonDecode(actual) as Map<String, Object?>;
    final changes = <String>[];

    for (final key in {...before.keys, ...after.keys}.toList()..sort()) {
      final was = before[key];
      final now = after[key];
      if (jsonEncode(was) == jsonEncode(now)) continue;
      if (was == null) {
        changes.add('+ $key: ${jsonEncode(now)}');
      } else if (now == null) {
        changes.add('- $key: ${jsonEncode(was)}');
      } else {
        changes.add('~ $key:\n    was ${jsonEncode(was)}\n    now ${jsonEncode(now)}');
      }
    }
    return changes;
  }

  static Map<String, Object?> _radius(BorderRadius radius) => {
        'tl': radius.topLeft.x,
        'tr': radius.topRight.x,
        'bl': radius.bottomLeft.x,
        'br': radius.bottomRight.x,
      };

  static Map<String, Object?> _insets(EdgeInsetsGeometry insets) => {
        'l': insets.resolve(TextDirection.ltr).left,
        't': insets.resolve(TextDirection.ltr).top,
        'r': insets.resolve(TextDirection.ltr).right,
        'b': insets.resolve(TextDirection.ltr).bottom,
      };

  /// Colours are recorded as ARGB integers, which diff as a readable hex value
  /// and cannot be confused by `Color`'s float channels.
  static String _colour(Color? colour) {
    if (colour == null) return 'none';
    return '#${colour.toARGB32().toRadixString(16).padLeft(8, '0')}';
  }

  static Map<String, Object?> _textStyle(TextStyle style) => {
        'size': style.fontSize,
        'weight': style.fontWeight?.value,
        'color': _colour(style.color),
        'height': style.height,
      };
}
