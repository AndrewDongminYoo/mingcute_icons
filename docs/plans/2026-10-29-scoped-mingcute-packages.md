# Scoped MingCute package migration

## Approved direction

Adapt the Flutter icon package to the upstream scoped npm packages while retaining the existing Dart icon names.
The implementation and its regression checks were completed in the current session before the operator requested the PR.
This plan records that accepted direction and the remaining delivery checks.

## Implementation and checks

1. Inspect npm metadata and packaged assets for `mingcute_icon`, `@mingcute/font`, and `@mingcute/svg`.
   Verify the deprecation notice, matching version, CSS selectors, font formats, and SVG paths.
2. Add a generator regression using scoped CSS, separate families, renamed icons, and local SVG fixtures.
   Observe failure with the original parser before applying the fix.
3. Update `package.json`, `.gitignore`, `tool/update_icons.sh`, `tool/generate_fonts.dart`, and the font declarations in `pubspec.yaml`.
   Regenerate `pnpm-lock.yaml`, both TTF assets, CSS, and `lib/flutter_mingcute.dart` with the real updater.
4. Update `test/generator_test.dart`, `test/font_consistency_test.dart`, and `test/icon_test.dart`.
   Check per-style codepoint coverage and render distinct, nonempty glyphs from the converted fonts.
   Confirm that reverting the parser and substituting the filled font for the regular font each fail the relevant regression.
5. Update `.github/workflows/update-icons.yml`, `README.md`, and `CHANGELOG.md` in the same change.
   Exercise the workflow's Bash against actual `npm view --json` metadata and controlled open-PR fixtures.
   Include the negative control that removes `dist-tags` from the fixture.
6. Run the updater again and format the generated CSS.
   Compare hashes of the CSS, two TTF files, Dart output, package manifest, and pnpm lockfile.
7. Complete independent read-only reviews of generation and automation.
   Verify and repair any confirmed contract defects before scoped staging.
8. Resolve whether the pre-existing toolchain version changes belong in the PR.
   Create concern-based commits, push the task branch, and open the PR against `main`.
9. Observe current-head CI and hosted review within the recorded budget.
   Finish and read back the live PR title and body before assigning `AndrewDongminYoo` at the review handoff.
   Keep the PR open for operator review.

## Verification

```bash
pnpm install --frozen-lockfile
bash tool/update_icons.sh 3.0.2
flutter test
flutter analyze
dart format --output=none --set-exit-if-changed lib/flutter_mingcute.dart tool/generate_fonts.dart test/generator_test.dart test/font_consistency_test.dart test/icon_test.dart
```

Use explicit changed-file paths for Trunk formatting and checks.
Shut down the repository's Trunk daemon after the one-off verification.
