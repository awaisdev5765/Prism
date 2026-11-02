/// Testing helpers for apps and packages built on Prism.
///
/// Kept in a separate entry point so `package:prism_kit/prism.dart` stays free
/// of a test-only dependency. Your app already has `flutter_test` in
/// `dev_dependencies`, which is the only place this library is used.
///
/// ```dart
/// import 'package:prism_kit/testing.dart';
///
/// testWidgets('the dashboard shows an empty state', (tester) async {
///   await pumpPrism(tester, const Dashboard(), size: const Size(320, 568));
///   expect(find.text('Nothing here yet'), findsOneWidget);
/// });
/// ```
///
/// The value here is that Prism's own test suite uses exactly these helpers, so
/// your tests exercise the same environment — including the parts that are easy
/// to get wrong, like a viewport that is not zero-sized and a design system that
/// is actually installed.
library;

export 'src/testing/harness.dart'
    show expectNoOverflow, prismTestSizes, pumpPrism, pumpPrismWithSemantics;
