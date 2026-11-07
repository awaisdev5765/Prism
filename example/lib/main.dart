// Prism gallery — interactive demos for every component.
//
// Run: `flutter run` inside this folder, then tap a component from the
// grid. Every demo is a working, copy-pasteable snippet using the real API.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:prism_kit/prism.dart';

void main() => runApp(const PrismGalleryApp());

/// The gallery shell.
///
/// It exercises the parts of Prism that are easiest to get wrong when you are
/// the one building the library: theming, a live token override, and the
/// adaptive shell doing real work on a real screen.
class PrismGalleryApp extends StatefulWidget {
  const PrismGalleryApp({super.key});

  @override
  State<PrismGalleryApp> createState() => _PrismGalleryAppState();
}

class _PrismGalleryAppState extends State<PrismGalleryApp> {
  ThemeMode _mode = ThemeMode.system;

  /// When true, the app is themed with deliberately unusual tokens so you can
  /// see every component adopt them at once. This is the design system doing
  /// its job, not a mock-up.
  bool _compactSpacing = false;

  void _toggleMode() {
    setState(() {
      _mode = switch (_mode) {
        ThemeMode.system => ThemeMode.light,
        ThemeMode.light => ThemeMode.dark,
        ThemeMode.dark => ThemeMode.system,
      };
    });
  }

  void _toggleTokens() => setState(() => _compactSpacing = !_compactSpacing);

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF39A9DB);

    // One token set, installed in both themes. Flip the switch in the app bar
    // and watch every component change rhythm at once.
    final tokens = _compactSpacing
        ? const PrismTokens(
            spaceMd: 10,
            spaceLg: 14,
            radiusSm: 2,
            radiusMd: 3,
            radiusLg: 4,
            radiusXl: 6,
          )
        : PrismTokens.fallback;

    return MaterialApp(
      title: 'Prism gallery',
      debugShowCheckedModeBanner: false,
      themeMode: _mode,
      theme: ThemeData(colorSchemeSeed: seed, extensions: [tokens]),
      darkTheme: ThemeData(
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
        extensions: [tokens],
      ),
      home: GalleryHome(
        themeMode: _mode,
        onToggleTheme: _toggleMode,
        compactTokens: _compactSpacing,
        onToggleTokens: _toggleTokens,
      ),
    );
  }
}

/// A searchable grid of every component demo.
class GalleryHome extends StatefulWidget {
  const GalleryHome({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
    required this.compactTokens,
    required this.onToggleTokens,
  });

  /// Current theme mode, shown on the toggle button.
  final ThemeMode themeMode;

  /// Cycles system → light → dark.
  final VoidCallback onToggleTheme;

  /// Whether the unusual token set is active.
  final bool compactTokens;

  /// Installs or removes the unusual token set.
  final VoidCallback onToggleTokens;

  @override
  State<GalleryHome> createState() => _GalleryHomeState();
}

class _GalleryHomeState extends State<GalleryHome> {
  final _controller = TextEditingController();

  /// Every demo, in the order they appear in the grid.
  ///
  /// `keywords` are extra search terms, so "table" finds the data table and
  /// "pin" finds the OTP field.
  static const _demos = <_Demo>[
    _Demo('Adaptive scaffold', Icons.smartphone, [
      'nav',
      'rail',
      'responsive',
    ], _scaffold),
    _Demo('Toast', Icons.notifications_none, [
      'snackbar',
      'notification',
    ], _toast),
    _Demo('Banner', Icons.campaign_outlined, [
      'announcement',
      'dismiss',
    ], _banner),
    _Demo('Search', Icons.search, ['filter', 'query', 'fuzzy'], _search),
    _Demo('Settings', Icons.settings_outlined, [
      'preferences',
      'tiles',
    ], _settings),
    _Demo('Markdown', Icons.article_outlined, [
      'gfm',
      'commonmark',
      'text',
    ], _markdown),
    _Demo('Code view', Icons.code, ['syntax', 'highlight', 'copy'], _code),
    _Demo('Form', Icons.edit_note, ['validation', 'fields', 'submit'], _form),
    _Demo('Pagination', Icons.menu, [
      'infinite',
      'scroll',
      'list',
    ], _pagination),
    _Demo('Master-detail', Icons.view_agenda_outlined, [
      'split',
      'panes',
    ], _masterDetail),
    _Demo('Adaptive dialog', Icons.open_in_full, ['modal', 'confirm'], _dialog),
    _Demo('State views', Icons.extension_outlined, [
      'loading',
      'empty',
      'error',
    ], _stateViews),
    _Demo('Palette', Icons.palette_outlined, [
      'colour',
      'extract',
      'theme',
    ], _palette),
    _Demo('Changelog', Icons.history, [
      'releases',
      'version',
      'whats new',
    ], _changelog),
    _Demo('AI chat', Icons.smart_toy_outlined, [
      'llm',
      'openai',
      'ollama',
      'streaming',
    ], _ai),
    _Demo('Skeleton', Icons.blur_on, [
      'loading',
      'shimmer',
      'placeholder',
    ], _skeleton),
    _Demo('Avatar', Icons.account_circle_outlined, [
      'initials',
      'profile',
      'presence',
    ], _avatar),
    _Demo('Chip input', Icons.label_outline, [
      'tags',
      'tokens',
      'labels',
    ], _chipInput),
    _Demo('OTP field', Icons.password, ['pin', 'code', 'verification'], _otp),
    _Demo('Timeline', Icons.timeline, [
      'activity',
      'steps',
      'history',
    ], _timeline),
    _Demo('Stepper', Icons.linear_scale, [
      'wizard',
      'progress',
      'steps',
    ], _stepper),
    _Demo('Data table', Icons.table_chart_outlined, [
      'grid',
      'sort',
      'rows',
      'columns',
    ], _dataTable),
    _Demo('Command palette', Icons.keyboard_command_key, [
      'launcher',
      'shortcut',
      'cmd k',
    ], _commandPalette),
    _Demo('Adaptive sheet', Icons.vertical_align_bottom, [
      'bottom sheet',
      'modal',
    ], _adaptiveSheet),
    _Demo('Connection banner', Icons.cloud_off_outlined, [
      'offline',
      'network',
    ], _connection),
    _Demo('Design tokens', Icons.palette, [
      'spacing',
      'radius',
      'motion',
    ], _tokens),
    _Demo('AI message bubble', Icons.chat_bubble_outline, [
      'ai',
      'chat',
      'assistant',
      'streaming',
    ], _aiBubble),
    _Demo('AI composer', Icons.keyboard, [
      'ai',
      'input',
      'prompt',
      'suggestions',
    ], _aiComposer),
    _Demo('Color picker', Icons.colorize, [
      'colour',
      'hsv',
      'hex',
      'paint',
    ], _colorPicker),
    _Demo('Overlay tour', Icons.tour, [
      'onboarding',
      'spotlight',
      'coach',
      'guide',
    ], _overlayTour),
    _Demo('Sparkline', Icons.show_chart, [
      'chart',
      'trend',
      'mini',
    ], _sparkline),
  ];

