#!/usr/bin/env bash
set -euo pipefail

# Device-only Build 33 QA; no TestFlight or App Store publishing.
case "${1:-}" in
  source)
set -euo pipefail
REPO_ROOT="$(git rev-parse --show-toplevel)"
cd "$REPO_ROOT"
test "${CM_BRANCH:-}" = "qa/build33-private-iphone-oct07" || {
  echo "BLOCKED: private QA workflow must run on exact owner QA branch."
  exit 1
}
SOURCE_SHA="$(git rev-parse HEAD)"
# The private branch must contain the reviewed repair snapshot.
git merge-base --is-ancestor f3dcf6f361551205fd5f70bb1ca0d51affc390c8 HEAD || {
  echo "BLOCKED: missing Build 33 repair base."
  exit 1
}
echo "FAMEVERSE_SOURCE_SHA=$SOURCE_SHA" >> "$CM_ENV"
printf '%s\n' \
  "status=PRIVATE_QA_NOT_RELEASE_APPROVED" \
  "build_family=33" \
  "source_branch=${CM_BRANCH}" \
  "source_commit=$SOURCE_SHA" \
  "codemagic_build=${CM_BUILD_ID:-unknown}" \
  "publishing=disabled" > "$REPO_ROOT/native/flutter_v1/build33_private_qa_source.txt"
echo "Private QA source pinned to $SOURCE_SHA"
    ;;
  platforms)
set -euo pipefail
rm -rf /tmp/fameverse_private_qa_shells
flutter create \
  --platforms=ios,android \
  --org com.fameverse \
  --project-name live \
  --no-pub \
  /tmp/fameverse_private_qa_shells
rm -rf ios android
cp -R /tmp/fameverse_private_qa_shells/ios ./ios
cp -R /tmp/fameverse_private_qa_shells/android ./android
for spec in \
  "NSCameraUsageDescription|Fameverse Live uses the camera during live streaming." \
  "NSMicrophoneUsageDescription|Fameverse Live uses the microphone during live streaming." \
  "NSPhotoLibraryUsageDescription|Fameverse lets you select a profile picture and private proof videos."
do
  KEY="${spec%%|*}"
  VALUE="${spec#*|}"
  /usr/libexec/PlistBuddy -c "Set :$KEY $VALUE" ios/Runner/Info.plist 2>/dev/null || \
  /usr/libexec/PlistBuddy -c "Add :$KEY string $VALUE" ios/Runner/Info.plist
done
bash tool/apply_ios_branding.sh
bash tool/apply_android_branding.sh
if [ -f android/app/build.gradle.kts ]; then
  sed -i.bak 's/minSdk = flutter.minSdkVersion/minSdk = 24/' android/app/build.gradle.kts
elif [ -f android/app/build.gradle ]; then
  sed -i.bak 's/minSdkVersion flutter.minSdkVersion/minSdkVersion 24/' android/app/build.gradle
fi
grep -Fq 'PRODUCT_BUNDLE_IDENTIFIER = com.fameverse.live;' ios/Runner.xcodeproj/project.pbxproj || {
  echo "BLOCKED: mismatched Fameverse iOS bundle identifier."
  exit 1
}
    ;;
  packages)
set -euo pipefail
flutter pub get
    ;;
  gates)
set -euo pipefail
dart run tool/check_native_contract.dart
bash tool/verify_ios_branding.sh
bash tool/verify_android_branding.sh
dart format --output=none --set-exit-if-changed lib test tool
flutter analyze
flutter test
    ;;
  android)
set -euo pipefail
flutter build apk --debug \
  --dart-define=FAMEVERSE_BUILD_FAMILY=33 \
  --dart-define=FAMEVERSE_SOURCE_SHA="$FAMEVERSE_SOURCE_SHA"
test -s build/app/outputs/flutter-apk/app-debug.apk
    ;;
  ios-unsigned)
set -euo pipefail
find . -name Podfile -execdir pod install \;
flutter build ios --debug --no-codesign \
  --dart-define=FAMEVERSE_BUILD_FAMILY=33 \
  --dart-define=FAMEVERSE_SOURCE_SHA="$FAMEVERSE_SOURCE_SHA"
    ;;
  adhoc)
