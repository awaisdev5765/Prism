/// Prism Image — resilient network image loading for Flutter.
///
/// The maintained replacement for the discontinued `flutter_image` package:
/// a drop-in `NetworkImageWithRetry` image provider with configurable
/// retry strategies (exponential backoff, jitter, transient status codes).
///
/// ```dart
/// const Image(image: NetworkImageWithRetry('https://example.com/photo.png'))
/// ```
///
/// See the README for the full migration guide from `flutter_image`.
library;

export './fetch_failure.dart';
export './fetch_strategy.dart';
export './network_image_with_retry.dart';
