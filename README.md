<p align="center">
  <img width="720" alt="Prism" src="https://img.shields.io/badge/Prism-34%20adaptive%20Flutter%20components-39A9DB?style=for-the-badge">
</p>

<h1 align="center">🔷 Prism</h1>
<h3 align="center">One dependency. 34 adaptive Flutter components. Native feel on phone, desktop & web.</h3>

<p align="center">
  <img src="https://img.shields.io/badge/pub.dev-prism__kit-0175C2?logo=dart&logoColor=white" alt="pub.dev">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="MIT">
  <img src="https://img.shields.io/badge/Flutter-3.27%2B-02569B?logo=flutter&logoColor=white" alt="Flutter">
  <img src="https://img.shields.io/badge/tests-766%20passing-brightgreen" alt="tests">
</p>

---

**Prism** is a component library for Flutter that removes the most repetitive parts of app building. Instead of assembling a dozen fragmented pub.dev packages — each with its own style, API and quirks — you install one package and get a coherent, cross-platform toolkit with a shared design system:

- **Adaptive by default** — every component responds to window size and target platform. A toast is bottom-centered on a phone and stacked top-right on a desktop window. A settings page becomes a two-pane layout on tablets. A dialog renders Material on Android and Cupertino-style behavior on macOS — from a single call.
- **Local-first & privacy-friendly** — persistence uses `shared_preferences` on-device; no accounts, no telemetry, no network calls unless you explicitly opt in (the AI client and updater are the only networked parts, and you own the endpoints).
- **A real design system** — `PrismTokens` (spacing, radii, motion) and `PrismColors` (semantic roles) so every component shares one visual language and follows light/dark and Material You automatically.
- **Zero heavy dependencies** — only `http`, `markdown`, `shared_preferences`, `url_launcher`, `meta` and `material_color_utilities`.
- **Battle-tested** — 385 unit & widget tests, analyzed clean.

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
| 18 | **Skeleton** | Shimmering placeholders: text, card, tile list, circle — reduced-motion aware |
| 19 | **Avatar** | Image with deterministic initials fallback, presence dots and badges |
| 20 | **ChipInput** | Tag/token entry with paste splitting, duplicates, limits and suggestions |
| 21 | **OtpField** | OTP/PIN entry with paste, auto-submit, SMS autofill and grouping |
| 22 | **Timeline** | Vertical event timeline with connectors, semantic roles and rich nodes |
| 23 | **Stepper** | Wizard progress: horizontal on wide, compact "Step X of Y" on phones |
| 24 | **DataTable** | Sortable table that becomes labelled cards on narrow windows |
| 25 | **CommandPalette** | ⌘K launcher with fuzzy search, grouping and keyboard navigation |
| 26 | **AdaptiveSheet** | Bottom sheet on phones, centred dialog on desktop — one call |
| 27 | **ConnectionBanner** | Offline/online banner with debounce, retry and live-region announcements |
| 28 | **SyncStatus** | Compact, live-region sync indicator with progress, retry and six phases |
| 29 | **Calendar** | Month grid with single/range/multiple selection, markers and localisable names |
| 30 | **Tabs** | Adaptive tab strip: scrolls on phones, shares the width on desktop |
| 31 | **SegmentedControl** | Single-choice control that scrolls instead of overflowing |
| 32 | **Accordion** | Collapsible sections with single-expansion mode |
| 33 | **Rating** | Star rating with half values and full slider semantics |
| 34 | **Badge** | Count or status dot, collapsing to `99+` and hiding at zero |

### Design system

| | |
|---|---|
| **PrismTokens** | Spacing scale, corner radii, motion durations and breakpoints, installable via `ThemeData.extensions` |
| **PrismColors** | Semantic roles (success / warning / error / info) plus raised and sunken surfaces, derived from any `ColorScheme` |

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

Two helpers cover the parts that always get written badly:

```dart
// Models rarely return bare JSON — fenced, prefixed with "Here is the JSON:",
// or trailed by a closing remark. This handles all three and never throws.
final data = PrismStructuredOutput.extractMap(reply);

// Compliant output is easier to get than to parse. Say what you want up front.
final prompt = PrismStructuredOutput.instructJson(
  'Classify this review.',
  schema: {'sentiment': 'positive|negative', 'confidence': 0.0},
);

// Long threads are sent whole until the provider rejects them or truncates the
// middle. This trims the oldest turns, protecting the system message and the
// newest exchange, and reports a usage ratio for a context meter.
final messages = PrismContextBudget(maxTokens: 8000).fit(history);
```

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


### Skeleton — loading that keeps the page shape

