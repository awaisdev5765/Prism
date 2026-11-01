<p align="center">
  <img width="720" alt="Prism" src="https://img.shields.io/badge/Prism-17%20adaptive%20Flutter%20components-39A9DB?style=for-the-badge">
</p>

<h1 align="center">🔷 Prism</h1>
<h3 align="center">One dependency. 17 adaptive Flutter components. Native feel on phone, desktop & web.</h3>

<p align="center">
  <img src="https://img.shields.io/badge/pub.dev-prism__kit-0175C2?logo=dart&logoColor=white" alt="pub.dev">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="MIT">
  <img src="https://img.shields.io/badge/Flutter-3.27%2B-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/tests-252%20passing-brightgreen" alt="tests">
</p>

---

**Prism** is a component library for Flutter that removes the most repetitive parts of app building. Instead of assembling a dozen fragmented pub.dev packages — each with its own style, API and quirks — you install one package and get a coherent, cross-platform toolkit:

- **Adaptive by default** — every component responds to window size and target platform. A toast is bottom-centered on a phone and stacked top-right on a desktop window. A settings page becomes a two-pane layout on tablets. A dialog renders Material on Android and Cupertino-style behavior on macOS — from a single call.
- **Local-first & privacy-friendly** — persistence uses `shared_preferences` on-device; no accounts, no telemetry, no network calls unless you explicitly opt in (the AI client and updater are the only networked parts, and you own the endpoints).
- **Zero heavy dependencies** — only `http`, `markdown`, `shared_preferences`, `url_launcher`, `meta` and `material_color_utilities`.
- **Battle-tested** — 252 unit & widget tests, analyzed clean.

## 📦 Install

```yaml
dependencies:
  prism_kit: ^1.0.0
```

```bash
flutter pub add prism_kit
```

One import gives you everything:

```dart
import 'package:prism_kit/prism.dart';
```

## 🧩 Components

| # | Component | One-liner |
|---|---|---|
| 1 | **AdaptiveScaffold** | Bottom nav bar → navigation rail → expanded rail, by window width |
| 2 | **AdaptiveDialog** | Platform-adaptive dialogs from a single call |
| 3 | **PrismAi** | Provider-agnostic streaming AI chat: OpenAI, Ollama, Groq, DeepSeek, Gemini, Anthropic — with typed events, tool-calling loop and a ready chat view |
| 4 | **Banner** | Dismissible announcement banners; dismissals persist across restarts |
| 5 | **Changelog** | Parse a Keep-a-Changelog markdown file into collapsible "What's new" cards |
| 6 | **CodeView** | Syntax-highlighted, copyable code viewer with pluggable tokenizers |
| 7 | **Form** | Declarative forms: fields, validators, submit lifecycle states |
| 8 | **Image** | Retrying network image provider with configurable backoff strategy |
| 9 | **Markdown** | Fast, plugin-free CommonMark + GFM renderer with syntax highlighting |
| 10 | **MasterDetail** | Responsive two-pane layouts (list → detail) that push on compact windows |
| 11 | **Pagination** | Infinite-scroll list with page loader, empty/error/retry states |
| 12 | **Palette** | Extract dominant/vibrant/muted color palettes from images |
| 13 | **Search** | Adaptive search: local datasets or debounced async backends |
| 14 | **Settings** | iOS-style grouped settings pages with searchable tiles |
| 15 | **StateViews** | Loading / empty / error / success state widgets driven by one notifier |
| 16 | **Toast** | Adaptive toasts: bottom-centered on mobile, stacked top-right on desktop |
| 17 | **Updater** | In-app update flow: version gates, rollouts, skip-version, download progress |

---

## 🚀 Usage

Every snippet below is copy-pasteable and matches the shipped API.

### AdaptiveScaffold — responsive navigation

Renders a `NavigationBar` under 600 dp, a `NavigationRail` up to 839 dp and an expanded labeled rail beyond:

