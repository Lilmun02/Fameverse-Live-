#!/usr/bin/env bash
set -euo pipefail

# A builder-only, deterministic native shell for Shorebird Android checks.
# Reuse this exact script for a separately approved release and its patches.
if [ "${FAMEVERSE_OTA_STAGE:-}" != "android-dry-run" ]; then
  echo "BLOCKED: Android Shorebird bootstrap is restricted to dry-run preflight."
  exit 1
fi

if git ls-files -- android | grep -q .; then
  echo "BLOCKED: tracked Android platform files exist; do not replace them."
  exit 1
fi

TMP_PLATFORM="/tmp/fameverse_shorebird_android_shell"
rm -rf "$TMP_PLATFORM"
flutter create \
  --platforms=android \
  --org com.fameverse \
  --project-name live \
  --no-pub \
  "$TMP_PLATFORM"

test -f "$TMP_PLATFORM/android/app/src/main/AndroidManifest.xml"
rm -rf android
cp -R "$TMP_PLATFORM/android" ./android

# Mirror the native-foundation minimum SDK rule without changing tracked files.
if [ -f android/app/build.gradle.kts ]; then
  sed -i.bak 's/minSdk = flutter.minSdkVersion/minSdk = 24/' android/app/build.gradle.kts
  grep -Fq 'applicationId = "com.fameverse.live"' android/app/build.gradle.kts
  grep -Fq 'minSdk = 24' android/app/build.gradle.kts
elif [ -f android/app/build.gradle ]; then
  sed -i.bak 's/minSdkVersion flutter.minSdkVersion/minSdkVersion 24/' android/app/build.gradle
  grep -Fq 'applicationId "com.fameverse.live"' android/app/build.gradle
  grep -Fq 'minSdkVersion 24' android/app/build.gradle
else
  echo "BLOCKED: expected Flutter Android Gradle build file is missing."
  exit 1
fi

bash tool/apply_android_branding.sh
bash tool/verify_android_branding.sh
echo "Android dry-run native shell verified: com.fameverse.live / minSdk 24."
