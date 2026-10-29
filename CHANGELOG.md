# Changelog

## 3.0.2+1 - 2026-10-30

### Fixed

- Excluded internal plans and specs from the published package.
- Removed the Flutter SDK upper bound to allow automated publication.

## 3.0.2 - 2026-10-29

### Changed

- Migrated from the deprecated mingcute_icon package to @mingcute/font@3.0.2 and @mingcute/svg@3.0.2.
- Converted both upstream WOFF2 styles to bundled TTF fonts while preserving existing Dart icon names.
- Updated the generator, SVG previews, and automated release checks for the scoped packages.

### Added

- Added `backgroundBaseFill`, `backgroundBaseLine`, `loading3Fill`, and `loading3Line`.

## 2.9.72 - 2026-07-15

### Added

- Initial release, generated from mingcute_icon@2.9.72 (3,322 icons in fill and line styles).
