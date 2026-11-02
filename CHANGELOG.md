# Changelog

## 1.3.0

### Added
- **`PrismSyncStatus`** — a compact sync indicator with six phases (idle,
  pushing, pulling, offline, failed, paused), progress, a retry action that only
  appears on failure, and a live region so a failed sync is announced. Prism
  takes no sync dependency: `PrismSyncSnapshot` is a plain value type and the
  adapter from `flutter_local_first` is a compiler-checked switch.
- **`package:prism_kit/testing.dart`** — `pumpPrism`, `expectNoOverflow` and
  `pumpPrismWithSemantics`, the same helpers Prism's own suite uses. `pumpPrism`
  installs a real viewport (a bare `MediaQueryData()` reports size zero, which
  silently makes adaptive components take their compact path), the design system,
  brightness, text direction and reduced-motion setting.
- **`context.prismMotion(...)` and `context.prismReduceMotion`** for honouring
  the platform's reduce-motion setting.
- **`docs/VERSIONING.md`** — semantic versioning and deprecation policy, noting
  that visual defaults and accessibility semantics are both API.
- **CI, publish and docs workflows.** Publish runs on a `v*` tag, verifies the
  tag matches `pubspec.yaml`, and skips cleanly when no credentials are present.
  Docs builds the API reference plus the web gallery and deploys both to Pages.
- **`theme_contrast_test.dart`** — the semantic palette is verified against WCAG
  AA (4.5:1 text, 3:1 accents) across ten brand seeds in both brightnesses.
- **`component_matrix_test.dart`** — 184 cases pumping every component at 320 px
  and 1600 px, in light and dark, in LTR and RTL.
- **`accessibility_test.dart`** — 15 tests covering live regions, hidden
  decorative content, touch targets, sortable-header semantics, reduce motion and
  RTL rendering.

### Changed
- **Every animated component now honours reduce motion**, routing its duration
  through `context.prismMotion(...)`. Previously one of 28 areas respected it.
- `PrismSkeleton` is wrapped in `ExcludeSemantics`: announcing placeholders is
  noise for a screen reader user.
- `PrismToast` and `PrismStateView` are live regions, so state the user did not
  trigger is actually announced.
- `PrismDataTable` sortable headers announce sortability, the current direction
  and the next action.
- `PrismPaginatedList` announces loading and end-of-list.
- The chip remove affordance meets the 32 dp minimum touch target; it was
  roughly 19 px.

### Fixed
- **`PrismChipInput` overflowed by 48 px** when a tag was wider than the field,
  because the chip label was a bare `Text` that could not shrink. It is now
  `Flexible` with ellipsis, and the untruncated value still reaches assistive
  tech. Found by the new component matrix.

## 1.2.0

A consistency release: the design system introduced in 1.1.0 now actually
governs the whole library.

### Changed
- **Every component reads `PrismTokens` and `PrismColors`.** Previously the
  original 17 components ignored the design system, so overriding tokens had no
  effect on toasts, banners, forms, search, settings, pagination, changelogs,
  code views, scaffolds, master-detail, dialogs or state views. A single
  `ThemeData.extensions` override now restyles the entire app.
- Style classes (`PrismStateViewStyle`, `PrismBannerStyle`, `ChangelogStyle`,
  `PrismCodeViewStyle`, `PrismSearch`) gained a `resolve(BuildContext)` method
  that fills unset fields from tokens, and their visual fields became nullable so
  "unset" is distinguishable from "deliberately zero".
- `PrismStateViewStyle` gained `iconSize`, `padding`, `gap` and `retryLabel`.
- `PrismBannerStyle`, `ChangelogStyle` and `PrismCodeViewStyle` field defaults
  are now token-derived rather than literal.
- `PrismAdaptiveScaffold` and `PrismMasterDetail` transition durations default to
  `PrismTokens.durationMedium`; `PrismAdaptiveScaffold` accepts token-driven
  breakpoints.
- `PrismSearch.debounce` defaults to `PrismTokens.durationMedium`.
- `PrismBreakpoint.resolve` accepts custom thresholds; the previous behaviour is
  available as `resolveStandard`.

### Added
- **15 design-system tests** that install deliberately unusual tokens and assert
  components read them, including light/dark colour divergence, semantic-role
  distinctness, token-driven breakpoints, and graceful behaviour when no tokens
  are registered at all. A hard-coded radius, duration or colour now fails CI.
- `CONTRIBUTING.md` documenting the two rules that matter and how to add a
  component.
- GitHub Actions workflow running formatting, strict analysis, the full test
  suite and an example build.
- Issue templates (bug, feature) and a pull request checklist.

### Improved
- The example gallery is now searched-indexed with keywords, has a theme-mode
  toggle, and has a live token override so you can watch every component adopt a
  non-default token set at once. It also builds for the web.

### Fixed
- `PrismColours.resolve` now derives `error` and `onError` from the theme rather
  than leaving them transparent.
- Attachment progress no longer emits 100% twice.

## 1.1.0

### Added
- **Design system**: `PrismTokens` (spacing scale, corner radii, motion
  durations, breakpoints, control height) installable via
  `ThemeData.extensions`, and `PrismColors` (semantic success/warning/error/
  info roles plus raised and sunken surfaces) derived from any `ColorScheme`.
- **PrismSkeleton** — shimmering placeholders (text, card, tile list, circle)
  that honour the platform's reduced-motion setting.
- **PrismAvatar** — image avatars with deterministic initials fallback,
  presence dots, badges, borders and accessibility labels.
- **PrismChipInput** — tag entry with delimiter/paste splitting, duplicate
  rejection, max limits, validators and a suggestion overlay.
- **PrismOtpField** — OTP/PIN entry with paste, auto-submit, digit grouping,
  obscuring and native `oneTimeCode` autofill.
- **PrismTimeline** — vertical event timeline with connectors, semantic roles,
  rich per-entry content and optional mirrored layout.
- **PrismStepper** — wizard progress that is horizontal on wide windows and a
  compact "Step X of Y" header with a progress bar on phones.
- **PrismDataTable** — sortable table on desktop that becomes labelled cards
  on narrow windows.
- **PrismCommandPalette** — ⌘K launcher with fuzzy search, grouping and full
  keyboard navigation.
- **PrismAdaptiveSheet** — bottom sheet on phones, centred dialog on desktop,
  from one call, with typed action results.
- **PrismConnectionBanner** — offline/online banner with settle delay,
  reconnected flash, retry action and live-region announcements.

### Changed
- README rewritten with copy-pasteable usage documentation for all 27
  components, a platform support matrix and a design-system section.
- Example gallery expanded to 26 interactive demos.
- Test suite grown from 252 to 385 tests.

## 1.0.0

- Initial consolidated release: merges prism_adaptive_dialog, prism_adaptive_scaffold, prism_ai, prism_banner, prism_changelog, prism_code_view, prism_form, prism_image, prism_markdown, prism_master_detail, prism_pagination, prism_palette, prism_search, prism_settings, prism_state_views, prism_toast and prism_updater into a single package.
