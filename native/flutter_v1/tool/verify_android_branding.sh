#!/usr/bin/env bash
set -euo pipefail

APP_NAME="${FAMEVERSE_APP_NAME:-Fameverse}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ANDROID_ROOT="$PROJECT_ROOT/android"
MANIFEST="$ANDROID_ROOT/app/src/main/AndroidManifest.xml"

if [ ! -f "$MANIFEST" ]; then
  echo "AndroidManifest.xml is missing."
  exit 1
fi

if ! grep -Fq "android:label=\"$APP_NAME\"" "$MANIFEST"; then
  echo "Android app label is not locked to '$APP_NAME'."
  exit 1
fi

for density in mdpi hdpi xhdpi xxhdpi xxxhdpi; do
  icon="$ANDROID_ROOT/app/src/main/res/mipmap-$density/ic_launcher.png"
  if [ ! -s "$icon" ]; then
    echo "Missing Fameverse launcher icon: $icon"
    exit 1
  fi
  size=$(wc -c < "$icon" | tr -d ' ')
  if [ "$size" -lt 500 ]; then
    echo "Launcher icon is unexpectedly small: $icon ($size bytes)"
    exit 1
  fi
done

echo "Verified Fameverse Android branding: name='$APP_NAME' and all launcher densities present."
