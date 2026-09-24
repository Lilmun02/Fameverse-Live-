#!/usr/bin/env bash
set -euo pipefail

EXPECTED_NAME="${FAMEVERSE_APP_NAME:-Fameverse}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PROJECT_ROOT/../.." && pwd)"
IOS_ROOT="$PROJECT_ROOT/ios"
PLIST="$IOS_ROOT/Runner/Info.plist"
ICON_DIR="$IOS_ROOT/Runner/Assets.xcassets/AppIcon.appiconset"
CONTENTS_JSON="$ICON_DIR/Contents.json"
SOURCE_SVG="$REPO_ROOT/public/icon.svg"
PLIST_BUDDY="/usr/libexec/PlistBuddy"

for required in "$PLIST" "$CONTENTS_JSON" "$SOURCE_SVG"; do
  test -f "$required" || {
    echo "Branding law failed: missing $required"
    exit 1
  }
done

display_name="$($PLIST_BUDDY -c 'Print :CFBundleDisplayName' "$PLIST")"
bundle_name="$($PLIST_BUDDY -c 'Print :CFBundleName' "$PLIST")"

if [ "$display_name" != "$EXPECTED_NAME" ]; then
  echo "Branding law failed: CFBundleDisplayName='$display_name', expected '$EXPECTED_NAME'"
  exit 1
fi

if [ "$bundle_name" != "$EXPECTED_NAME" ]; then
  echo "Branding law failed: CFBundleName='$bundle_name', expected '$EXPECTED_NAME'"
  exit 1
fi

if ! grep -Fq 'aria-label="Fameverse crown"' "$SOURCE_SVG"; then
  echo "Branding law failed: canonical Fameverse crown artwork is missing"
  exit 1
fi

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
  path="$ICON_DIR/$filename"
  if [ ! -s "$path" ]; then
    echo "Branding law failed: missing generated AppIcon file $path"
    exit 1
  fi

  width="$(sips -g pixelWidth "$path" 2>/dev/null | awk '/pixelWidth/ {print $2}')"
  height="$(sips -g pixelHeight "$path" 2>/dev/null | awk '/pixelHeight/ {print $2}')"
  if [ "$width" != "$pixels" ] || [ "$height" != "$pixels" ]; then
    echo "Branding law failed: $filename is ${width}x${height}, expected ${pixels}x${pixels}"
    exit 1
  fi
done

if grep -Eq '<string>(Live|live)</string>' "$PLIST"; then
  echo "Branding law failed: Flutter placeholder display name remains in Info.plist"
  exit 1
fi

echo "Fameverse iOS branding law passed: '$EXPECTED_NAME' with canonical crown AppIcon set."
