/// Validates AI responses before showing them to the user.
class PrismGuard {
  PrismGuard({
    this.blockedPatterns = const [],
    this.maxResponseLength = 0,
    this.customValidators = const [],
  });
  final List<RegExp> blockedPatterns;
  final int maxResponseLength;
  final List<String? Function(String)> customValidators;

  String? check(String response) {
    for (final pattern in blockedPatterns) {
      if (pattern.hasMatch(response)) return 'Matched: ${pattern.pattern}';
    }
    if (maxResponseLength > 0 && response.length > maxResponseLength)
      return 'Too long';
    for (final validator in customValidators) {
      final error = validator(response);
      if (error != null) return error;
    }
    return null;
  }
}
