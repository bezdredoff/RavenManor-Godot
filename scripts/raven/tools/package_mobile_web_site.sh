#!/usr/bin/env bash
# Export a self-contained Raven Manor Pages tree, rooted in the checked-out code.
# Run only with a read-only token / no production secrets on candidate source.
set -euo pipefail
if [[ $# -ne 1 ]]; then
  echo "usage: package_mobile_web_site.sh OUT_DIR" >&2
  exit 2
fi
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
OUT="$(mkdir -p "$1" && cd "$1" && pwd)"
test "$ROOT" != "$OUT"
mkdir -p "$OUT/builder" "$OUT/dashboard"
godot --headless --path "$ROOT" --editor --quit
godot --headless --path "$ROOT" --export-release "GitHub Pages Web" "$OUT/index.html"
for file in index.html index.js index.wasm index.pck; do
  test -s "$OUT/$file" || { echo "Missing Web export $file" >&2; exit 1; }
done
cp -a "$ROOT/builder/." "$OUT/builder/"
cp "$ROOT/dashboard/index.html" "$ROOT/dashboard/style.css" "$ROOT/dashboard/app.mjs" "$OUT/dashboard/"
python3 "$ROOT/scripts/raven/tools/build_production_dashboard.py" \
  --output "$OUT/dashboard/status.json"
test -s "$OUT/builder/index.html"
test -s "$OUT/dashboard/status.json"
echo "Raven mobile preview export passed: $OUT"
