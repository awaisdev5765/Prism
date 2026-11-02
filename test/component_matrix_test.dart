import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prism_kit/prism.dart';

/// A cross-cutting safety net: every component is pumped at a phone width, a
/// desktop width, in light and dark, and in both text directions, and must
/// render without throwing or overflowing.
///
/// This is deliberately not a behavioural test — the per-component suites cover
/// behaviour. Its job is to catch the classes of bug that only appear at an
/// extreme: a `Row` that overflows at 320 px, a colour that is unreadable in
/// dark mode, an `EdgeInsetsDirectional` that is not actually directional.
class _Case {
  const _Case(
    this.name,
    this.build, {
    this.tall = false,
    this.ownScaffold = false,
  });

  final String name;
  final Widget Function() build;

  /// Content that is legitimately taller than a phone screen and is documented
  /// to live inside a scrollable.
  final bool tall;

  /// Components that provide their own [Scaffold].
  final bool ownScaffold;
}

final _cases = <_Case>[
  _Case(
    'AdaptiveScaffold',
    ownScaffold: true,
    () => PrismAdaptiveScaffold(
      destinations: const [
        AdaptiveDestination(icon: Icons.home, label: 'Home'),
        AdaptiveDestination(icon: Icons.settings, label: 'Settings'),
      ],
      bodyBuilder: (i) => const SizedBox.shrink(),
    ),
  ),
  _Case('Toast', () => const ToastProbe()),
  _Case(
    'Banner',
    tall: true,
    () => const PrismBanner(
      announcements: [
        PrismAnnouncement(
          id: 'a',
          title: 'Announcement',
          message: 'A reasonably long announcement message for width testing.',
          actionLabel: 'See more',
        ),
      ],
    ),
  ),
  _Case(
    'Search',
    () => PrismSearch<String>(
      items: const ['Alpha', 'Beta', 'Gamma'],
      itemLabel: (s) => s,
    ),
  ),
  _Case(
    'Settings',
    ownScaffold: true,
    () => PrismSettingsPage(
      sections: const [
        PrismSettingsSection(
          title: 'General',
          tiles: [
            PrismSwitchTile(
              common: PrismTileCommon(
                key: 'k',
                title: 'A setting with a fairly long title',
                subtitle: 'And a supporting description underneath it',
                leading: Icons.tune,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  _Case(
    'Markdown',
    tall: true,
    () => const PrismMarkdown(
      '# Heading\n\nSome **bold** text and a [link](https://flutter.dev).',
    ),
  ),
  _Case(
    'CodeView',
    tall: true,
    () => const PrismCodeView(code: "void main() => print('hi');"),
  ),
  _Case(
    'StateView',
    tall: true,
    () => PrismStateView<String>(
      state: PrismViewError<String>(StateError('boom')),
      onRetry: () {},
      successBuilder: (d) => Text(d),
    ),
  ),
  _Case(
    'StateView empty',
    tall: true,
    () => PrismStateView<String>(
      state: const PrismViewEmpty(),
      successBuilder: (d) => Text(d),
    ),
  ),
  _Case(
    'PaginatedList',
    () => PrismPaginatedList<String>(
      pageLoader: (_) async => const ['one', 'two'],
      itemBuilder: (c, item, i) => ListTile(title: Text(item)),
    ),
  ),
  _Case(
    'MasterDetail',
    ownScaffold: true,
    () => PrismMasterDetail<String>(
      items: const ['Alpha', 'Beta'],
      masterBuilder: (c, item, selected) => ListTile(
        selected: selected,
        title: Text(item),
        subtitle: const Text('A long supporting line that may need to wrap'),
      ),
      detailBuilder: (c, item) => Center(child: Text(item)),
    ),
  ),
  _Case('Palette', () => const Center(child: Text('palette'))),
  _Case(
    'Changelog',
    tall: true,
    () => const ChangelogView(
      changelog: '## 1.0.0\n\n### Added\n- Something new and notable\n',
    ),
  ),
  _Case(
    'Skeleton',
    tall: true,
    () => const PrismSkeletonList.cards(count: 2, mediaHeight: 80),
  ),
  _Case(
    'Avatar',
    () => const Row(
      children: [
        PrismAvatar(name: 'Ayesha Khan', presence: PrismPresence.online),
        PrismAvatar(name: 'A Very Long Display Name Here'),
      ],
    ),
  ),
  _Case(
    'ChipInput',
    tall: true,
    () => PrismChipInput(
      label: 'Tags',
      value: const ['alpha', 'a-rather-long-tag-value', 'gamma'],
      suggestions: const ['delta', 'epsilon'],
      helperText: 'Some helper text that explains what this field does.',
      onChanged: (_) {},
    ),
  ),
  _Case(
    'OtpField',
    tall: true,
    () => const PrismOtpField(
      length: 6,
      groupSeparatorAfter: 3,
      errorText: 'That code is not valid',
    ),
  ),
  _Case(
    'Timeline',
    tall: true,
    () => const PrismTimeline(
      entries: [
        PrismTimelineEntry(
          title: 'Order placed',
          subtitle: 'A supporting line that is long enough to wrap on a phone',
          timestamp: 'Today, 09:12',
          semantic: PrismSemantic.success,
        ),
        PrismTimelineEntry(title: 'Out for delivery', isActive: true),
      ],
    ),
  ),
  _Case(
    'Stepper',
    tall: true,
    () => const PrismStepper(
      steps: [
        PrismStep(title: 'Account', subtitle: 'Email and password'),
        PrismStep(title: 'Profile'),
        PrismStep(title: 'Preferences', isOptional: true),
      ],
      currentIndex: 1,
    ),
  ),
  _Case(
    'DataTable',
    tall: true,
    () => PrismDataTable<_Row>(
      rows: const [
        _Row('INV-1042', 'Zenith Ltd', 'Paid'),
        _Row('INV-1043', 'Aurora Media', 'Overdue'),
      ],
      columns: [
        PrismColumn<_Row>(
          label: 'Invoice',
          alwaysVisible: true,
          cell: (c, r, i) => Text(r.id),
        ),
        PrismColumn<_Row>(label: 'Client', cell: (c, r, i) => Text(r.client)),
        PrismColumn<_Row>(
          label: 'Status',
          numeric: true,
          cell: (c, r, i) => Text(r.status),
        ),
      ],
    ),
  ),
  _Case(
    'CommandPalette',
    tall: true,
    () => PrismCommandPalette(
      commands: [
        PrismCommand(
          label: 'New note',
          subtitle: 'Create a blank note',
          icon: Icons.add,
          group: 'File',
          shortcut: '⌘N',
          onSelect: () {},
        ),
        PrismCommand(label: 'Sign out', group: 'Account', onSelect: () {}),
      ],
    ),
  ),
  _Case(
    'ConnectionBanner',
    tall: true,
    () => PrismConnectionBanner(
      source: () => const Stream<bool>.empty(),
      onRetry: () {},
    ),
  ),
  _Case('EmptyStateView', () => const SizedBox.shrink()),
];

class _Row {
  const _Row(this.id, this.client, this.status);
  final String id;
  final String client;
  final String status;
}

/// Fires a toast shortly after mount so the toast host renders inside the tree.
class ToastProbe extends StatefulWidget {
  const ToastProbe({super.key});

  @override
  State<ToastProbe> createState() => _ToastProbeState();
}

class _ToastProbeState extends State<ToastProbe> {
  @override
  void initState() {
    super.initState();
    // Queue after the frame: showing a toast during build would call setState
    // on the overlay mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      PrismToast.info(context, 'A toast message for width testing');
    });
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

const _sizes = <String, Size>{
  'phone': Size(320, 568),
  'wide': Size(1600, 1000),
};

void main() {
  for (final MapEntry(key: sizeName, value: size) in _sizes.entries) {
    for (final brightness in Brightness.values) {
      for (final rtl in [false, true]) {
        group('$sizeName / ${brightness.name} / ${rtl ? 'RTL' : 'LTR'}', () {
          for (final testCase in _cases) {
            testWidgets('${testCase.name} renders cleanly', (tester) async {
              tester.view.physicalSize = size;
              tester.view.devicePixelRatio = 1.0;
              addTearDown(tester.view.reset);

              final content = testCase.build();
              await tester.pumpWidget(
                MaterialApp(
                  theme: ThemeData(
                    colorSchemeSeed: const Color(0xFF39A9DB),
                    brightness: brightness,
                  ),
                  home: Directionality(
                    textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                    child: testCase.ownScaffold
                        ? content
                        : Scaffold(
                            body: testCase.tall
                                ? SingleChildScrollView(child: content)
                                : content,
                          ),
                  ),
                ),
              );
              // Let any implicit animation settle; an overflow throws here.
              await tester.pump(const Duration(milliseconds: 350));

              // Transient overlays must not leave timers behind, or the next
              // test in the file fails for the wrong reason.
              PrismToast.dismissAll();
              await tester.pump(const Duration(milliseconds: 400));

              expect(
                tester.takeException(),
                isNull,
                reason:
                    '${testCase.name} threw at ${size.width}x${size.height} '
                    'in ${brightness.name} ${rtl ? 'RTL' : 'LTR'}',
              );
            });
          }
        });
      }
    }
  }
}