```dart
PrismAdaptiveScaffold(
  destinations: const [
    AdaptiveDestination(icon: Icons.home_outlined, selectedIcon: Icons.home, label: 'Home'),
    AdaptiveDestination(icon: Icons.search_outlined, selectedIcon: Icons.search, label: 'Search'),
    AdaptiveDestination(icon: Icons.settings_outlined, label: 'Settings'),
  ],
  bodyBuilder: (index) => const Center(child: Text('Page')),
)
```

### Toast — adaptive notifications

```dart
PrismToast.success(context, 'Saved successfully');
PrismToast.error(context, 'Something went wrong');
PrismToast.info(context, 'Heads up!');
PrismToast.warning(context, 'Low battery');

// Full control
PrismToast.show(
  context,
  const PrismToastMessage(
    message: 'Report synced',
    title: 'Done',
    duration: Duration(seconds: 5),
    actionLabel: 'View',
    onAction: openReport,
  ),
);
```

Position adapts automatically: bottom-centered on phones, stacked top-right where there's room.

### Banner — dismissible announcements

```dart
Column(
  children: [
    PrismBanner(
      announcements: const [
        PrismAnnouncement(
          id: 'release-2-1',            // reuse the id + bump version to re-show
          version: 2,
          title: 'New in 2.1',
          message: 'Dark mode and faster sync!',
          actionLabel: "See what's new",
          severity: PrismSeverity.info,
        ),
      ],
    ),
    // …the rest of your page…
  ],
)
```

Dismissals persist via `shared_preferences`. Banners can be scheduled (`startsAt`/`endsAt`) and prioritized (`newest`, `oldest`, `severity`).

### Search — local or backend

```dart
// Local dataset
PrismSearch<String>(
  items: const ['Dart', 'Flutter', 'Firebase'],
  itemLabel: (item) => item,
  onSelected: (item) => print('picked $item'),
)

// Debounced async backend
PrismSearch<City>(
  onSearch: (query) => api.searchCities(query),
  itemLabel: (city) => city.name,
  onSelected: (city) => go(city),
)
```

### Settings — grouped, searchable pages

```dart
final controller = PrismSettingsController();

PrismSettingsPage(
  controller: controller,
  searchable: true,
  sections: const [
    PrismSettingsSection(
      title: 'Appearance',
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
          onTap: openLanguagePicker,
        ),
      ],
    ),
  ],
)
```

Read & write values through the controller: `controller.set('dark-mode', true)` / `controller.get<bool>('dark-mode')`.

### Markdown + CodeView — rich content

```dart
PrismMarkdown('# Hello\n\n- **Rich** markdown\n- `inline code`')

PrismCodeView(code: "void main() => print('Hello');")
```

The markdown renderer is plugin-free (pure Dart CommonMark + GFM) and pairs perfectly with ChangelogView bullets.

### Form — declarative & validated

```dart
final controller = PrismFormController();

PrismForm(
  controller: controller,
  child: Column(children: [
    PrismTextField.email(name: 'email', label: 'Email'),
    PrismPasswordField(name: 'password', common: PrismFieldCommon(
      name: 'password', label: 'Password',
      validators: [Validators.required('Enter a password')],
    )),
    PrismDropdownField<String>(
      common: PrismFieldCommon(name: 'plan', label: 'Plan'),
      items: const ['Free', 'Pro'],
      itemBuilder: (plan) => plan,
    ),
    FilledButton(
      onPressed: () async {
        if (await controller.submit((values) => api.register(values))) {
          // success — status transitions surfaced via controller
        }
      },
      child: const Text('Create account'),
    ),
  ]),
)
```

Validators come from `Validators.required()`, `Validators.email()` etc., or you can pass any `(value) => messageOrNull` function. Submit runs all validations, then your action, and exposes typed statuses (`pristine`, `editing`, `submitting`, `success`, `failure`).

### StateViews — one widget, four states

```dart
final notifier = PrismViewStateNotifier<List<Note>>(const PrismViewLoading());

PrismStateView(
  state: notifier.value,
  successBuilder: (notes) => NotesList(notes),
  emptyMessage: 'No notes yet',
)
```

