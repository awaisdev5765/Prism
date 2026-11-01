// Prism gallery — interactive demos for every component.
//
// Run: `flutter run` inside this folder, then tap a component from the
// grid. Every demo is a working, copy-pasteable snippet using the real API.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:prism_kit/prism.dart';

void main() => runApp(const PrismGalleryApp());

class PrismGalleryApp extends StatelessWidget {
  const PrismGalleryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prism gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF39A9DB)),
      darkTheme: ThemeData(
        colorSchemeSeed: const Color(0xFF39A9DB),
        brightness: Brightness.dark,
      ),
      home: const GalleryHome(),
    );
  }
}

class GalleryHome extends StatelessWidget {
  const GalleryHome({super.key});

  static final demos = <(String, IconData, WidgetBuilder)>[
    ('Adaptive scaffold', Icons.smartphone, _build(ScaffoldDemo())),
    ('Toast', Icons.notifications_none, _build(ToastDemo())),
    ('Banner', Icons.campaign_outlined, _build(BannerDemo())),
    ('Search', Icons.search, _build(SearchDemo())),
    ('Settings', Icons.settings_outlined, _build(SettingsDemo())),
    ('Markdown', Icons.article_outlined, _build(MarkdownDemo())),
    ('Code view', Icons.code, _build(CodeDemo())),
    ('Form', Icons.edit_note, _build(FormDemo())),
    ('Pagination', Icons.menu, _build(PaginationDemo())),
    ('Master-detail', Icons.view_agenda_outlined, _build(MasterDetailDemo())),
    ('Adaptive dialog', Icons.open_in_full, _build(DialogDemo())),
    ('State views', Icons.extension_outlined, _build(StateViewsDemo())),
    ('Palette', Icons.palette_outlined, _build(PaletteDemo())),
    ('Changelog', Icons.history, _build(ChangelogDemo())),
    ('AI chat', Icons.smart_toy_outlined, _build(AiDemo())),
  ];

  static WidgetBuilder _build(Widget widget) => (_) => widget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prism gallery')),
      body: GridView.count(
        crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 3 : 2,
        padding: const EdgeInsets.all(16),
        children: [
          for (final (name, icon, builder) in demos)
            Card(
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: builder),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 32),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(name, textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
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
        AdaptiveDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
        AdaptiveDestination(icon: Icons.search_outlined, selectedIcon: Icons.search, label: 'Search'),
        AdaptiveDestination(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
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
              onPressed: () => PrismToast.success(context, 'Saved successfully'),
              child: const Text('Success'),
            ),
            FilledButton(
              onPressed: () => PrismToast.error(context, 'Something went wrong'),
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
                message: 'Highest severity wins with PrismBannerPriority.severity.',
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
    'Apple', 'Apricot', 'Banana', 'Blueberry', 'Cherry', 'Cranberry',
    'Dragonfruit', 'Durian', 'Elderberry', 'Fig', 'Grape', 'Guava',
    'Kiwi', 'Lemon', 'Lime', 'Mango', 'Melon', 'Nectarine', 'Orange',
    'Papaya', 'Peach', 'Pear', 'Pineapple', 'Plum', 'Raspberry',
    'Strawberry', 'Tangerine', 'Watermelon',
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
          const Text('Built-in Dart & JSON tokenizers — bring your own with LanguageTokenizer.'),
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
                      _result = ok ? '✅ Account created!' : '❌ Check the fields';
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
        detailBuilder: (context, item) => Center(child: Text('Detail of $item')),
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
          _notifier.value = const PrismViewSuccess(['Note A', 'Note B', 'Note C']);
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
      const Color(0xFF39A9DB), const Color(0xFFF39237),
      const Color(0xFF2E7D5B), const Color(0xFFB04141),
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
                    decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(12)),
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
