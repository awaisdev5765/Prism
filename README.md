# 🔷 Prism

<p align="center">
  <b>A unified Flutter component library.</b><br/>
  Adaptive, Material-style widgets that feel native on phone, desktop and web.
</p>

[![pub.dev](https://img.shields.io/badge/pub.dev-prism-0175C2?logo=dart&logoColor=white)](https://pub.dev/packages/prism)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.27%2B-02569B?logo=flutter&logoColor=white)](https://flutter.dev)

---

Prism bundles **17 production-ready components** into one dependency — every widget adapts its layout to the platform it runs on, from a phone in your hand to a wide desktop window.

## 📦 Components

| Component | What it does |
|---|---|
| **AdaptiveScaffold** | Responsive scaffold: bottom nav → rail → expanded rail |
| **AdaptiveDialog** | Platform-adaptive dialogs from one call |
| **PrismAi** | Provider-agnostic streaming AI chat client (OpenAI, Ollama, Groq, DeepSeek…) |
| **Banner** | Dismissible announcement banners with persisted dismissals |
| **Changelog** | Parse & display CHANGELOG.md as beautiful cards |
| **CodeView** | Syntax-highlighted, copyable code viewer |
| **Form** | Declarative, validated forms |
| **Image** | Adaptive image view with zoom & gestures |
| **Markdown** | Fast, plugin-free CommonMark + GFM markdown renderer |
| **MasterDetail** | Responsive two-pane layouts |
| **Pagination** | Infinite-scroll list with loading/empty/error states |
| **Palette** | Dynamic color palette generation |
| **Search** | Adaptive search: local datasets or async backends |
| **Settings** | iOS-style grouped settings pages with searchable tiles |
| **StateViews** | Loading / empty / error state widgets |
| **Toast** | Adaptive toast notifications (bottom-center mobile, stacked top-right desktop) |
| **Updater** | In-app update flow with release notes |

## 🚀 Quick start

```yaml
dependencies:
  prism: ^1.0.0
```

```dart
import 'package:prism/prism.dart';

// A toast that adapts its position to the platform
PrismToast.success(context, 'Saved successfully');

// An announcement banner with persisted dismissal
PrismBanner(
  announcements: const [
    PrismAnnouncement(id: 'welcome-1', message: 'Welcome to the app!'),
  ],
)

// An adaptive search over a local dataset
PrismSearch<String>(
  items: const ['Dart', 'Flutter', 'Firebase'],
  itemLabel: (item) => item,
  onSelected: (item) => print('picked $item'),
)
```

Run the full gallery:

```bash
git clone https://github.com/awaisdev5765/prism.git
cd prism/example
flutter run
```

## 🎯 Why one package?

- **One dependency** instead of a dozen fragmented packages
- **Consistent design language** across every widget
- **Adaptive by default** — every component responds to window size and platform
- **Zero heavyweight dependencies** — only `http`, `markdown`, `shared_preferences`, `url_launcher` and friends

## 📄 License

MIT — see [LICENSE](LICENSE).

## ☕ Support

If Prism helps you ship faster, please consider supporting my work:

<p align="center">
  <a href="https://buymeacoffee.com/awaisdev572">
    <img src="https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=%E2%98%95&slug=awaisdev572&button_colour=FFDD00&font_colour=000000&font_family=Lato&outline_colour=000000&coffee_colour=ffffff" alt="Buy Me A Coffee">
  </a>
</p>

Or [become a supporter on Buy Me a Coffee](https://buymeacoffee.com/awaisdev572) 💛
