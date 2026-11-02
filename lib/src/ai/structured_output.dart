import 'dart:convert';

/// Pulling structured data out of a language model's reply.
///
/// Models rarely return bare JSON. They wrap it in a ``` fence, prefix it with
/// "Here is the JSON you asked for:", or trail a closing remark. Naively calling
/// `jsonDecode` on the response fails for all three, which is why this exists.
///
/// ```dart
/// final data = PrismStructuredOutput.extractMap(reply);
/// print(data?['sentiment']);
/// ```
///
/// This is deliberately dependency-free and forgiving. It never throws: a
/// malformed response yields null, and callers decide whether to retry.
abstract final class PrismStructuredOutput {
  /// Extracts the first JSON object or array from [text].
  ///
  /// Handles fenced blocks (```` ```json ```` or ```` ``` ````), leading and
  /// trailing prose, and nested braces inside strings. Returns null when no
  /// valid JSON is present.
  static Object? extract(String text) {
    for (final candidate in _candidates(text)) {
      final decoded = _tryDecode(candidate);
      if (decoded != null) return decoded;
    }
    return null;
  }

  /// Extracts a JSON object, or null when the response holds no object.
  ///
  /// An array is accepted when it contains a single object, because models
  /// sometimes wrap a lone result in a list.
  static Map<String, Object?>? extractMap(String text) {
    final value = extract(text);
    if (value is Map<String, Object?>) return value;
    if (value is List && value.length == 1 && value.first is Map) {
      return (value.first as Map).cast<String, Object?>();
    }
    return null;
  }

  /// Extracts a JSON array, or null. A single object is wrapped into a list,
  /// mirroring [extractMap]'s tolerance in the other direction.
  static List<Object?>? extractList(String text) {
    final value = extract(text);
    if (value is List) return value;
    if (value is Map) return [value];
    return null;
  }

  /// Extracts and maps a list of objects, skipping any entry that is not a map.
  ///
  /// The tolerant behaviour matters here: a model asked for ten items will
  /// occasionally emit nine objects and a stray string, and losing the nine is
  /// worse than dropping the one.
  static List<Map<String, Object?>> extractMapList(String text) {
    final list = extractList(text) ?? const [];
    return [
      for (final entry in list)
        if (entry is Map) entry.cast<String, Object?>(),
    ];
  }

  /// Rewrites a prompt to ask for JSON, and describes the shape you expect.
  ///
  /// Appending the shape explicitly measurably improves compliance, and stating
  /// "no prose" up front saves the extraction step from having to work.
  static String instructJson(
    String prompt, {
    Map<String, Object?>? schema,
    bool array = false,
  }) {
    final buffer = StringBuffer(prompt)
      ..write('\n\nRespond with ')
      ..write(array ? 'a JSON array' : 'a JSON object')
      ..write(' only. Do not include prose, explanation, or a markdown fence.');
    if (schema != null) {
      buffer
        ..write(' The object must have exactly these keys: ')
        ..write(schema.keys.join(', '))
        ..write('. Example shape:\n')
        ..write(jsonEncode(schema));
    }
    return buffer.toString();
  }

  /// Every substring worth attempting to decode, most likely first.
  static Iterable<String> _candidates(String text) sync* {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    // Fenced blocks first: if the model fenced its output, that fence is the
    // most reliable signal about where the JSON starts and ends.
    for (final match in _fence.allMatches(text)) {
      final body = match.group(1);
      if (body != null && body.trim().isNotEmpty) yield body.trim();
    }

    // Then the whole string, which covers a clean response.
    yield trimmed;

    // Finally, brace- and bracket-balanced spans, which covers prose around
    // the payload.
    final fromObject = _balanced(trimmed, '{', '}');
    if (fromObject != null) yield fromObject;
    final fromArray = _balanced(trimmed, '[', ']');
    if (fromArray != null) yield fromArray;
  }

  static final RegExp _fence = RegExp(
    r'```(?:json|JSON)?\s*([\s\S]*?)```',
    multiLine: true,
  );

  /// Returns the first balanced span of [open]..[close], ignoring delimiters
  /// inside string literals.
  static String? _balanced(String text, String open, String close) {
    final start = text.indexOf(open);
    if (start < 0) return null;

    var depth = 0;
    var inString = false;
    var escaped = false;

    for (var i = start; i < text.length; i++) {
      final char = text[i];
      if (escaped) {
        escaped = false;
        continue;
      }
      if (char == r'\') {
        escaped = true;
        continue;
      }
      if (char == '"') {
        inString = !inString;
        continue;
      }
      if (inString) continue;
      if (char == open) depth++;
      if (char == close) {
        depth--;
        if (depth == 0) return text.substring(start, i + 1);
      }
    }
    return null;
  }

  static Object? _tryDecode(String candidate) {
    if (candidate.isEmpty) return null;
    try {
      return jsonDecode(candidate);
    } on FormatException {
      return null;
    }
  }
}
