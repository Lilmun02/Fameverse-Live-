#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${FAMEVERSE_APP_NAME:-Fameverse}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PROJECT_ROOT/../.." && pwd)"
IOS_ROOT="$PROJECT_ROOT/ios"
PLIST="$IOS_ROOT/Runner/Info.plist"
ICON_DIR="$IOS_ROOT/Runner/Assets.xcassets/AppIcon.appiconset"
CONTENTS_JSON="$ICON_DIR/Contents.json"
SOURCE_SVG="$REPO_ROOT/public/icon.svg"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

for required in "$PLIST" "$CONTENTS_JSON" "$SOURCE_SVG"; do
  if [ ! -f "$required" ]; then
    echo "Missing required Fameverse branding input: $required"
    exit 1
  fi
done

set_plist_string() {
  local key="$1"
  local value="$2"
  "$PLIST_BUDDY" -c "Set :$key $value" "$PLIST" 2>/dev/null || \
    "$PLIST_BUDDY" -c "Add :$key string $value" "$PLIST"
}

set_plist_string CFBundleDisplayName "$APP_NAME"
set_plist_string CFBundleName "$APP_NAME"

TMP_DIR="$(mktemp -d /tmp/fameverse-ios-branding.XXXXXX)"
trap 'rm -rf "$TMP_DIR"' EXIT

# iOS supplies the final rounded app-icon mask. Make the source artwork fully
# opaque so App Store validation never sees transparent rounded corners.
NATIVE_SVG="$TMP_DIR/fameverse-native-icon.svg"
sed 's/<rect width="512" height="512" rx="112"/<rect width="512" height="512"/' \
  "$SOURCE_SVG" > "$NATIVE_SVG"

RAW_PNG="$TMP_DIR/fameverse-raw.png"
if sips -s format png "$NATIVE_SVG" --out "$RAW_PNG" >/dev/null 2>&1; then
  :
else
  qlmanage -t -s 1024 -o "$TMP_DIR" "$NATIVE_SVG" >/dev/null 2>&1
  QL_PNG="$TMP_DIR/$(basename "$NATIVE_SVG").png"
  if [ ! -f "$QL_PNG" ]; then
    echo "Could not rasterize Fameverse app icon from $SOURCE_SVG"
    exit 1
  fi
  mv "$QL_PNG" "$RAW_PNG"
fi

# Round-trip through JPEG to guarantee an opaque RGB source, then return to PNG.
OPAQUE_JPG="$TMP_DIR/fameverse-opaque.jpg"
OPAQUE_PNG="$TMP_DIR/fameverse-opaque.png"
sips -s format jpeg "$RAW_PNG" --out "$OPAQUE_JPG" >/dev/null
sips -s format png "$OPAQUE_JPG" --out "$OPAQUE_PNG" >/dev/null
sips -z 1024 1024 "$OPAQUE_PNG" --out "$TMP_DIR/fameverse-1024.png" >/dev/null
MASTER_PNG="$TMP_DIR/fameverse-1024.png"

python3 - "$CONTENTS_JSON" <<'PY' | while IFS='|' read -r filename pixels; do
import json
import sys

with open(sys.argv[1], encoding='utf-8') as handle:
    payload = json.load(handle)

for image in payload.get('images', []):
    filename = image.get('filename')
    size = image.get('size')
    scale = image.get('scale')
    if not filename or not size or not scale:
        continue
    points = float(size.split('x', 1)[0])
    multiplier = float(scale.rstrip('x'))
    pixels = int(round(points * multiplier))
    print(f'{filename}|{pixels}')
PY
  if [ -z "$filename" ] || [ -z "$pixels" ]; then
    continue
  fi
  sips -z "$pixels" "$pixels" "$MASTER_PNG" \
    --out "$ICON_DIR/$filename" >/dev/null
done

echo "Applied Fameverse iOS branding: name='$APP_NAME', icon='$SOURCE_SVG'"
