# Versioning and deprecation policy

Prism follows [semantic versioning](https://semver.org): `MAJOR.MINOR.PATCH`.

## What each number means

| Change | Bump |
|---|---|
| A component renders differently, a default changes, a public member is removed or renamed | **MAJOR** |
| A new component, a new optional parameter, a new exported type | **MINOR** |
| A bug fix that restores documented behaviour | **PATCH** |

Two areas deserve a note because they are easy to get wrong:

- **Visual defaults are API.** Changing `PrismTokens.fallback`, a component's
  default radius, or the semantic palette changes what every consumer's app looks
  like. Those are MAJOR. Adding a *new* optional style field is MINOR, because
  unset fields resolve to the previous value.
- **Semantics are API.** Removing a label or a live region is a regression for a
  screen reader user, so it is treated as MAJOR even though no signature changed.

## Deprecation

Nothing public is removed in the release that deprecates it. The sequence is:

1. **Deprecate.** Add `@Deprecated('Use X instead. Removed in 2.0.0.')`, keep the
   old member working, and note it in `CHANGELOG.md`.
2. **Wait.** The deprecated member survives at least one MINOR release, and never
   less than 90 days.
3. **Remove.** Only in a MAJOR release.

```dart
@Deprecated('Use PrismTokens.radiusMd. Removed in 2.0.0.')
const double kPrismRadius = 12;
```

Deprecations are visible in `dart analyze` output, so consumers find out from
their own tooling rather than from a changelog they did not read.

## How to release

1. Update `version:` in `pubspec.yaml`.
2. Add a `CHANGELOG.md` entry describing user-visible changes, in the categories
   the file already uses (`Added`, `Changed`, `Fixed`, `Improved`).
3. Merge to `main` with CI green.
4. Tag and push:

   ```bash
   git tag v1.3.0
   git push origin v1.3.0
   ```

   The `publish` workflow runs `flutter pub publish --dry-run`, then publishes.
   It requires a `PUB_CREDENTIALS` repository secret containing the contents of
   `~/.config/dart/pub-credentials.json`; without it the job skips rather than
   failing.

5. Confirm the release on pub.dev and check the documentation score.

## Compatibility

- **Dart SDK**: `^3.5.0` and above, as declared in `pubspec.yaml`.
- **Flutter**: the current stable channel. Prism tracks stable, not beta.
- **Platforms**: every component supports Android, iOS, macOS, Windows, Linux
  and web. A component that cannot work on one of those says so in its docs.

## Pre-1.0

Versions below 1.0.0 make no compatibility promise, but Prism is at 1.x and will
stay there: breaking changes wait for a major release like any other project.
