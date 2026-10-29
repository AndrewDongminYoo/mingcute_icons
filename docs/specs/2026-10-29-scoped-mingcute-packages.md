# Scoped MingCute packages

## Problem

The npm package `mingcute_icon` is deprecated in favor of `@mingcute/font` and `@mingcute/svg`.
The replacement font package publishes separate Core Filled and Core Regular WOFF2 fonts, new CSS selectors, and shared codepoints across styles.
The existing updater expects one TTF and category-based SVG directories, so changing only the dependency name cannot regenerate the Flutter package.

## Scope

- Use matching `@mingcute/font` and `@mingcute/svg` versions, initially 3.0.2.
- Convert the upstream fonts to TTF with the build-only `wawoff2` dependency.
- Register both font families and generate existing `Fill` and `Line` Dart names.
- Preserve existing names where upstream spelling changed.
- Embed local SVG previews from the new style directories.
- Update release discovery, dependency locking, README, and changelog.

## Acceptance criteria

1. All 3,322 existing public icon constant names remain available.
2. Generation produces the upstream 3,326 styled icons with embedded SVG previews.
3. Filled and regular constants use their respective TTF fonts, including when their codepoints are equal.
4. CSS without icon mappings fails without replacing the existing Dart output.
5. Repeating the current-version update and repository CSS formatting produces byte-identical generated files.
6. Automated discovery advances one release at a time, never passes npm `latest`, refuses a missing cursor, and waits for an open update PR using either branch prefix.
7. `flutter test`, `flutter analyze`, scoped Dart formatting, frozen pnpm installation, and the affected Trunk checks pass.

## Constraints

Preserve existing unrelated workspace edits unless the operator includes them in this PR.
Do not introduce a Flutter runtime dependency for font conversion.
The package version follows the coordinated upstream version.
Changes to font family names and codepoints require using the generated constants rather than manually retained values from 2.x.

## Non-goals

This migration does not add a framework-specific npm renderer, MingCute Pro styles, or a new Flutter rendering API.
Opening the PR does not authorize merging or publishing it.