```dart
if (loading)
  const PrismSkeletonList.cards(count: 3)
else
  NoteList(notes)

// Or compose primitives
PrismSkeletonCard(mediaHeight: 140, lines: 3)
PrismSkeletonText(lines: 2, lastLineFraction: 0.4)
PrismSkeleton.circle(diameter: 44)
```

The shimmer stops automatically when the platform requests reduced motion, so you never ship a strobe to a user who asked for calm.

### Avatar — never a broken image

```dart
PrismAvatar(name: 'Ayesha Khan')
PrismAvatar(name: 'Ayesha Khan', imageUrl: user.photoUrl, size: 56)
PrismAvatar(name: 'Ayesha Khan', presence: PrismPresence.online)
PrismAvatar(name: 'Acme Inc', shape: PrismAvatarShape.rounded, size: 48)
```

Initials come from `PrismAvatar.initialsFor(name)`; the fallback colour is picked deterministically from the name, so a person looks the same on every device. Failed image loads silently fall back to initials.

### ChipInput — tags without the pain

```dart
PrismChipInput(
  label: 'Tags',
  value: tags,
  suggestions: const ['dart', 'flutter', 'ui'],
  maxChips: 5,
  helperText: 'Paste a comma-separated list to add several at once.',
  onChanged: (next) => setState(() => tags = next),
)
```

Handles comma/newline/semicolon paste, duplicate rejection (case-insensitive), backspace-to-delete, custom validators and an optional suggestion overlay.

### OtpField — paste, autofill, auto-submit

```dart
PrismOtpField(
  length: 6,
  groupSeparatorAfter: 3,     // renders 123 456
  errorText: error,
  onCompleted: (code) => verify(code),
)

PrismOtpField(length: 4, obscure: true)   // PIN entry
```

A single transparent field sits behind the digit boxes, so IME, paste, selection, autofill (`oneTimeCode`) and screen readers all behave natively.

### Timeline — order tracking and activity feeds

```dart
PrismTimeline(
  entries: [
    PrismTimelineEntry(
      title: 'Order placed',
      timestamp: '09:12',
      semantic: PrismSemantic.success,
    ),
    PrismTimelineEntry(
      title: 'Out for delivery',
      subtitle: 'Driver Sam · 2 stops away',
      isActive: true,
      child: TrackLiveCard(),
    ),
    PrismTimelineEntry(
      title: 'Delivery failed',
      semantic: PrismSemantic.error,
    ),
  ],
  onEntryTap: (index, entry) => open(index),
)
```

### Stepper — wizards that stay readable

```dart
PrismStepper(
  steps: const [
    PrismStep(title: 'Account'),
    PrismStep(title: 'Profile'),
    PrismStep(title: 'Preferences', isOptional: true),
  ],
  currentIndex: step,
  erroredIndices: {1},
  onStepTapped: (i) => setState(() => step = i),
)
```

Horizontal with connectors on wide windows; a compact `Step 2 of 3` header with a progress bar on phones.

### DataTable — one widget, two layouts

```dart
PrismDataTable<Invoice>(
  rows: invoices,
  onRowTap: (row, i) => open(row),
  columns: [
    PrismColumn(label: 'Invoice', alwaysVisible: true,
      cell: (c, r, i) => Text(r.id),
      sortComparator: (a, b) => a.id.compareTo(b.id)),
    PrismColumn(label: 'Client', cell: (c, r, i) => Text(r.client)),
    PrismColumn(label: 'Total', numeric: true, cell: (c, r, i) => Text('\$${r.total}')),
  ],
)
```

Desktop gets a sortable table with a header row; phones get the same data as cards with field labels. No horizontal scrolling, no hidden columns.

### CommandPalette — a ⌘K launcher

```dart
final chosen = await PrismCommandPalette.show(
  context: context,
  commands: [
    PrismCommand(label: 'New note', icon: Icons.add, group: 'File',
      shortcut: '⌘N', onSelect: createNote),
    PrismCommand(label: 'Toggle theme', group: 'View',
      keywords: const ['dark', 'appearance'], onSelect: toggleTheme),
  ],
);
```

Fuzzy subsequence search (so `tt` finds *Toggle theme*), grouping, arrow/Enter/Escape navigation, and a full-screen route on phones.

### AdaptiveSheet — bottom sheet or dialog, automatically

```dart
final confirmed = await PrismAdaptiveSheet.show<bool>(
  context: context,
  title: 'Delete this note?',
  subtitle: 'It will move to Trash for 30 days.',
  child: const Text('You can restore it any time.'),
  actions: [
    const PrismSheetAction(label: 'Cancel', value: false),
    PrismSheetAction(label: 'Delete', value: true, isDestructive: true),
  ],
);
```

### ConnectionBanner — offline UX in one line

