# Contributing to Prism

Thanks for helping. Prism aims to be the component library you reach for when you
want one dependency, a consistent look, and no surprises. That means the bar for
a change is not only "does it work" but "does it fit".

## Getting set up

```bash
git clone https://github.com/awaisdev5765/Prism.git
cd Prism
flutter pub get
cd example && flutter pub get && cd ..
```

Run the checks the CI runs:

```bash
dart format lib test          # formatting
flutter analyze               # analysis (strict)
flutter test                  # 400 tests
```

To try a change by hand, run the gallery — it has an interactive demo for every
component:

```bash
cd example && flutter run
```

## The two rules that matter most

### 1. Read the design system, never hard-code

Every visual constant must come from `PrismTokens` and `PrismColors`:

```dart
// Yes
final tokens = context.prismTokens;
Padding(padding: EdgeInsets.all(tokens.spaceMd), child: child);
Container(color: context.prismColors.surfaceRaised);

// No
Padding(padding: const EdgeInsets.all(16), child: child);
Container(color: const Color(0xFFF5F5F5));
```

This is what lets a single `ThemeData.extensions` override restyle a whole app.
If you add a field to a style class, make it nullable and resolve it in the
existing `resolve(BuildContext)` method rather than defaulting it in the
constructor.

`test/theme_design_system_test.dart` installs deliberately unusual tokens and
asserts components pick them up — a hard-coded value fails there.

### 3. Snapshot the styles you resolved

`test/style_snapshot_test.dart` records what each component resolved — radii,
paddings, colours, durations — into `test/snapshots/*.json`, and fails when any of
it changes.

Add a snapshot when you add a component:

```dart
testWidgets('my component', (tester) async {
  await snapshot(tester, 'my_component', const MyComponent());
});
```

To update after an intended change:

```bash
PRISM_UPDATE_SNAPSHOTS=1 flutter test test/style_snapshot_test.dart
```

**Read the diff before committing it.** A snapshot updated without being read is a
snapshot that has stopped testing anything.

These are deliberately not image goldens. Pixel comparison is platform-sensitive,
so a golden generated on macOS fails on CI's Linux runner, and the usual fixes —
tagging them, or tolerating a pixel difference — weaken the check until it stops
catching the thing you wanted. Structural snapshots are platform-independent and
diff as JSON, which means a reviewer can actually see what moved.

### 2. Adapt to the window

Components should look right from a 320 px phone to a 1600 px desktop. Where a
layout cannot work at one extreme, switch to a different layout rather than
letting it overflow — see `PrismDataTable` (table → cards) and `PrismStepper`
(horizontal → "Step X of Y") for the pattern. Use
`tokens.breakpointCompact` / `tokens.breakpointExpanded` rather than literal
widths.

## Adding a component

1. Create `lib/src/<name>/<name>.dart` with the widget and any supporting types.
2. Export it from `lib/prism.dart`.
3. Document every public member — pub.dev scores documentation coverage, and
   more importantly, users read it.
4. Add a demo to `example/lib/main.dart`.
5. Add tests under `test/<name>_prism_<name>_test.dart` covering: default
   rendering, each documented option, empty/loading/error states, and both a
   compact and a wide window.
6. Note the addition in `CHANGELOG.md`.

## Style

- `dart format` decides formatting; do not argue with it.
- Single quotes, trailing commas, and named parameters for anything that is not
  obvious at the call site.
- Prefer a sealed class or an enum over a boolean flag when a parameter has more
  than two meaningful states.
- Write doc comments that explain *why*, and include a copy-pasteable example for
  anything non-trivial.
- Keep the dependency list short. A component that needs a new package needs a
  good reason.

## Reporting bugs

Use the issue templates. A minimal reproduction is worth more than a long
description — if you can paste it into `example/` and see the problem, we can fix
it quickly.

## Licence

By contributing you agree that your contribution is licensed under the MIT
Licence, the same terms as the project.
