# mingcute_icons

A [MingCute](https://www.mingcute.com) icon library package for Flutter applications.
Provides 3,300+ carefully designed icons in `fill` and `line` styles as a single icon font, generated from the [mingcute_icon](https://www.npmjs.com/package/mingcute_icon) npm package.

The package version tracks the upstream `mingcute_icon` release it was generated from.

## Usage

```dart
import 'package:mingcute_icons/mingcute_icons.dart';

Icon(MingCuteIcons.home1Fill);
Icon(MingCuteIcons.searchLine, size: 32, color: Colors.teal);
```

Icon names are the upstream CSS class names (`mgc_home_1_fill`) converted to lowerCamelCase (`home1Fill`).
Every icon ships in two styles, suffixed `Fill` and `Line`.

## Updating icons

```bash
bash tool/update_icons.sh          # latest mingcute_icon release
bash tool/update_icons.sh 2.9.72   # pin a specific version
```

A daily GitHub Actions workflow (`.github/workflows/update-icons.yml`) regenerates the icon set and opens a PR when a new upstream release is published.

## License

Package code and the bundled MingCute font/SVG assets are licensed under Apache-2.0 (see LICENSE, © MingCute Design).
