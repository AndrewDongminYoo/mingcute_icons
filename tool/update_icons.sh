#!/usr/bin/env bash
#
# Upgrade the @mingcute dependencies and regenerate the Flutter icon set.
#
# Shared by the `merry update-icons` developer script and the
# `.github/workflows/update-icons.yml` automation so the regeneration steps
# live in exactly one place.
#
# Usage:
#   tool/update_icons.sh            # upgrade to the latest @mingcute/font release
#   tool/update_icons.sh 3.0.2      # pin matching font and SVG versions
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

version_spec="${1:-latest}"

# 1. Resolve one upstream version for both packages.
version="$(pnpm view "@mingcute/font@${version_spec}" version)"
pnpm add --save-exact "@mingcute/font@${version}" "@mingcute/svg@${version}"

# 2. Upstream ships WOFF2 only. Flutter's native engines need SFNT fonts.
cat node_modules/@mingcute/font/dist/css/core-filled.min.css \
	node_modules/@mingcute/font/dist/css/core-regular.min.css >assets/mingcute.css
pnpm exec woff2_decompress.js node_modules/@mingcute/font/dist/fonts/core-filled.woff2 assets/mingcute.ttf
pnpm exec woff2_decompress.js node_modules/@mingcute/font/dist/fonts/core-regular.woff2 assets/mingcute_line.ttf

# 3. Regenerate lib/flutter_mingcute.dart with inline SVG dartdoc previews.
#    Each style has its own SVG directory and font family.
dart run tool/generate_fonts.dart assets/mingcute.css \
	--inline-svg \
	--npm-package=@mingcute/svg \
	--font-family=MingCute \
	--font-package=flutter_mingcute \
	--class-name=MingCuteIcons \
	--css-prefix=mgc- \
	--docs-url='https://github.com/mingcute-design/mingcute-icons/search?q=' \
	--output=./lib/flutter_mingcute.dart \
	--svg-dir=node_modules/@mingcute/svg

# 4. Format so the committed file honours analysis_options.yaml page_width (80).
#    The generator emits unwrapped lines; without this the diff is noisy and
#    long-line lints trip. Keeps merry and CI regeneration byte-identical.
dart format lib/flutter_mingcute.dart

# The vendored CSS is left exactly as upstream ships it. trunk formats it — via
# trunk-fmt-pre-commit locally, and via the format step in
# .github/workflows/update-icons.yml in CI — so the prettier version lives in
# .trunk/trunk.yaml alone and cannot drift from a second pin here.
