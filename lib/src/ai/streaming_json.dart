import 'dart:convert';

/// Parses partial JSON output from a streaming AI response.
class StreamingJsonParser {
  StreamingJsonParser();
  final StringBuffer _buffer = StringBuffer();

  void consume(String chunk) => _buffer.write(chunk);

  /// Returns all top-level string values, even if the JSON is incomplete.
  Map<String, String> get fields {
    final s = _buffer.toString();
    final result = <String, String>{};
    var depth = 0;
    var inStr = false;
    var esc = false;
    var key = '';
    var value = '';
    var readingKey = false;
    var readingValue = false;
    var keyDone = false;
    var valueStarted = false;

    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (esc) { esc = false; if (readingKey) key += c; if (readingValue) value += c; continue; }
      if (inStr) {
        if (c == r'\') { esc = true; continue; }
        if (c == '"') {
          inStr = false;
          if (readingKey) { readingKey = false; keyDone = true; }
          else if (readingValue) { readingValue = false; valueStarted = true; result[key] = value; }
          continue;
        }
        if (readingKey) key += c;
        if (readingValue) value += c;
        continue;
      }
      // Not in string
      if (c == '"') {
        inStr = true;
        if (!keyDone && !readingValue) { readingKey = true; key = ''; }
        else if (keyDone && !readingValue && !valueStarted) { readingValue = true; value = ''; }
        continue;
      }
      if (c == ':') { continue; }
      if (c == ',') {
        if (!inStr) { key = ''; value = ''; keyDone = false; readingValue = false; valueStarted = false; }
        continue;
      }
      if (c == '{') { depth++; continue; }
      if (c == '}') { depth--; continue; }
      // Skip digits and other chars
    }
    return result;
  }

  bool get isComplete {
    final s = _buffer.toString();
    var depth = 0; var inStr = false; var esc = false;
    for (var i = 0; i < s.length; i++) {
      final c = s[i];
      if (esc) { esc = false; continue; }
      if (inStr) { if (c == r'\') esc = true; if (c == '"') inStr = false; continue; }
      if (c == '"') { inStr = true; continue; }
      if (c == '{') depth++;
      if (c == '}') depth--;
    }
    return depth == 0 && !inStr;
  }

  Map<String, Object?>? complete() {
    if (!isComplete) return null;
    try {
      final decoded = jsonDecode(_buffer.toString());
      return decoded is Map<String, Object?> ? decoded : null;
    } on FormatException { return null; }
  }

  void reset() => _buffer.clear();
}
