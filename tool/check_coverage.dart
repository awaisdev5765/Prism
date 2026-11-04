// Checks test coverage against a threshold, from an lcov report.
//
//   dart run tool/check_coverage.dart coverage/lcov.info --min 88
//
// Prints the total, the lowest-covered files, and fails when the total drops
// below the threshold. Prints the weak spots even when it passes, because a
// number on its own does not tell you where to look.
//
// Deliberately dependency-free and Flutter-free, so plain `dart run` works. A
// script that imported Flutter could not run outside the engine, which is how the
// token export ended up test-driven instead.

import 'dart:io';

/// Coverage for one source file.
class FileCoverage {
  /// Creates a coverage record.
  FileCoverage(this.path);

  /// The file this record describes, as written in the lcov report.
  final String path;

  /// Lines that were executed.
  int hit = 0;

  /// Lines that could be executed.
  int found = 0;

  /// Percentage covered, treating a file with no executable lines as complete.
  double get percent => found == 0 ? 100 : hit / found * 100;
}

/// Parses an lcov report.
Map<String, FileCoverage> parseLcov(String contents) {
  final files = <String, FileCoverage>{};
  FileCoverage? current;

  for (final line in contents.split('\n')) {
    if (line.startsWith('SF:')) {
      current = files.putIfAbsent(line.substring(3).trim(), () {
        return FileCoverage(line.substring(3).trim());
      });
    } else if (line.startsWith('LF:') && current != null) {
      current.found = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('LH:') && current != null) {
      current.hit = int.tryParse(line.substring(3).trim()) ?? 0;
    }
  }
  return files;
}

void main(List<String> arguments) {
  final positional = arguments.where((a) => !a.startsWith('--')).toList();
  final minIndex = arguments.indexOf('--min');
  final minimum = minIndex >= 0 && minIndex + 1 < arguments.length
      ? double.tryParse(arguments[minIndex + 1]) ?? 0
      : 0.0;

  final path = positional.isEmpty ? 'coverage/lcov.info' : positional.first;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln(
      'No coverage report at $path.\n'
      'Run: flutter test --coverage',
    );
    exit(2);
  }

  final all = parseLcov(file.readAsStringSync());
  // Only the package's own source counts. Generated files and the test helpers
  // would otherwise flatter or depress the number.
  final lib = {
    for (final entry in all.entries)
      if (entry.key.startsWith('lib/')) entry.key: entry.value,
  };

  if (lib.isEmpty) {
    stderr.writeln('No lib/ entries in $path. Is the report from this package?');
    exit(2);
  }

  final hit = lib.values.fold(0, (sum, f) => sum + f.hit);
  final found = lib.values.fold(0, (sum, f) => sum + f.found);
  final total = found == 0 ? 100.0 : hit / found * 100;

  stdout.writeln('Coverage: ${total.toStringAsFixed(1)}% ($hit/$found lines)');
  stdout.writeln('Files: ${lib.length}');

  final ranked = lib.values.toList()..sort((a, b) => a.percent.compareTo(b.percent));
  final weak = ranked.take(8).where((f) => f.percent < 80).toList();
  if (weak.isNotEmpty) {
    stdout.writeln('Lowest covered, worth a look:');
    for (final entry in weak) {
      stdout.writeln(
        '  ${entry.percent.toStringAsFixed(1).padLeft(5)}%  '
        '${entry.found.toString().padLeft(4)} lines  ${entry.path}',
      );
    }
  }

  if (minimum > 0 && total < minimum) {
    stderr.writeln(
      '\nCoverage ${total.toStringAsFixed(1)}% is below the '
      '${minimum.toStringAsFixed(1)}% threshold.',
    );
    exit(1);
  }
}
