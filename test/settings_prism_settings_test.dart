import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prism_kit/prism.dart';

PrismSettingsPage _page({
  PrismSettingsController? controller,
  bool searchable = false,
}) => PrismSettingsPage(
  controller: controller,
  searchable: searchable,
  sections: [
    const PrismSettingsSection(
      title: 'Appearance',
      tiles: [
        PrismSwitchTile(
          common: PrismTileCommon(
            key: 'darkMode',
            title: 'Dark mode',
            leading: Icons.dark_mode,
          ),
        ),
        PrismSliderTile(
          common: PrismTileCommon(key: 'fontSize', title: 'Text size'),
          min: 0.5,
          max: 2,
          divisions: 6,
        ),
      ],
    ),
    PrismSettingsSection(
      title: 'General',
      tiles: [
        PrismActionTile(
          common: PrismTileCommon(key: 'about', title: 'About'),
        ),
        PrismDropdownTile<String>(
          common: PrismTileCommon(key: 'language', title: 'Language'),
          items: ['English', 'العربية'],
          itemLabel: (item) => item,
        ),
        PrismCheckboxTile(
          common: PrismTileCommon(key: 'analytics', title: 'Share analytics'),
        ),
      ],
    ),
  ],
);

Future<void> _pump(
  WidgetTester tester,
  PrismSettingsPage page, {
  Size size = const Size(400, 900),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: page));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('switch toggles through the controller', (tester) async {
    final controller = PrismSettingsController();
    await _pump(tester, _page(controller: controller));
    expect(controller.get<bool>('darkMode', false), isFalse);
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    expect(controller.get<bool>('darkMode', false), isTrue);
  });

  testWidgets('slider writes double values', (tester) async {
    final controller = PrismSettingsController();
    await _pump(tester, _page(controller: controller));
    await tester.drag(find.byType(Slider), const Offset(200, 0));
    await tester.pumpAndSettle();
    expect(controller.get<double>('fontSize', 0.5), greaterThan(0.5));
  });

  testWidgets('dropdown selection is stored', (tester) async {
    final controller = PrismSettingsController();
    await _pump(tester, _page(controller: controller));
    // Whole tile is the tap target now.
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العربية').last);
    await tester.pumpAndSettle();
    expect(controller.get<String>('language', ''), 'العربية');
  });

  testWidgets('checkbox toggles', (tester) async {
    final controller = PrismSettingsController();
    await _pump(tester, _page(controller: controller));
    await tester.tap(find.text('Share analytics'));
    await tester.pumpAndSettle();
    expect(controller.get<bool>('analytics', false), isTrue);
  });

  testWidgets('onChanged fires with key and value', (tester) async {
    final changes = <String, Object?>{};
    final controller = PrismSettingsController(
      onChanged: (key, value) => changes[key] = value,
    );
    await _pump(tester, _page(controller: controller));
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    expect(changes['darkMode'], isTrue);
  });

  testWidgets('no duplicate onChanged for same value', (tester) async {
    var calls = 0;
    final controller = PrismSettingsController(onChanged: (_, _) => calls++);
    await _pump(tester, _page(controller: controller));
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark mode'));
    await tester.pumpAndSettle();
    expect(calls, 2); // on→off
  });

  testWidgets('search filters tiles by title', (tester) async {
    await _pump(tester, _page(searchable: true));
    await tester.enterText(find.byType(TextField), 'dark');
    await tester.pumpAndSettle();
    expect(find.text('Dark mode'), findsOneWidget);
    expect(find.text('About'), findsNothing);
    expect(find.text('Text size'), findsNothing);
  });

  testWidgets('search filters by subtitle too', (tester) async {
    await _pump(
      tester,
      PrismSettingsPage(
        searchable: true,
        sections: [
          const PrismSettingsSection(
            tiles: [
              PrismSwitchTile(
                common: PrismTileCommon(
                  key: 'x',
                  title: 'Sync',
                  subtitle: 'Keep everything up to date',
                ),
              ),
              PrismActionTile(
                common: PrismTileCommon(key: 'y', title: 'About'),
              ),
            ],
          ),
        ],
      ),
    );
    await tester.enterText(find.byType(TextField), 'up to date');
    await tester.pumpAndSettle();
    expect(find.text('Sync'), findsOneWidget);
    expect(find.text('About'), findsNothing);
  });

  testWidgets('clearing search restores all tiles', (tester) async {
    await _pump(tester, _page(searchable: true));
    await tester.enterText(find.byType(TextField), 'dark');
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('wide windows center content at maxWidth', (tester) async {
    await _pump(tester, _page(), size: const Size(1400, 900));
    final contentLeft = tester.getTopLeft(find.text('About')).dx;
    final contentRight = tester.getTopRight(find.text('About')).dx;
    const mid = 1400 / 2;
    expect(contentLeft, greaterThan(300));
    expect(contentLeft, lessThan(mid));
    expect(contentRight, greaterThan(mid));
  });

  test('controller setAll notifies once and stores values', () {
    final controller = PrismSettingsController();
    var notified = 0;
    controller.addListener(() => notified++);
    controller.setAll({'a': 1, 'b': 2});
    expect(notified, 1);
    expect(controller.values, {'a': 1, 'b': 2});
  });
}