```dart
PrismConnectionBanner(
  source: () => Connectivity().onConnectivityChanged.map((r) => r != ConnectivityResult.none),
  onlineMessage: 'Back online — syncing…',
  onRetry: refetch,
)
```

Dampens short blips with a settle delay, flashes a reconnected message, and announces changes through a polite live region.

### Design tokens — one visual language

```dart
MaterialApp(
  theme: ThemeData(
    colorSchemeSeed: Colors.teal,
    extensions: const [
      PrismTokens(
        spaceMd: 20,
        radiusMd: 16,
        durationMedium: Duration(milliseconds: 200),
      ),
    ],
  ),
)

// Anywhere in your app:
Padding(padding: EdgeInsets.all(context.prismTokens.spaceMd), child: …)
Container(color: context.prismColors.surfaceRaised)
Container(color: context.prismColors.forRole(PrismSemantic.success).background)
```

**Every one of the 34 components reads these tokens** — toasts, banners, forms,
data tables, the command palette, everything. Change `spaceMd` once and the whole
app changes rhythm together; switch `brightness` and every semantic colour
follows.

`PrismColors` gives you the four roles a `ColorScheme` does not spell out —
`success`, `warning`, `error` and `info` — each with a solid accent and a
container/on-container pair, resolved per brightness so they stay legible in
both modes. The fallback green and amber are deliberately distinct from
`primary` and `tertiary`, so "success" still reads as success when your brand
colour happens to be green.

If you register no tokens at all, components fall back to `PrismTokens.fallback`
and behave exactly as before. Nothing throws, nothing breaks.

Motion follows the platform's reduce-motion setting automatically — every
animated component reads its duration through `context.prismMotion(...)`, so you
do not have to remember to gate each one.

### SyncStatus — a live sync indicator

```dart
ValueListenableBuilder(
  valueListenable: syncEngine.state,
  builder: (context, state, _) => PrismSyncStatus(snapshot: snapshotOf(state)),
)
```

Six phases (idle, pushing, pulling, offline, failed, paused), each with its own
icon, label and semantic colour. It is a live region, so a failed sync is
announced rather than silently ignored, and it offers a retry action only when
there is something to retry.

