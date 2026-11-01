# Changelog

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
