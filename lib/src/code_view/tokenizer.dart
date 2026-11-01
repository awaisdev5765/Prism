/// Built-in, dependency-free syntax tokenizer for common languages.
///
/// Produces [CodeToken]s with token kinds that [PrismCodeViewStyle] maps to
/// colors. Adding a new language only requires a new [LanguageTokenizer]
/// implementation.
library;

/// The kind of a syntactic element found in source code.
enum TokenKind {
  /// A reserved keyword (e.g. `class`, `if`, `return`).
  keyword,

  /// A literal string, including its delimiters.
  string,

  /// A numeric literal.
  number,

  /// A single or multi-line comment.
  comment,

  /// A class, function, or type name.
  identifier,

  /// Operators and punctuation (`+`, `-`, `(`, `)`, `;`).
  punctuation,

  /// Anything that does not match another kind (whitespace, plain words).
  plain,
}

/// A single span of source code and its syntactic [kind].
class CodeToken {
  /// Creates a token spanning [text] with syntactic kind [kind].
  const CodeToken(this.text, this.kind);

  /// The raw source text of this token.
  final String text;

  /// The syntactic classification of this token.
  final TokenKind kind;
}

/// Strategy for splitting source code into [CodeToken]s.
abstract class LanguageTokenizer {
  /// Creates a tokenizer.
  const LanguageTokenizer();

  /// Tokenizes [code] into a flat list of tokens covering the full input.
  List<CodeToken> tokenize(String code);
}

/// Tokenizer for Dart source code.
class DartTokenizer extends LanguageTokenizer {
  /// Creates a Dart tokenizer.
  const DartTokenizer();

  static const _keywords = {
    'abstract',
    'as',
    'assert',
    'async',
    'await',
    'base',
    'break',
    'case',
    'catch',
    'class',
    'const',
    'continue',
    'covariant',
    'default',
    'deferred',
    'do',
    'dynamic',
    'else',
    'enum',
    'export',
    'extends',
    'extension',
    'external',
    'factory',
    'false',
    'final',
    'finally',
    'for',
    'function',
    'get',
    'hide',
    'if',
    'implements',
    'import',
    'in',
    'interface',
    'is',
    'late',
    'library',
    'mixin',
    'null',
    'on',
    'operator',
    'part',
    'required',
    'rethrow',
    'return',
    'sealed',
    'set',
    'show',
    'static',
    'super',
    'switch',
    'sync',
    'this',
    'throw',
    'true',
    'try',
    'typedef',
    'var',
    'void',
    'when',
    'while',
    'with',
    'yield',
  };

  @override
  List<CodeToken> tokenize(String code) => _tokenize(
    code,
    keywords: _keywords,
    lineComment: '//',
    blockComment: const ('/*', '*/'),
  );
}

/// Tokenizer for JSON documents.
class JsonTokenizer extends LanguageTokenizer {
  /// Creates a JSON tokenizer.
  const JsonTokenizer();

  static const _keywords = {'true', 'false', 'null'};

  @override
  List<CodeToken> tokenize(String code) => _tokenize(
    code,
    keywords: _keywords,
    lineComment: null,
    blockComment: null,
  );
}

/// Tokenizer for YAML documents.
class YamlTokenizer extends LanguageTokenizer {
  /// Creates a YAML tokenizer.
  const YamlTokenizer();

  static const _keywords = {'true', 'false', 'null', 'yes', 'no', 'on', 'off'};

  @override
  List<CodeToken> tokenize(String code) => _tokenize(
    code,
    keywords: _keywords,
    lineComment: '#',
    blockComment: null,
  );
}

/// Generic scanner shared by all built-in tokenizers.
List<CodeToken> _tokenize(
  String code, {
  required Set<String> keywords,
  required String? lineComment,
  required (String, String)? blockComment,
}) {
  final tokens = <CodeToken>[];
  final buffer = StringBuffer();
  TokenKind bufferKind = TokenKind.plain;

  void flush() {
    if (buffer.isNotEmpty) {
      tokens.add(CodeToken(buffer.toString(), bufferKind));
      buffer.clear();
    }
  }

  void emit(String text, TokenKind kind) {
    if (bufferKind != kind) flush();
    bufferKind = kind;
    buffer.write(text);
  }

  var i = 0;
  while (i < code.length) {
    final ch = code[i];

    // Comments.
    if (lineComment != null && code.startsWith(lineComment, i)) {
      flush();
      final end = code.indexOf('\n', i);
      final commentEnd = end == -1 ? code.length : end;
      emit(code.substring(i, commentEnd), TokenKind.comment);
      i = commentEnd;
      continue;
    }
    if (blockComment != null) {
      final (open, close) = blockComment;
      if (code.startsWith(open, i)) {
        flush();
        final end = code.indexOf(close, i + open.length);
        final commentEnd = end == -1 ? code.length : end + close.length;
        emit(code.substring(i, commentEnd), TokenKind.comment);
        i = commentEnd;
        continue;
      }
    }

    // Strings (single, double, and raw triple-quoted for Dart).
    if (ch == '"' || ch == "'") {
      flush();
      final quote = ch;
      final isTriple = code.startsWith(quote * 3, i);
      final delimiter = isTriple ? quote * 3 : quote;
      var end = i + delimiter.length;
      while (end < code.length) {
        if (code[end] == '\\') {
          end += 2;
          continue;
        }
        if (code.startsWith(delimiter, end)) break;
        end++;
      }
      final stringEnd = (end + delimiter.length).clamp(i, code.length).toInt();
      emit(code.substring(i, stringEnd), TokenKind.string);
      i = stringEnd;
      continue;
    }

    // Numbers.
    if (_isDigit(ch)) {
      flush();
      var end = i;
      while (end < code.length &&
          (_isDigit(code[end]) || code[end] == '.' || code[end] == '_')) {
        end++;
      }
      emit(code.substring(i, end), TokenKind.number);
      i = end;
      continue;
    }

    // Identifiers / keywords.
    if (_isIdentifierStart(ch)) {
      flush();
      var end = i;
      while (end < code.length && _isIdentifierPart(code[end])) {
        end++;
      }
      final word = code.substring(i, end);
      emit(
        word,
        keywords.contains(word) ? TokenKind.keyword : TokenKind.identifier,
      );
      i = end;
      continue;
    }

    // Everything else: punctuation or whitespace grouped as plain.
    emit(ch, TokenKind.punctuation);
    i++;
  }
  flush();
  return tokens;
}

bool _isDigit(String ch) =>
    ch.codeUnitAt(0) >= 0x30 && ch.codeUnitAt(0) <= 0x39;
bool _isIdentifierStart(String ch) => ch == '_' || _isLetter(ch) || ch == r'$';
bool _isIdentifierPart(String ch) => _isIdentifierStart(ch) || _isDigit(ch);
bool _isLetter(String ch) {
  final c = ch.toLowerCase().codeUnitAt(0);
  return c >= 0x61 && c <= 0x7A;
}
