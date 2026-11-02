# Changelog

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