set -euo pipefail
test -n "${CM_CERTIFICATE:-}" || {
  echo "BLOCKED: missing CM_CERTIFICATE distribution P12."
  exit 1
}
test -n "${CM_CERTIFICATE_PASSWORD:-}" || {
  echo "BLOCKED: missing CM_CERTIFICATE_PASSWORD."
  exit 1
}
# Prefer the QA-only variable; never mistake an App Store profile for device-installable signing.
PROFILE_B64="${CM_QA_ADHOC_PROVISIONING_PROFILE:-${CM_PROVISIONING_PROFILE:-}}"
test -n "$PROFILE_B64" || {
  echo "BLOCKED: add CM_QA_ADHOC_PROVISIONING_PROFILE with the owner's iPhone UDID."
  exit 1
}
PROFILE_PATH="/tmp/fameverse_private_qa.mobileprovision"
printf '%s' "$PROFILE_B64" | base64 --decode > "$PROFILE_PATH"
security cms -D -i "$PROFILE_PATH" -o /tmp/fameverse_qa_profile.plist
/usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' /tmp/fameverse_qa_profile.plist >/dev/null || {
  echo "BLOCKED: App Store profile cannot be installed directly on an iPhone. An Ad Hoc profile containing the owner's UDID is required."
  exit 1
}
QA_TEAM_ID="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' /tmp/fameverse_qa_profile.plist)"
QA_PROFILE_NAME="$(/usr/libexec/PlistBuddy -c 'Print :Name' /tmp/fameverse_qa_profile.plist)"
QA_APP_ID="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' /tmp/fameverse_qa_profile.plist)"
test "$QA_APP_ID" = "$QA_TEAM_ID.com.fameverse.live" || {
  echo "BLOCKED: the Ad Hoc profile does not match com.fameverse.live."
  exit 1
}
keychain initialize
printf '%s' "$CM_CERTIFICATE" | base64 --decode > /tmp/fameverse_qa_distribution.p12
openssl pkcs12 -in /tmp/fameverse_qa_distribution.p12 \
  -passin pass:"$CM_CERTIFICATE_PASSWORD" -noout
keychain add-certificates \
  --certificate /tmp/fameverse_qa_distribution.p12 \
  --certificate-password "$CM_CERTIFICATE_PASSWORD"
mkdir -p "$HOME/Library/MobileDevice/Provisioning Profiles"
cp "$PROFILE_PATH" "$HOME/Library/MobileDevice/Provisioning Profiles/fameverse_private_qa.mobileprovision"
xcode-project use-profiles \
  --project ios/Runner.xcodeproj \
  --profile "$PROFILE_PATH"
cat >/tmp/fameverse_qa_export_options.plist <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>ad-hoc</string>
  <key>signingStyle</key><string>manual</string>
  <key>teamID</key><string>$QA_TEAM_ID</string>
  <key>provisioningProfiles</key>
  <dict><key>com.fameverse.live</key><string>$QA_PROFILE_NAME</string></dict>
</dict>
</plist>
EOF
plutil -lint /tmp/fameverse_qa_export_options.plist
echo "Verified device-installable Ad Hoc profile (owner must confirm iPhone UDID enrollment)."
    ;;
  ipa)
set -euo pipefail
flutter build ipa --release \
  --build-number="$BUILD_NUMBER" \
  --dart-define=FAMEVERSE_BUILD_FAMILY=33 \
  --dart-define=FAMEVERSE_SOURCE_SHA="$FAMEVERSE_SOURCE_SHA" \
  --dart-define=FAMEVERSE_QA_ONLY=true \
  --export-options-plist=/tmp/fameverse_qa_export_options.plist
test -n "$(find build/ios/ipa -maxdepth 1 -type f -name '*.ipa' -print -quit)"
echo "PRIVATE owner-device QA artifact created. Distribution remains disabled."
    ;;
  *) echo "Unknown private QA build stage" >&2; exit 2 ;;
esac