  static Widget _scaffold() => const ScaffoldDemo();
  static Widget _toast() => const ToastDemo();
  static Widget _banner() => const BannerDemo();
  static Widget _search() => const SearchDemo();
  static Widget _settings() => const SettingsDemo();
  static Widget _markdown() => const MarkdownDemo();
  static Widget _code() => const CodeDemo();
  static Widget _form() => const FormDemo();
  static Widget _pagination() => const PaginationDemo();
  static Widget _masterDetail() => const MasterDetailDemo();
  static Widget _dialog() => const DialogDemo();
  static Widget _stateViews() => const StateViewsDemo();
  static Widget _palette() => const PaletteDemo();
  static Widget _changelog() => const ChangelogDemo();
  static Widget _ai() => const AiDemo();
  static Widget _skeleton() => const SkeletonDemo();
  static Widget _avatar() => const AvatarDemo();
  static Widget _chipInput() => const ChipInputDemo();
  static Widget _otp() => const OtpDemo();
  static Widget _timeline() => const TimelineDemo();
  static Widget _stepper() => const StepperDemo();
  static Widget _dataTable() => const DataTableDemo();
  static Widget _commandPalette() => const CommandPaletteDemo();
  static Widget _adaptiveSheet() => const AdaptiveSheetDemo();
  static Widget _connection() => const ConnectionDemo();
  static Widget _tokens() => const TokensDemo();
  static Widget _aiBubble() => const AiBubbleDemo();
  static Widget _aiComposer() => const AiComposerDemo();
  static Widget _colorPicker() => const ColorPickerDemo();
  static Widget _overlayTour() => const OverlayTourDemo();
  static Widget _sparkline() => const SparklineDemo();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_Demo> get _visible {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) return _demos;
    return _demos.where((d) => d.matches(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final demos = _visible;
    final columns = switch (MediaQuery.sizeOf(context).width) {
      < 520 => 2,
      < 840 => 3,
      _ => 4,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Prism gallery'),
        actions: [
          IconButton(
            tooltip: widget.compactTokens
                ? 'Restore default tokens'
                : 'Apply a distinctly non-default token set',
            icon: Icon(widget.compactTokens ? Icons.tune : Icons.tune_outlined),
            onPressed: widget.onToggleTokens,
          ),
          IconButton(
            tooltip: 'Theme: ${widget.themeMode.name}',
            icon: Icon(switch (widget.themeMode) {
              ThemeMode.system => Icons.brightness_auto_outlined,
              ThemeMode.light => Icons.light_mode_outlined,
              ThemeMode.dark => Icons.dark_mode_outlined,
            }),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              tokens.spaceMd,
              tokens.spaceMd,
              tokens.spaceMd,
              tokens.spaceSm,
            ),
            // PrismSearch, used by Prism on itself.
            child: PrismSearch<_Demo>(
              items: _demos,
              itemLabel: (d) => d.name,
              hintText: 'Find a component…',
              onSelected: (demo) => _open(demo.name),
            ),
          ),
          Expanded(
            child: demos.isEmpty
                ? const PrismStateView<List<_Demo>>(
                    state: PrismViewEmpty(),
                    emptyMessage: 'No component matches that search.',
                    successBuilder: _never,
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(tokens.spaceMd),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: tokens.spaceSm,
                      crossAxisSpacing: tokens.spaceSm,
                    ),
                    itemCount: demos.length,
                    itemBuilder: (context, i) {
                      final demo = demos[i];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: InkWell(
                          onTap: () => _open(demo.name),
                          child: Padding(
                            padding: EdgeInsets.all(tokens.spaceSm),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(demo.icon, size: tokens.spaceXl),
                                SizedBox(height: tokens.spaceSm),
                                Text(
                                  demo.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _never(List<_Demo> _) => const SizedBox.shrink();

  void _open(String name) {
    final demo = _demos.firstWhere((d) => d.name == name);
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => demo.build()),
    );
  }
}

/// One entry in the gallery grid.
@immutable
class _Demo {
  const _Demo(this.name, this.icon, this.keywords, this.build);

  final String name;
  final IconData icon;
  final List<String> keywords;
  final Widget Function() build;

  bool matches(String query) =>
      name.toLowerCase().contains(query) ||
      keywords.any((k) => k.contains(query));
}

// ─── Adaptive scaffold ──────────────────────────────────────────────────────
// Resize the window to see bottom nav → rail → expanded rail.

class ScaffoldDemo extends StatefulWidget {
  const ScaffoldDemo({super.key});

  @override
  State<ScaffoldDemo> createState() => _ScaffoldDemoState();
}

class _ScaffoldDemoState extends State<ScaffoldDemo> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return PrismAdaptiveScaffold(
      currentIndex: _index,
      onDestinationSelected: (i) => setState(() => _index = i),
      destinations: const [
        AdaptiveDestination(
          icon: Icons.home_outlined,
          selectedIcon: Icons.home,
          label: 'Home',
        ),
        AdaptiveDestination(
          icon: Icons.search_outlined,
          selectedIcon: Icons.search,
          label: 'Search',
        ),
        AdaptiveDestination(
          icon: Icons.settings_outlined,
          selectedIcon: Icons.settings,
          label: 'Settings',
        ),
      ],
      bodyBuilder: (i) => Center(
        child: Text(
          'Page $i — resize the window!',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}

// ─── Toast ──────────────────────────────────────────────────────────────────

class ToastDemo extends StatelessWidget {
  const ToastDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismToast')),
      body: Center(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            FilledButton(
              onPressed: () =>
                  PrismToast.success(context, 'Saved successfully'),
              child: const Text('Success'),
            ),
            FilledButton(
              onPressed: () =>
                  PrismToast.error(context, 'Something went wrong'),
              child: const Text('Error'),
            ),
            FilledButton(
              onPressed: () => PrismToast.info(context, 'Heads up!'),
              child: const Text('Info'),
            ),
            FilledButton(
              onPressed: () => PrismToast.warning(context, 'Low battery'),
              child: const Text('Warning'),
            ),
            FilledButton(
              onPressed: () => PrismToast.show(
                context,
                PrismToastMessage(
                  message: 'Report synced to your workspace',
                  title: 'Done',
                  duration: const Duration(seconds: 5),
                  actionLabel: 'Undo',
                  onAction: () {},
                ),
              ),
              child: const Text('With action'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Banner ─────────────────────────────────────────────────────────────────

class BannerDemo extends StatelessWidget {
  const BannerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismBanner')),
      body: ListView(
        children: [
          PrismBanner(
            announcements: const [
              PrismAnnouncement(
                id: 'gallery-demo-1',
                version: 1,
                title: 'Announcement',
                message: 'Dismiss me — I stay dismissed across restarts.',
                severity: PrismSeverity.info,
              ),
              PrismAnnouncement(
                id: 'gallery-demo-2',
                version: 1,
                title: 'Critical notice',
                message:
                    'Highest severity wins with PrismBannerPriority.severity.',
                severity: PrismSeverity.error,
              ),
            ],
            priority: PrismBannerPriority.severity,
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'The banner shows the highest-severity undismissed announcement. '
              'Dismissals persist via shared_preferences — restart and they stay gone.',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Search ─────────────────────────────────────────────────────────────────

class SearchDemo extends StatelessWidget {
  const SearchDemo({super.key});

  static const fruits = [
    'Apple',
    'Apricot',
    'Banana',
    'Blueberry',
    'Cherry',
    'Cranberry',
    'Dragonfruit',
    'Durian',
    'Elderberry',
    'Fig',
    'Grape',
    'Guava',
    'Kiwi',
    'Lemon',
    'Lime',
    'Mango',
    'Melon',
    'Nectarine',
    'Orange',
    'Papaya',
    'Peach',
    'Pear',
    'Pineapple',
    'Plum',
    'Raspberry',
    'Strawberry',
    'Tangerine',
    'Watermelon',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismSearch')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: PrismSearch<String>(
          items: fruits,
          itemLabel: (item) => item,
          hintText: 'Search fruits…',
          onSelected: (item) => PrismToast.success(context, 'Picked $item'),
        ),
      ),
    );
  }
}

// ─── Settings ───────────────────────────────────────────────────────────────

class SettingsDemo extends StatefulWidget {
  const SettingsDemo({super.key});

  @override
  State<SettingsDemo> createState() => _SettingsDemoState();
}

class _SettingsDemoState extends State<SettingsDemo> {
  late final PrismSettingsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PrismSettingsController();
    _controller.setAll({'notifications': true, 'dark-mode': false});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismSettingsPage')),
      body: PrismSettingsPage(
        controller: _controller,
        searchable: true,
        sections: const [
          PrismSettingsSection(
            title: 'General',
            tiles: [
              PrismSwitchTile(
                common: PrismTileCommon(
                  key: 'notifications',
                  title: 'Notifications',
                  subtitle: 'Receive break reminders',
                  leading: Icons.notifications_outlined,
                ),
              ),
              PrismSwitchTile(
                common: PrismTileCommon(
                  key: 'dark-mode',
                  title: 'Dark mode',
                  subtitle: 'Follow the system theme',
                  leading: Icons.dark_mode,
                ),
              ),
              PrismActionTile(
                common: PrismTileCommon(
                  key: 'language',
                  title: 'Language',
                  subtitle: 'English',
                  leading: Icons.language,
                ),
              ),
            ],
          ),
          PrismSettingsSection(
            title: 'About',
            tiles: [
              PrismActionTile(
                common: PrismTileCommon(
                  key: 'version',
                  title: 'Version',
                  subtitle: '1.0.0',
                  leading: Icons.info_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Markdown ───────────────────────────────────────────────────────────────

class MarkdownDemo extends StatelessWidget {
  const MarkdownDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismMarkdown')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: PrismMarkdown(
          '# Hello Prism\n\n'
          'A **fast**, plugin-free markdown renderer with full CommonMark\n'
          'and GFM support.\n\n'
          '## Features\n\n'
          '- Rich **bold**, *italic* and ~~strikethrough~~\n'
          '- [Links](https://flutter.dev) that are tappable\n'
          '- `inline code` and fenced blocks\n\n'
          '```dart\n'
          "void main() => print('rendered');\n"
          '```\n',
        ),
      ),
    );
  }
}

// ─── Code view ──────────────────────────────────────────────────────────────

class CodeDemo extends StatelessWidget {
  const CodeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismCodeView')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PrismCodeView(code: "void main() {\n  print('Hello, Prism!');\n}"),
          const SizedBox(height: 16),
          const Text(
            'Built-in Dart & JSON tokenizers — bring your own with LanguageTokenizer.',
          ),
        ],
      ),
    );
  }
}

// ─── Form ───────────────────────────────────────────────────────────────────

class FormDemo extends StatefulWidget {
  const FormDemo({super.key});

  @override
  State<FormDemo> createState() => _FormDemoState();
}

class _FormDemoState extends State<FormDemo> {
  final _controller = PrismFormController();
  String _result = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismForm')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PrismForm(
            controller: _controller,
            child: Column(
              children: [
                PrismTextField.email(name: 'email', label: 'Email'),
                const SizedBox(height: 12),
                PrismPasswordField(
                  common: PrismFieldCommon(
                    name: 'password',
                    label: 'Password',
                    validators: [Validators.required('Enter a password')],
                  ),
                ),
                const SizedBox(height: 12),
                PrismDropdownField<String>(
                  common: PrismFieldCommon(
                    name: 'plan',
                    label: 'Plan',
                    validators: [Validators.required('Pick a plan')],
                  ),
                  items: const ['Free', 'Pro', 'Team'],
                  itemLabel: (plan) => plan,
                ),
                const SizedBox(height: 12),
                PrismCheckboxField(
                  common: PrismFieldCommon(
                    name: 'terms',
                    label: 'I accept the terms of service',
                    validators: [Validators.required('Please accept')],
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () async {
                    final ok = await _controller.submit(
                      (values) async => _mockRegister(values),
                    );
                    setState(() {
                      _result = ok
                          ? '✅ Account created!'
                          : '❌ Check the fields';
                    });
                  },
                  child: const Text('Create account'),
                ),
                if (_result.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(_result),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mockRegister(Map<String, Object?> values) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    // ignore: avoid_print
    print('registering: $values');
  }
}

// ─── Pagination ─────────────────────────────────────────────────────────────

class PaginationDemo extends StatelessWidget {
  const PaginationDemo({super.key});

  Future<List<String>> _loadPage(int page) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (page >= 3) return const []; // end of data
    return List.generate(20, (i) => 'Item #${page * 20 + i + 1}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismPaginatedList')),
      body: PrismPaginatedList<String>(
        pageLoader: _loadPage,
        itemBuilder: (context, item, index) => ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(item),
        ),
      ),
    );
  }
}

// ─── Master-detail ──────────────────────────────────────────────────────────

class MasterDetailDemo extends StatelessWidget {
  const MasterDetailDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(8, (i) => 'Conversation ${i + 1}');
    return Scaffold(
      appBar: AppBar(title: const Text('PrismMasterDetail')),
      body: PrismMasterDetail<String>(
        items: items,
        masterBuilder: (context, item, selected) => ListTile(
          selected: selected,
          leading: const Icon(Icons.chat_bubble_outline),
          title: Text(item),
          subtitle: const Text('Last message preview…'),
        ),
        detailBuilder: (context, item) =>
            Center(child: Text('Detail of $item')),
        empty: (context) => const Center(child: Text('Pick a conversation')),
      ),
    );
  }
}

// ─── Adaptive dialog ────────────────────────────────────────────────────────

class DialogDemo extends StatelessWidget {
  const DialogDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismAdaptiveDialog')),
      body: Center(
        child: FilledButton(
          onPressed: () async {
            final ok = await PrismAdaptiveDialog.show<bool>(
              context,
              builder: (context) => AlertDialog(
                title: const Text('Delete conversation?'),
                content: const Text('This action cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            );
            if (!context.mounted) return;
            if (ok ?? false) {
              PrismToast.success(context, 'Deleted');
            }
          },
          child: const Text('Show adaptive dialog'),
        ),
      ),
    );
  }
}

// ─── State views ────────────────────────────────────────────────────────────

class StateViewsDemo extends StatefulWidget {
  const StateViewsDemo({super.key});

  @override
  State<StateViewsDemo> createState() => _StateViewsDemoState();
}

class _StateViewsDemoState extends State<StateViewsDemo> {
  late final PrismViewStateNotifier<List<String>> _notifier;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _notifier = PrismViewStateNotifier<List<String>>.fromFuture(_mockLoad());
    _cycle();
  }

  static Future<List<String>> _mockLoad() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    return const ['Note A', 'Note B', 'Note C'];
  }

  Future<void> _cycle() async {
    while (mounted) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      _step = (_step + 1) % 4;
      switch (_step) {
        case 0:
          _notifier.value = const PrismViewLoading();
        case 1:
          _notifier.value = const PrismViewSuccess([
            'Note A',
            'Note B',
            'Note C',
          ]);
        case 2:
          _notifier.value = const PrismViewEmpty();
        case 3:
          _notifier.value = PrismViewError(StateError('Network unavailable'));
      }
    }
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismStateView (auto-cycling)')),
      body: ValueListenableBuilder(
        valueListenable: _notifier,
        builder: (context, state, _) => PrismStateView<List<String>>(
          state: state,
          successBuilder: (notes) => ListView(
            children: [for (final n in notes) ListTile(title: Text(n))],
          ),
        ),
      ),
    );
  }
}

// ─── Palette ────────────────────────────────────────────────────────────────

class PaletteDemo extends StatelessWidget {
  const PaletteDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = <Color>[
      const Color(0xFF39A9DB),
      const Color(0xFFF39237),
      const Color(0xFF2E7D5B),
      const Color(0xFFB04141),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('PrismPalette')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'PrismPalette.fromImage(image) extracts:\n'
              'vibrant, muted, dominant colors + text contrast pairs.\n\n'
              'Sample extracted swatches:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              children: [
                for (final c in colors)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Changelog ──────────────────────────────────────────────────────────────

class ChangelogDemo extends StatelessWidget {
  const ChangelogDemo({super.key});

  static const _changelog = '''
# Changelog

## 2.1.0 - 2026-10-30

### Added
- Dark mode support
- Faster sync engine

### Fixed
- Crash when opening locked notes

## 2.0.0 - 2026-09-12

### Added
- End-to-end encryption
''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ChangelogView')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ChangelogView(
            changelog: _changelog,
            highlightVersion: '2.1.0',
            bulletBuilder: (bullet) => PrismMarkdown(bullet),
          ),
        ],
      ),
    );
  }
}

// ─── AI chat ────────────────────────────────────────────────────────────────

class AiDemo extends StatelessWidget {
  const AiDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismAi')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.smart_toy_outlined, size: 48),
              SizedBox(height: 16),
              Text(
                'Provider-agnostic streaming AI chat.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'PrismAiChatView gives you a complete streaming chat UI.\n\n'
                'Plug in any provider:\n\n'
                'OpenAiStreamClient(baseUrl: "https://api.openai.com/v1", apiKey: "sk-…")\n'
                'OpenAiStreamClient(baseUrl: "http://localhost:11434/v1")  // Ollama\n'
                'GeminiStreamClient(apiKey: "…")\n'
                'AnthropicStreamClient(apiKey: "…")\n\n'
                '…or implement AiStreamClient for anything else.\n'
                'Includes SSE parsing, typed events (AiDelta, AiToolCall, AiDone),\n'
                'and an automatic tool-calling loop (AiAgent).',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton ───────────────────────────────────────────────────────────────

class SkeletonDemo extends StatelessWidget {
  const SkeletonDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismSkeleton')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Text('Card skeleton — keeps the page shape while loading'),
          SizedBox(height: 12),
          PrismSkeletonCard(mediaHeight: 140, lines: 3),
          SizedBox(height: 24),
          Text('Tile list skeleton'),
          SizedBox(height: 12),
          PrismSkeletonList.tiles(count: 3),
          SizedBox(height: 24),
          Text('Text + circle primitives'),
          SizedBox(height: 12),
          Row(
            children: [
              PrismSkeleton.circle(diameter: 44),
              SizedBox(width: 12),
              Expanded(
                child: PrismSkeletonText(lines: 2, lastLineFraction: 0.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Avatar ─────────────────────────────────────────────────────────────────

class AvatarDemo extends StatelessWidget {
  const AvatarDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismAvatar')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Initials are derived automatically and the colour is '
            'stable for a given name.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              PrismAvatar(name: 'Ayesha Khan'),
              PrismAvatar(name: 'Bilal Ahmed', size: 48),
              PrismAvatar(name: 'Chen Wei', size: 56),
              PrismAvatar(name: 'Dana Malik', size: 64),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Presence indicators'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: const [
              PrismAvatar(name: 'Online User', presence: PrismPresence.online),
              PrismAvatar(name: 'Away User', presence: PrismPresence.away),
              PrismAvatar(name: 'Busy User', presence: PrismPresence.busy),
              PrismAvatar(
                name: 'Offline User',
                presence: PrismPresence.offline,
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Rounded shape for teams and badges'),
          const SizedBox(height: 12),
          Row(
            children: [
              const PrismAvatar(
                name: 'Acme Inc',
                size: 48,
                shape: PrismAvatarShape.rounded,
              ),
              const SizedBox(width: 12),
              const PrismAvatar(
                name: 'Ayesha Khan',
                size: 48,
                borderWidth: 2,
                badge: Icon(Icons.verified, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Chip input ─────────────────────────────────────────────────────────────

class ChipInputDemo extends StatefulWidget {
  const ChipInputDemo({super.key});

  @override
  State<ChipInputDemo> createState() => _ChipInputDemoState();
}

class _ChipInputDemoState extends State<ChipInputDemo> {
  List<String> _tags = ['flutter', 'open-source'];
  List<String> _limited = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismChipInput')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PrismChipInput(
            label: 'Tags',
            hint: 'Type and press Enter…',
            value: _tags,
            suggestions: const [
              'dart',
              'flutter',
              'ui',
              'mobile',
              'web',
              'api',
            ],
            helperText: 'Paste a comma-separated list to add several at once.',
            onChanged: (next) => setState(() => _tags = next),
          ),
          const SizedBox(height: 32),
          PrismChipInput(
            label: 'Up to 3 (no duplicates)',
            value: _limited,
            maxChips: 3,
            onChanged: (next) => setState(() => _limited = next),
          ),
        ],
      ),
    );
  }
}

// ─── OTP field ──────────────────────────────────────────────────────────────

class OtpDemo extends StatefulWidget {
  const OtpDemo({super.key});

  @override
  State<OtpDemo> createState() => _OtpDemoState();
}

class _OtpDemoState extends State<OtpDemo> {
  String? _error;
  String _code = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismOtpField')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text('Six-digit code — paste works, and it auto-submits.'),
          const SizedBox(height: 20),
          PrismOtpField(
            length: 6,
            groupSeparatorAfter: 3,
            errorText: _error,
            helperText: 'Hint: 123456 is accepted',
            onChanged: (v) => setState(() {
              _code = v;
              _error = null;
            }),
            onCompleted: (code) {
              setState(() {
                _error = code == '123456' ? null : 'That code is not valid';
              });
              if (code == '123456') {
                PrismToast.success(context, 'Code accepted');
              }
            },
          ),
          const SizedBox(height: 32),
          const Text('Obscured PIN variant'),
          const SizedBox(height: 12),
          const PrismOtpField(length: 4, obscure: true, autofocus: false),
          const SizedBox(height: 20),
          Text('Current value: ${_code.isEmpty ? '—' : _code}'),
        ],
      ),
    );
  }
}

// ─── Timeline ───────────────────────────────────────────────────────────────

class TimelineDemo extends StatelessWidget {
  const TimelineDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismTimeline')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PrismTimeline(
            entries: [
              const PrismTimelineEntry(
                title: 'Order placed',
                subtitle: 'Payment confirmed',
                timestamp: 'Today, 09:12',
                semantic: PrismSemantic.success,
              ),
              const PrismTimelineEntry(
                title: 'Packed',
                timestamp: 'Today, 10:04',
                icon: Icons.inventory_2_outlined,
              ),
              PrismTimelineEntry(
                title: 'Out for delivery',
                subtitle: 'Driver Sam · 2 stops away',
                timestamp: 'Today, 11:30',
                isActive: true,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: const Text('Track live'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ),
              ),
              const PrismTimelineEntry(
                title: 'Delivery attempt failed',
                subtitle: 'No one home — will retry tomorrow',
                timestamp: 'Today, 14:15',
                semantic: PrismSemantic.error,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stepper ────────────────────────────────────────────────────────────────

class StepperDemo extends StatefulWidget {
  const StepperDemo({super.key});

  @override
  State<StepperDemo> createState() => _StepperDemoState();
}

class _StepperDemoState extends State<StepperDemo> {
  int _index = 1;
  final _errored = <int>{};

  static const _steps = [
    PrismStep(title: 'Account', subtitle: 'Email & password'),
    PrismStep(title: 'Profile', subtitle: 'Name & photo'),
    PrismStep(
      title: 'Preferences',
      subtitle: 'Notifications',
      isOptional: true,
    ),
    PrismStep(title: 'Done'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismStepper')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PrismStepper(
              steps: _steps,
              currentIndex: _index,
              erroredIndices: _errored,
              onStepTapped: (i) => setState(() => _index = i),
            ),
            const SizedBox(height: 40),
            const Text(
              'Resize the window: the stepper collapses to a compact '
              '"Step X of Y" header with a progress bar.',
            ),
            const Spacer(),
            Row(
              children: [
                OutlinedButton(
                  onPressed: _index == 0
                      ? null
                      : () => setState(() => _index--),
                  child: const Text('Back'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      if (_index == 1) {
                        _errored.add(1);
                      } else {
                        _errored.clear();
                        if (_index < _steps.length - 1) _index++;
                      }
                    });
                  },
                  child: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data table ─────────────────────────────────────────────────────────────

class DataTableDemo extends StatelessWidget {
  const DataTableDemo({super.key});

  static final _invoices = [
    _Invoice('INV-1042', 'Zenith Ltd', 1240, 'Paid'),
    _Invoice('INV-1043', 'Aurora Media', 380, 'Overdue'),
    _Invoice('INV-1044', 'Meridian Co', 915, 'Paid'),
    _Invoice('INV-1045', 'Northwind', 2100, 'Draft'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismDataTable')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PrismDataTable<_Invoice>(
            rows: _invoices,
            onRowTap: (row, i) => PrismToast.info(context, 'Opened ${row.id}'),
            columns: [
              PrismColumn<_Invoice>(
                label: 'Invoice',
                alwaysVisible: true,
                cell: (c, r, i) => Text(r.id),
                sortComparator: (a, b) => a.id.compareTo(b.id),
              ),
              PrismColumn<_Invoice>(
                label: 'Client',
                cell: (c, r, i) => Text(r.client),
                sortComparator: (a, b) => a.client.compareTo(b.client),
              ),
              PrismColumn<_Invoice>(
                label: 'Status',
                cell: (c, r, i) => Chip(
                  label: Text(r.status),
                  visualDensity: VisualDensity.compact,
                ),
              ),
              PrismColumn<_Invoice>(
                label: 'Total',
                numeric: true,
                cell: (c, r, i) => Text('\$${r.total}'),
                sortComparator: (a, b) => a.total.compareTo(b.total),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tap a header to sort. On a narrow window the same data '
            'becomes labelled cards.',
          ),
        ],
      ),
    );
  }
}

class _Invoice {
  const _Invoice(this.id, this.client, this.total, this.status);
  final String id;
  final String client;
  final int total;
  final String status;
}

// ─── Command palette ────────────────────────────────────────────────────────

class CommandPaletteDemo extends StatelessWidget {
  const CommandPaletteDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismCommandPalette')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.keyboard_command_key, size: 48),
            const SizedBox(height: 16),
            const Text(
              'A ⌘K-style launcher with fuzzy search,\ngrouping and '
              'full keyboard navigation.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _open(context),
              icon: const Icon(Icons.search),
              label: const Text('Open palette'),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    PrismCommandPalette.show(
      context: context,
      commands: [
        PrismCommand(
          label: 'New note',
          subtitle: 'Create a blank note',
          icon: Icons.note_add_outlined,
          group: 'File',
          shortcut: '⌘N',
          keywords: const ['create', 'add'],
          onSelect: () => PrismToast.success(context, 'New note'),
        ),
        PrismCommand(
          label: 'Search notes',
          icon: Icons.search,
          group: 'File',
          shortcut: '⌘F',
          onSelect: () => PrismToast.info(context, 'Search'),
        ),
        PrismCommand(
          label: 'Toggle dark mode',
          icon: Icons.dark_mode_outlined,
          group: 'View',
          keywords: const ['theme', 'appearance'],
          onSelect: () => PrismToast.info(context, 'Theme toggled'),
        ),
        PrismCommand(
          label: 'Export as markdown',
          icon: Icons.download_outlined,
          group: 'Share',
          keywords: const ['save', 'download'],
          onSelect: () => PrismToast.info(context, 'Exported'),
        ),
        PrismCommand(
          label: 'Sign out',
          icon: Icons.logout,
          group: 'Account',
          onSelect: () => PrismToast.warning(context, 'Signed out'),
        ),
      ],
    );
  }
}

// ─── Adaptive sheet ─────────────────────────────────────────────────────────

class AdaptiveSheetDemo extends StatelessWidget {
  const AdaptiveSheetDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismAdaptiveSheet')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'On a phone this slides up from the bottom.\n'
                'On a wide window it becomes a centred dialog.\n\n'
                'Resize the window and try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => _open(context),
                child: const Text('Show sheet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final confirmed = await PrismAdaptiveSheet.show<bool>(
      context: context,
      title: 'Delete this note?',
      subtitle: 'The note will move to Trash for 30 days.',
      child: const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          'You can restore it any time from the Trash, or delete it '
          'permanently right away.',
        ),
      ),
      actions: [
        const PrismSheetAction(label: 'Cancel', value: false),
        PrismSheetAction(
          label: 'Delete',
          value: true,
          isDestructive: true,
          icon: Icons.delete_outline,
        ),
      ],
    );
    if (!context.mounted) return;
    if (confirmed ?? false) {
      PrismToast.success(context, 'Note deleted');
    }
  }
}

// ─── Connection banner ──────────────────────────────────────────────────────

class ConnectionDemo extends StatefulWidget {
  const ConnectionDemo({super.key});

  @override
  State<ConnectionDemo> createState() => _ConnectionDemoState();
}

class _ConnectionDemoState extends State<ConnectionDemo> {
  final _controller = StreamController<bool>.broadcast();
  bool _online = true;

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismConnectionBanner')),
      body: Column(
        children: [
          PrismConnectionBanner(
            source: () => _controller.stream,
            onlineMessage: 'Back online — syncing…',
            retryLabel: 'Retry now',
            onRetry: () => PrismToast.info(context, 'Retrying…'),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_online ? 'Simulated: online' : 'Simulated: offline'),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () {
                      _online = !_online;
                      _controller.add(_online);
                      setState(() {});
                    },
                    child: Text(_online ? 'Go offline' : 'Go online'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Design tokens ──────────────────────────────────────────────────────────

class TokensDemo extends StatelessWidget {
  const TokensDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.prismTokens;
    final colors = context.prismColors;

    Widget swatch(String label, Color color, Color onColor) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(tokens.radiusMd),
      ),
      child: Text(label, style: TextStyle(color: onColor, fontSize: 12)),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Prism design tokens')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Semantic colors',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final role in PrismSemantic.values)
                swatch(
                  role.name,
                  colors.forRole(role).background,
                  colors.forRole(role).foreground,
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Spacing scale', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final (name, value) in [
            ('spaceXs', tokens.spaceXs),
            ('spaceSm', tokens.spaceSm),
            ('spaceMd', tokens.spaceMd),
            ('spaceLg', tokens.spaceLg),
            ('spaceXl', tokens.spaceXl),
            ('spaceXxl', tokens.spaceXxl),
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(width: 90, child: Text(name)),
                  Container(height: 14, width: value * 4, color: colors.info),
                  const SizedBox(width: 8),
                  Text(value.toStringAsFixed(0)),
                ],
              ),
            ),
          const SizedBox(height: 24),
          Text('Corner radii', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              for (final (name, value) in [
                ('sm', tokens.radiusSm),
                ('md', tokens.radiusMd),
                ('lg', tokens.radiusLg),
                ('xl', tokens.radiusXl),
              ])
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: colors.surfaceSunken,
                    borderRadius: BorderRadius.circular(value),
                    border: Border.all(color: colors.outline),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$name\n${value.toStringAsFixed(0)}',
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('Motion', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            'fast ${tokens.durationFast.inMilliseconds} ms · '
            'medium ${tokens.durationMedium.inMilliseconds} ms · '
            'slow ${tokens.durationSlow.inMilliseconds} ms',
          ),
          const SizedBox(height: 24),
          Text(
            'Override any of these in ThemeData.extensions: const '
            '[PrismTokens(spaceMd: 20, radiusMd: 16)].',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// ─── AI message bubble ──────────────────────────────────────────────────────

class AiBubbleDemo extends StatelessWidget {
  const AiBubbleDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI message bubble')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PrismAiMessageBubble(
            message: AiChatMessage.user('Summarise this article for me.'),
          ),
          const SizedBox(height: 12),
          PrismAiMessageBubble(
            message: AiChatMessage.assistant(
              '## Summary\n\nThe article argues that **adaptive layouts** '
              'beat one-size-fits-all design. Key points:\n\n'
              '- Phones get stacked flows\n'
              '- Desktop gets side-by-side panes',
            ),
            onCopy: () {},
            onRegenerate: () {},
          ),
          const SizedBox(height: 12),
          PrismAiMessageBubble(
            message: AiChatMessage.assistantWithToolCalls(const [
              AiToolCallRequest(
                id: 't1',
                name: 'fetch_weather',
                argumentsJson: '{}',
              ),
            ], content: 'Checking the weather…'),
          ),
          const SizedBox(height: 12),
          PrismAiMessageBubble(
            message: AiChatMessage.assistant(''),
            isStreaming: true,
            thinkingLabel: 'Thinking…',
          ),
        ],
      ),
    );
  }
}

// ─── AI composer ────────────────────────────────────────────────────────────

class AiComposerDemo extends StatefulWidget {
  const AiComposerDemo({super.key});

  @override
  State<AiComposerDemo> createState() => _AiComposerDemoState();
}

class _AiComposerDemoState extends State<AiComposerDemo> {
  final _log = <String>[];
  bool _busy = false;

  Future<void> _send(String text) async {
    setState(() {
      _busy = true;
      _log.insert(0, 'You: $text');
    });
    await Future<void>.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _busy = false;
        _log.insert(0, 'Assistant: (demo) You said "$text".');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI composer')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [for (final line in _log) Text(line)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: PrismPromptComposer(
              busy: _busy,
              suggestions: const ['Summarise', 'Translate', 'Explain simply'],
              onSend: _send,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Color picker ───────────────────────────────────────────────────────────

class ColorPickerDemo extends StatefulWidget {
  const ColorPickerDemo({super.key});

  @override
  State<ColorPickerDemo> createState() => _ColorPickerDemoState();
}

class _ColorPickerDemoState extends State<ColorPickerDemo> {
  Color _color = const Color(0xFF39A9DB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Color picker')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            height: 80,
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(height: 24),
          PrismColorPicker(
            color: _color,
            onChanged: (c) => setState(() => _color = c),
          ),
        ],
      ),
    );
  }
}

// ─── Overlay tour ───────────────────────────────────────────────────────────

class OverlayTourDemo extends StatefulWidget {
  const OverlayTourDemo({super.key});

  @override
  State<OverlayTourDemo> createState() => _OverlayTourDemoState();
}

class _OverlayTourDemoState extends State<OverlayTourDemo> {
  final _fab = GlobalKey();
  final _appBar = GlobalKey();
  bool _tourDone = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: KeyedSubtree(key: _appBar, child: const Text('Overlay tour')),
      ),
      body: Center(
        child: Text(
          _tourDone
              ? 'Tour complete ✓'
              : 'A tour will spotlight this app bar and the FAB.',
          textAlign: TextAlign.center,
        ),
      ),
      floatingActionButton: FloatingActionButton(
        key: _fab,
        onPressed: () => setState(() => _tourDone = false),
        child: const Icon(Icons.add),
      ),
      persistentFooterButtons: [
        TextButton(
          onPressed: () => setState(() => _tourDone = false),
          child: const Text('Replay tour'),
        ),
      ],
    );
  }
}

// ─── Sparkline ──────────────────────────────────────────────────────────────

class SparklineDemo extends StatelessWidget {
  const SparklineDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sparkline')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          PrismCard(
            child: ListTile(
              title: const Text('Revenue this week'),
              subtitle: const Text('+12% vs last week'),
              trailing: const PrismSparkline(
                values: [120, 132, 128, 141, 150, 148, 166],
                semantic: PrismSemantic.success,
              ),
            ),
          ),
          const SizedBox(height: 12),
          PrismCard(
            child: ListTile(
              title: const Text('Errors this week'),
              subtitle: const Text('-40% — trending down'),
              trailing: const PrismSparkline(
                values: [20, 18, 19, 15, 12, 10, 8],
                semantic: PrismSemantic.error,
                fill: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