Prism has no sync dependency. `PrismSyncSnapshot` is a plain value type, and the
adapter from [`flutter_local_first`](https://pub.dev/packages/flutter_local_first)'s
sealed `SyncState` is a compiler-checked switch — see the example on
`PrismSyncPhase`.

### Calendar — dates without a dependency

```dart
PrismCalendar(
  month: focusedMonth,
  selected: selectedDays,
  selection: PrismDateSelection.range,
  firstDate: DateTime(2026),
  lastDate: DateTime(2027),
  markers: daysWithEvents,
  onDaySelected: (day) => setState(() => selectedDays = {day}),
  onMonthChanged: (month) => setState(() => focusedMonth = month),
)
```

A grid of real buttons, so it works by keyboard and screen reader: each day
announces its full date, selection state and — in range mode — whether it is a
start, end or middle. No `intl` dependency; pass `monthNames` and
`weekdayLabels` to localise.

### Tabs, SegmentedControl — adapt instead of overflow

```dart
PrismTabs(
  tabs: const [
    PrismTab(label: 'Today', icon: Icons.today_outlined),
    PrismTab(label: 'Upcoming', icon: Icons.schedule_outlined),
  ],
  index: index,
  onChanged: (next) => setState(() => index = next),
  children: const [TodayView(), UpcomingView()],
)

PrismSegmentedControl<Density>(
  value: density,
  onChanged: (next) => setState(() => density = next),
  segments: const [
    PrismSegment(value: Density.compact, label: 'Compact'),
    PrismSegment(value: Density.comfortable, label: 'Comfortable'),
  ],
)
```

Below `PrismTokens.breakpointCompact` both scroll rather than clipping their
labels — five tabs do not fit on a phone, and silently hiding options is worse
than letting them scroll.

### Accordion, Rating, Badge

```dart
PrismAccordion(
  singleExpansion: true,
  sections: const [
    PrismAccordionSection(title: 'Delivery', child: Text('…')),
    PrismAccordionSection(title: 'Returns', child: Text('…')),
  ],
)

PrismRating(value: rating, allowHalf: true, onChanged: (v) => setRating(v))
PrismBadge(count: unread, child: Icon(Icons.notifications_outlined))
```

The rating picks the half value when you tap the left half of a star, and is a
slider with increase/decrease actions to a screen reader. The accordion announces
whether each section is expanded rather than presenting anonymous buttons.

---

## 🎨 Getting a look in one call

```dart
MaterialApp(
  theme: prismTheme(seed: brandPurple),
  darkTheme: prismTheme(seed: brandPurple, brightness: Brightness.dark),
)
```

`prismTheme` seeds the scheme, registers the tokens and extends any base theme
you already configured. To shape the feel, compose three orthogonal choices:

```dart
prismTheme(
  density: PrismDensity.compact,   // spacing and control height
  shape: PrismShape.sharp,         // corner radii
  motion: PrismMotion.brisk,       // durations
)
```

Or take a ready-made personality: `PrismTokenPresets.technical`,
`.friendly`, `.editorial`.

Spacing is deliberately **not** derived from your brand colour. A colour says
nothing about how much padding a table row wants, and pretending otherwise
produces the incoherent look this library exists to avoid.

## 🔍 Inspecting the design system

```dart
MaterialApp(
  builder: (context, child) => PrismDebugOverlay(
    enabled: kDebugMode,
    child: child!,
  ),
  home: const HomePage(),
)
```

A live panel showing the active tokens, the current window class, brightness and
whether reduced motion is on. It answers the question every theming bug starts
with — "are the tokens I set the tokens being read?" — without a rebuild-and-print
cycle. Disabled by default, so `enabled: kDebugMode` makes it release-safe.

---

## 🧪 Testing your own screens

`package:prism_kit/testing.dart` ships the same helpers Prism's own 672 tests
use, so your tests run in the same environment:

```dart
import 'package:prism_kit/testing.dart';

testWidgets('the dashboard shows an empty state', (tester) async {
  await pumpPrism(tester, const Dashboard(), size: const Size(320, 568));
  expect(find.text('Nothing here yet'), findsOneWidget);
});

testWidgets('the card survives every window size', (tester) async {
  await expectNoOverflow(tester, () => const MyCard());
});
```

`pumpPrism` installs the design system, a **real** viewport, brightness, text
direction and reduced-motion setting in one call. That last detail is the point:
a bare `MediaQueryData()` reports a zero-size viewport, so an adaptive component
silently falls into its compact layout and the test passes while asserting
nothing. `expectNoOverflow` pumps at phone, tablet and desktop widths and fails
on any exception — it is what caught the `PrismChipInput` overflow.

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
| Skeleton / Avatar / ChipInput / OtpField | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Timeline / Stepper / DataTable | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| CommandPalette / AdaptiveSheet / ConnectionBanner | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| PrismTokens / PrismColors | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

## 🧪 Quality

- **766 tests** (unit + widget) across all components
- **Every component is covered by design-system tests** that install
  deliberately unusual `PrismTokens` and assert the component actually reads
  them — a hard-coded radius, duration or colour fails CI
- **A 184-case component matrix** pumps every component at 320 px and 1600 px, in
  light and dark, in LTR and RTL, failing on any exception or overflow
- **The semantic palette is verified against WCAG AA** across ten brand seeds in
  both brightnesses, and the four roles are asserted to stay distinguishable
- **Accessibility is tested, not assumed**: live regions for state the user did
  not trigger, decorative content hidden from screen readers, minimum touch
  targets, and reduced motion honoured by every animated component
- Zero analyzer issues under `strict-casts`, `strict-inference` and
  `strict-raw-types`, plus a curated lint set
- Light and dark verified separately, and components verified to degrade
  gracefully when no tokens are registered at all
- CI runs formatting, strict analysis and the full suite on every push

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

The [`example/`](example/) folder is a **gallery app** with an interactive demo
for every component:

```bash
cd example && flutter run
```

- **Searchable grid** of all 26 demos, indexed with keywords — `pin` finds the
  OTP field, `offline` finds the connection banner.
- **Theme toggle** (system → light → dark) so you can check both palettes.
- **Live token override** in the app bar: flip it and every component adopts a
  distinctly non-default spacing and radius set at once. That is the design
  system doing its job, not a mock-up.
- The gallery builds itself out of Prism widgets, so it is also a usage example.

It also builds for the web if you want to try it without a device:

```bash
cd example && flutter build web
```

## 🤝 Contributing

Issues and PRs welcome. Start with [CONTRIBUTING.md](CONTRIBUTING.md) — the two
rules that matter are **read the design system, never hard-code** and **adapt to
the window**. Release and deprecation policy is in
[docs/VERSIONING.md](docs/VERSIONING.md).

The quickest meaningful contribution is a component that misbehaves on a
1200 px-wide window or in dark mode; the design-system tests will tell you if a
fix is complete.

## ☕ Support

If Prism helps you ship faster, please consider supporting my work:

<p align="center">
  <a href="https://buymeacoffee.com/awaisdev572">
    <img src="https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=%E2%98%95&slug=awaisdev572&button_colour=FFDD00&font_colour=000000&font_family=Lato&outline_colour=000000&coffee_colour=ffffff" alt="Buy Me A Coffee">
  </a>
</p>

## 📄 License

MIT — see [LICENSE](LICENSE).
