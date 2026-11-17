#!/usr/bin/env bash
set -euo pipefail

# Prepare a fresh, unsigned, non-publishing iOS project for Shorebird CI.
# For a future approved release/patch, reuse this exact shell-generation logic.
if [ "${FAMEVERSE_OTA_STAGE:-}" != "ios-dry-run" ]; then
  echo "BLOCKED: Shorebird iOS bootstrap is restricted to dry-run preflight."
  exit 1
fi

if git ls-files -- ios | grep -q .; then
  echo "BLOCKED: tracked iOS platform files exist; cannot replace them."
  exit 1
fi

TMP_PLATFORM="$(mktemp -d /tmp/fameverse-shorebird-ios.XXXXXX)"
trap 'rm -rf "$TMP_PLATFORM"' EXIT
flutter create \
  --platforms=ios \
  --org com.fameverse \
  --project-name live \
  --no-pub \
  "$TMP_PLATFORM"

test -f "$TMP_PLATFORM/ios/Runner.xcodeproj/project.pbxproj"
rm -rf ios
cp -R "$TMP_PLATFORM/ios" ./ios

# Match the existing native-testflight camera/microphone permissions exactly.
/usr/libexec/PlistBuddy \
  -c "Set :NSCameraUsageDescription Fameverse Live uses the camera for native live preview and hosting." \
  ios/Runner/Info.plist 2>/dev/null || \
/usr/libexec/PlistBuddy \
  -c "Add :NSCameraUsageDescription string Fameverse Live uses the camera for native live preview and hosting." \
  ios/Runner/Info.plist

/usr/libexec/PlistBuddy \
  -c "Set :NSMicrophoneUsageDescription Fameverse Live uses the microphone for native live hosting." \
  ios/Runner/Info.plist 2>/dev/null || \
/usr/libexec/PlistBuddy \
  -c "Add :NSMicrophoneUsageDescription string Fameverse Live uses the microphone for native live hosting." \
  ios/Runner/Info.plist

# Preserve the existing canonical iOS identity, splash, icon, and permissions.
bash tool/apply_ios_branding.sh
bash tool/verify_ios_branding.sh
if ! grep -Fq "PRODUCT_BUNDLE_IDENTIFIER = com.fameverse.live;" ios/Runner.xcodeproj/project.pbxproj; then
  echo "BLOCKED: iOS bundle identifier is not the approved com.fameverse.live."
  exit 1
fi
echo "Shorebird iOS shell verified: com.fameverse.live; unsigned dry-run only."
