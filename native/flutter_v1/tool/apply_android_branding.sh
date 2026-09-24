#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${FAMEVERSE_APP_NAME:-Fameverse}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PROJECT_ROOT/../.." && pwd)"
ANDROID_ROOT="$PROJECT_ROOT/android"
MANIFEST="$ANDROID_ROOT/app/src/main/AndroidManifest.xml"
SOURCE_SVG="$REPO_ROOT/public/icon.svg"

for required in "$MANIFEST" "$SOURCE_SVG"; do
  if [ ! -f "$required" ]; then
    echo "Missing required Fameverse Android branding input: $required"
    exit 1
  fi
done

python3 - "$MANIFEST" "$APP_NAME" <<'PY'
from pathlib import Path
import re
import sys

manifest = Path(sys.argv[1])
app_name = sys.argv[2]
text = manifest.read_text()
updated, count = re.subn(r'android:label="[^"]*"', f'android:label="{app_name}"', text, count=1)
if count != 1:
    raise SystemExit('Could not locate Android application label')
manifest.write_text(updated)
PY

TMP_DIR="$(mktemp -d /tmp/fameverse-android-branding.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Android applies launcher masks itself on supported launchers. Use an opaque
# square source so no Flutter placeholder or double transparent corner leaks.
NATIVE_SVG="$TMP_DIR/fameverse-native-icon.svg"
sed 's/<rect width="512" height="512" rx="112"/<rect width="512" height="512"/' \
  "$SOURCE_SVG" > "$NATIVE_SVG"

render_icon() {
  local pixels="$1"
  local output="$2"
  mkdir -p "$(dirname "$output")"

  if command -v sips >/dev/null 2>&1; then
    local raw="$TMP_DIR/raw-${pixels}.png"
    if ! sips -s format png "$NATIVE_SVG" --out "$raw" >/dev/null 2>&1; then
      qlmanage -t -s 1024 -o "$TMP_DIR" "$NATIVE_SVG" >/dev/null 2>&1
      local ql="$TMP_DIR/$(basename "$NATIVE_SVG").png"
      test -f "$ql"
      mv "$ql" "$raw"
    fi
    sips -z "$pixels" "$pixels" "$raw" --out "$output" >/dev/null
  elif command -v rsvg-convert >/dev/null 2>&1; then
    rsvg-convert -w "$pixels" -h "$pixels" "$NATIVE_SVG" > "$output"
  else
    echo "No supported SVG rasterizer found (need sips or rsvg-convert)."
    exit 1
  fi
}

render_icon 48  "$ANDROID_ROOT/app/src/main/res/mipmap-mdpi/ic_launcher.png"
render_icon 72  "$ANDROID_ROOT/app/src/main/res/mipmap-hdpi/ic_launcher.png"
render_icon 96  "$ANDROID_ROOT/app/src/main/res/mipmap-xhdpi/ic_launcher.png"
render_icon 144 "$ANDROID_ROOT/app/src/main/res/mipmap-xxhdpi/ic_launcher.png"
render_icon 192 "$ANDROID_ROOT/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"

echo "Applied Fameverse Android branding: name='$APP_NAME', icon='$SOURCE_SVG'"
