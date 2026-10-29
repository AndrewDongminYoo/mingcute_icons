# flutter_mingcute

A [MingCute](https://www.mingcute.com) icon library package for Flutter applications.
Provides 3,300+ carefully designed icons in `fill` and `line` styles, generated from the [@mingcute/font](https://www.npmjs.com/package/@mingcute/font) and [@mingcute/svg](https://www.npmjs.com/package/@mingcute/svg) npm packages.

The package version tracks the matching upstream `@mingcute/font` and `@mingcute/svg` release it was generated from.

## Usage

```dart
import 'package:flutter_mingcute/flutter_mingcute.dart';

Icon(MingCuteIcons.home1Fill);
Icon(MingCuteIcons.searchLine, size: 32, color: Colors.teal);
```

Upstream `core-filled` and `core-regular` styles map to the existing `Fill` and `Line` Dart suffixes (`mgc-home-1-core-filled` → `home1Fill`).
Existing Dart icon names are preserved, including names whose spelling changed upstream.
Each style uses its own bundled TTF font because the upstream fonts share codepoints.

## Updating icons

```bash
pnpm install --frozen-lockfile
bash tool/update_icons.sh         # latest @mingcute/font release
bash tool/update_icons.sh 3.0.2   # pin matching font and SVG versions
```

The updater converts the upstream WOFF2 fonts to TTF with the build-only `wawoff2` dependency so the fonts work in native Flutter applications.
SVG previews are embedded from `@mingcute/svg`.

A four-hourly GitHub Actions workflow (`.github/workflows/update-icons.yml`) regenerates the icon set and opens a PR when a new upstream release is published.

## License

Package code and the bundled MingCute font/SVG assets are licensed under Apache-2.0 (see LICENSE, © MingCute Design).
