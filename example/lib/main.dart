// Prism example gallery — demo screens for every component.
//
// Run: `flutter run` inside this folder, then tap a component from the
// grid. Each demo is a minimal, copy-pasteable snippet.

import 'package:flutter/material.dart';

import 'package:prism/prism.dart';

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

  @override
  Widget build(BuildContext context) {
    final demos = <(String, IconData, Widget Function())>[
      ('Adaptive scaffold', Icons.smartphone, () => const ScaffoldDemo()),
      ('Toast', Icons.notifications_none, () => const ToastDemo()),
      ('Banner', Icons.campaign_outlined, () => const BannerDemo()),
      ('Search', Icons.search, () => const SearchDemo()),
      ('Settings', Icons.settings_outlined, () => const SettingsDemo()),
      ('Markdown', Icons.article_outlined, () => const MarkdownDemo()),
      ('Code view', Icons.code, () => const CodeDemo()),
      ('Form', Icons.edit_note, () => const FormDemo()),
      ('Pagination', Icons.menu, () => const PaginationDemo()),
      ('Master-detail', Icons.view_agenda_outlined, () => const MasterDetailDemo()),
      ('Adaptive dialog', Icons.open_in_full, () => const DialogDemo()),
      ('State views', Icons.extension_outlined, () => const StateViewsDemo()),
      ('Palette', Icons.palette_outlined, () => const PaletteDemo()),
      ('AI chat', Icons.smart_toy_outlined, () => const AiDemo()),
    ];

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
                  MaterialPageRoute<void>(builder: (_) => builder()),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 32),
                      const SizedBox(height: 8),
                      Text(name, textAlign: TextAlign.center),
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

// ─── Demos ──────────────────────────────────────────────────────────────────

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
          ],
        ),
      ),
    );
  }
}

class BannerDemo extends StatelessWidget {
  const BannerDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismBanner')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: PrismBanner(
            announcements: [
              PrismAnnouncement(
                id: 'welcome-1',
                title: 'Announcement',
                message: 'This is what an announcement banner looks like.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchDemo extends StatelessWidget {
  const SearchDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(40, (i) => 'Fruit #${i + 1}');
    return Scaffold(
      appBar: AppBar(title: const Text('PrismSearch')),
      body: PrismSearch<String>(
        items: items,
        itemLabel: (item) => item,
        onSelected: (item) {},
      ),
    );
  }
}

class SettingsDemo extends StatelessWidget {
  const SettingsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismSettingsPage')),
      body: PrismSettingsPage(sections: const [
        PrismSettingsSection(
          title: 'General',
          tiles: [
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
      ]),
    );
  }
}

class MarkdownDemo extends StatelessWidget {
  const MarkdownDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismMarkdown')),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: PrismMarkdown('# Hello Prism\n\n- Rich **markdown** rendering\n- [Links](https://flutter.dev)\n- `inline code`'),
      ),
    );
  }
}

class CodeDemo extends StatelessWidget {
  const CodeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismCodeView')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: PrismCodeView(
            code: "void main() {\n  print('Hello, Prism!');\n}",
          ),
        ),
      ),
    );
  }
}

class FormDemo extends StatelessWidget {
  const FormDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismForm')),
      body: const Center(child: Text('PrismForm — declarative forms')),
    );
  }
}

class PaginationDemo extends StatelessWidget {
  const PaginationDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismPagination')),
      body: const Center(child: Text('PrismPagination — infinite scroll lists')),
    );
  }
}

class MasterDetailDemo extends StatelessWidget {
  const MasterDetailDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismMasterDetail')),
      body: const Center(child: Text('PrismMasterDetail — responsive two-pane layout')),
    );
  }
}

class DialogDemo extends StatelessWidget {
  const DialogDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismAdaptiveDialog')),
      body: Center(
        child: FilledButton(
          onPressed: () => showAdaptiveDialog<void>(
            context: context,
            builder: (_) => const AlertDialog(
              title: Text('Adaptive dialog'),
              content: Text('Adapts to the platform automatically.'),
            ),
          ),
          child: const Text('Show dialog'),
        ),
      ),
    );
  }
}

class StateViewsDemo extends StatelessWidget {
  const StateViewsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismStateViews')),
      body: const Center(child: Text('Loading / empty / error state views')),
    );
  }
}

class PaletteDemo extends StatelessWidget {
  const PaletteDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismPalette')),
      body: const Center(child: Text('Dynamic palette generation')),
    );
  }
}

class AiDemo extends StatelessWidget {
  const AiDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PrismAiChatView')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'PrismAi — provider-agnostic streaming AI chat.\n\n'
            'Configure an API key (OpenAI, Ollama, Groq…) and plug in '
            'PrismAiChatView for a full chat experience.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class ScaffoldDemo extends StatelessWidget {
  const ScaffoldDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return PrismAdaptiveScaffold(
      destinations: const [
        AdaptiveDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
        AdaptiveDestination(icon: Icons.search_outlined, selectedIcon: Icons.search, label: 'Search'),
        AdaptiveDestination(icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings'),
      ],
      bodyBuilder: (i) => Center(child: Text('Page $i')),
    );
  }
}
