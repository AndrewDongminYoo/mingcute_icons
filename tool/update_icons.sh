#!/usr/bin/env bash
#
# Upgrade the mingcute_icon dependency and regenerate the Flutter icon set.
#
# Shared by the `merry update-icons` developer script and the
# `.github/workflows/update-icons.yml` automation so the regeneration steps
# live in exactly one place.
#
# Usage:
#   tool/update_icons.sh            # upgrade to the latest mingcute_icon release
#   tool/update_icons.sh 2.9.72     # pin a specific mingcute_icon version
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT}"

version_spec="${1:-latest}"

# 1. Upgrade the mingcute_icon npm dependency.
pnpm add "mingcute_icon@${version_spec}"

# 2. Copy the generated font assets out of node_modules.
cp node_modules/mingcute_icon/font/Mingcute.css assets/mingcute.css
cp node_modules/mingcute_icon/font/MingCute.ttf assets/mingcute.ttf

# 3. Regenerate lib/flutter_mingcute.dart with inline SVG dartdoc previews.
#    MingCute ships per-icon SVGs grouped by category directory, so every
#    category is passed as a repeatable --svg-dir flag.
svg_dirs=()
for dir in node_modules/mingcute_icon/svg/*/; do
	svg_dirs+=("--svg-dir=${dir%/}")
done
dart run tool/generate_fonts.dart assets/mingcute.css \
	--inline-svg \
	--npm-package=mingcute_icon \
	--font-family=MingCute \
	--font-package=flutter_mingcute \
	--class-name=MingCuteIcons \
	--css-prefix=mgc_ \
	--docs-url='https://github.com/Richard9394/MingCute/search?q=' \
	--output=./lib/flutter_mingcute.dart \
	"${svg_dirs[@]}"

# 4. Format so the committed file honours analysis_options.yaml page_width (80).
#    The generator emits unwrapped lines; without this the diff is noisy and
#    long-line lints trip. Keeps merry and CI regeneration byte-identical.
dart format lib/flutter_mingcute.dart
