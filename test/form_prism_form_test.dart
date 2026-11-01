import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_kit/prism.dart';

Widget _host(
  WidgetTester tester, {
  required Widget child,
  PrismFormController? controller,
}) {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  return MaterialApp(home: Scaffold(body: child));
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required Widget child,
  PrismFormController? controller,
}) async {
  await tester.pumpWidget(_host(tester, child: child, controller: controller));
  await tester.pumpAndSettle();
}

Future<void> _pumpLogin(
  WidgetTester tester, {
  PrismFormController? controller,
  required Future<void> Function(Map<String, Object?>) onSubmit,
}) async {
  await _pumpForm(
    tester,
    controller: controller,
    child: PrismForm(
      controller: controller,
      child: Builder(
        builder: (context) => Column(
          children: [
            PrismTextField(
              common: const PrismFieldCommon(name: 'email', label: 'Email'),
            ),
            PrismPasswordField(
              common: PrismFieldCommon(
                name: 'password',
                label: 'Password',
                validators: [Validators.required(), Validators.minLength(8)],
              ),
            ),
            ListenableBuilder(
              listenable: PrismFormScope.of(context),
              builder: (context, _) {
                final c = PrismFormScope.of(context);
                return FilledButton(
                  onPressed: c.status.isSubmitting
                      ? null
                      : () => c.submit(onSubmit),
                  child: switch (c.status) {
                    PrismFormSubmitting() => const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    PrismFormFailure(:final message) => Text('Retry: $message'),
                    _ => const Text('Sign in'),
                  },
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  test('Validators.required fails on blank', () {
    expect(Validators.required()(null), isNotNull);
    expect(Validators.required()('  '), isNotNull);
    expect(Validators.required()('x'), isNull);
  });

  test('Validators.email accepts plausible addresses', () {
    expect(Validators.email()('user@example.com'), isNull);
    expect(Validators.email()('nope'), isNotNull);
    expect(Validators.email()(''), isNull); // empty → required's job
  });

  test('Validators.all returns the first failure', () {
    final v = Validators.all([Validators.required(), Validators.minLength(5)]);
    expect(v(''), isNotNull);
    expect(v('abc'), isNotNull);
    expect(v('abcdef'), isNull);
  });

  testWidgets('required error appears only after touch/submit', (tester) async {
    final controller = PrismFormController();
    await _pumpLogin(tester, controller: controller, onSubmit: (_) async {});

    // No error before touch.
    expect(controller.errorOf('password'), isNull);

    // Focus the password field, then blur by focusing the email field.
    await tester.tap(find.byType(TextField).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField).first);
    await tester.pumpAndSettle();
    expect(controller.errorOf('password'), isNotNull);
    expect(find.text('This field is required'), findsOneWidget);
  });

  testWidgets('minLength error appears after submit attempt', (tester) async {
    final controller = PrismFormController();
    await _pumpLogin(tester, controller: controller, onSubmit: (_) async {});
    await tester.enterText(find.widgetWithText(TextField, '').first, 'short');
    // Two TextFields exist (email, password); enter into password via key:
    final fields = find.byType(TextField);
    await tester.enterText(fields.last, 'short');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(controller.status, isA<PrismFormEditing>());
    expect(controller.errorOf('password'), 'Must be at least 8 characters');
    expect(find.text('Must be at least 8 characters'), findsOneWidget);
  });

  testWidgets('successful submit receives values and shows success', (
    tester,
  ) async {
    final controller = PrismFormController();
    Map<String, Object?>? received;
    await _pumpLogin(
      tester,
      controller: controller,
      onSubmit: (values) async {
        received = values;
      },
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'a@b.co');
    await tester.enterText(fields.last, 'longenough');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(received?['email'], 'a@b.co');
    expect(received?['password'], 'longenough');
    expect(controller.status, isA<PrismFormSuccess>());
  });

  testWidgets('submitting state disables the button', (tester) async {
    final controller = PrismFormController();
    await _pumpLogin(
      tester,
      controller: controller,
      onSubmit: (_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      },
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'a@b.co');
    await tester.enterText(fields.last, 'longenough');
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(controller.status, isA<PrismFormSubmitting>());
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.pumpAndSettle();
    expect(controller.status, isA<PrismFormSuccess>());
  });

  testWidgets('server field errors map inline', (tester) async {
    final controller = PrismFormController();
    await _pumpLogin(
      tester,
      controller: controller,
      onSubmit: (_) async {
        throw const PrismSubmissionException(
          fieldErrors: {'email': 'Already registered'},
          message: 'Check the highlighted fields',
        );
      },
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'a@b.co');
    await tester.enterText(fields.last, 'longenough');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(controller.status, isA<PrismFormFailure>());
    expect(find.text('Already registered'), findsOneWidget);
    expect(find.text('Retry: Check the highlighted fields'), findsOneWidget);
  });

  testWidgets('generic failure sets failure status', (tester) async {
    final controller = PrismFormController();
    await _pumpLogin(
      tester,
      controller: controller,
      onSubmit: (_) async => throw StateError('network'),
    );
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'a@b.co');
    await tester.enterText(fields.last, 'longenough');
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(controller.status, isA<PrismFormFailure>());
    expect(find.text('Retry: Submission failed'), findsOneWidget);
  });

  testWidgets('reset returns to pristine', (tester) async {
    final controller = PrismFormController();
    await _pumpLogin(tester, controller: controller, onSubmit: (_) async {});
    final fields = find.byType(TextField);
    await tester.enterText(fields.first, 'a@b.co');
    await tester.enterText(fields.last, 'longenough');
    controller.reset();
    await tester.pumpAndSettle();
    expect(controller.status, isA<PrismFormPristine>());
    expect(controller.values, isEmpty);
    expect(controller.errors, isEmpty);
  });

  testWidgets('dropdown and checkbox participate in values', (tester) async {
    final controller = PrismFormController();
    Map<String, Object?>? received;
    await _pumpForm(
      tester,
      controller: controller,
      child: PrismForm(
        controller: controller,
        child: Builder(
          builder: (context) => Column(
            children: [
              PrismDropdownField<String>(
                common: const PrismFieldCommon(name: 'role'),
                items: const ['admin', 'user'],
                itemLabel: (item) => item,
              ),
              PrismCheckboxField(
                common: const PrismFieldCommon(name: 'terms'),
                title: 'Accept terms',
              ),
              FilledButton(
                onPressed: () => PrismFormScope.of(context).submit((v) async {
                  received = v;
                }),
                child: const Text('Go'),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('admin').last); // menu item
    await tester.pumpAndSettle();
    await tester.tap(find.text('Accept terms'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(received?['role'], 'admin');
    expect(received?['terms'], isTrue);
  });
}