Transition with `notifier.value = PrismViewSuccess(data)` / `PrismViewError(error)` / `PrismViewEmpty()`.

### Pagination — infinite scroll

```dart
PrismPaginatedList<Msg>(
  pageLoader: (page) => api.fetchMessages(page),  // return [] to signal end
  itemBuilder: (context, msg, index) => MsgTile(msg),
)
```

First-load spinner, error state with retry, and "no more items" footer are handled for you.

### MasterDetail — two-pane layouts

```dart
PrismMasterDetail<Conversation>(
  items: conversations,
  masterBuilder: (context, conv, selected) => ConvTile(conv, selected: selected),
  detailBuilder: (context, conv) => ChatScreen(conv),
)
```

On compact windows it pushes a detail route (`PrismCompactBehavior.push`); on wide windows it becomes a side-by-side split with a configurable pane width.

### Palette — extract colors from images

```dart
final palette = await PrismPalette.fromImage(image);
final themeColor = palette.vibrantColor ?? palette.dominantColor;
```

### AI — streaming chat with any provider

```dart
final controller = AiChatController(
  client: OpenAiStreamClient(
    baseUrl: 'https://api.openai.com/v1',   // or http://localhost:11434/v1 (Ollama)
    apiKey: 'sk-…',
  ),
  model: 'gpt-4o-mini',
);

AiChatView(controller: controller)   // full streaming chat UI
```

Typed events (`AiDelta`, `AiToolCall`, `AiDone`, `AiError`), SSE parsing, and an automatic tool-calling agent loop (`AiAgent`) are included. Swap in `GeminiStreamClient`, `AnthropicStreamClient`, or implement `AiStreamClient` for anything else.

### Updater — in-app updates

```dart
PrismUpdateController(
  source: RemoteUpdateSource(url: 'https://example.com/updates.json'),
  // updates.json: {"versions": {"1.1.0": {"notes": "...", "url": "..."}}}
)
```

Handles version comparison, staged rollouts, skip-version persistence and download progress events.

### ChangelogView — What's new

```dart
ChangelogView(
  changelog: await rootBundle.loadString('CHANGELOG.md'),
  highlightVersion: '2.1.0',
)
```

Parses Keep-a-Changelog format into collapsible version cards; `WhatsNewSheet` shows it as a modal.

---

## 🖥 Platform support

| Component | Android | iOS | macOS | Windows | Linux | Web |
|---|:---:|:---:|:---:|:---:|:---:|:---:|
| AdaptiveScaffold / MasterDetail / Dialog | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Toast / Banner / StateViews / Pagination | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Search / Settings / Form | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Markdown / CodeView / Changelog / Palette | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Image (NetworkImageWithRetry) | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| AI client | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Updater | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## 🧪 Quality

- **252 tests** (unit + widget) across all components
- Zero analyzer issues; `flutter_lints` enforced
- Every public API documented

## 🧭 Migrating from the standalone packages

If you previously used an individual `prism_*` package, swap the dependency and change one import:

```diff
- prism_toast: ^0.1.0
+ prism_kit: ^1.0.0

- import 'package:prism_toast/prism_toast.dart';
+ import 'package:prism_kit/prism.dart';
```

All class names stay identical (`PrismToast`, `PrismBanner`, `PrismSearch`, …).

## 📖 Full example

The [`example/`](example/) folder contains a **gallery app** with an interactive demo for every component — run it with:

```bash
cd example && flutter run
```

## 🤝 Contributing

Issues and PRs welcome — pick a component and improve it: [github.com/awaisdev5765/Prism](https://github.com/awaisdev5765/Prism).

## ☕ Support

If Prism helps you ship faster, please consider supporting my work:

<p align="center">
  <a href="https://buymeacoffee.com/awaisdev572">
    <img src="https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=%E2%98%95&slug=awaisdev572&button_colour=FFDD00&font_colour=000000&font_family=Lato&outline_colour=000000&coffee_colour=ffffff" alt="Buy Me A Coffee">
  </a>
</p>

## 📄 License

MIT — see [LICENSE](LICENSE).
