#!/usr/bin/env bash
set -euo pipefail

# Build 33: TestFlight INTERNAL ONLY. No App Store release or external beta review.
case "${1:-}" in
  source)
    REPO_ROOT="$(git rev-parse --show-toplevel)"
    cd "$REPO_ROOT"
    TARGET_BRANCH="qa/build33-private-iphone-oct07"
    test "${CM_BRANCH:-}" = "$TARGET_BRANCH" || {
      echo "BLOCKED: TestFlight Build 33 requires $TARGET_BRANCH."
      exit 1
    }
    SOURCE_SHA="$(git rev-parse HEAD)"
    git fetch --no-tags origin "+refs/heads/$TARGET_BRANCH:refs/remotes/origin/$TARGET_BRANCH"
    TARGET_SHA="$(git rev-parse "refs/remotes/origin/$TARGET_BRANCH")"
    test "$SOURCE_SHA" = "$TARGET_SHA" || {
      echo "BLOCKED: Build source is stale; checkout=$SOURCE_SHA expected=$TARGET_SHA"
      exit 1
    }
    echo "FAMEVERSE_SOURCE_SHA=$SOURCE_SHA" >> "$CM_ENV"
    printf '%s\n' \
      "status=INTERNAL_TESTFLIGHT_CANDIDATE_NOT_RELEASE_APPROVED" \
      "build_family=33" \
      "source_branch=$TARGET_BRANCH" \
      "source_commit=$SOURCE_SHA" \
      "codemagic_build=${CM_BUILD_ID:-unknown}" \
      "distribution=TESTFLIGHT_INTERNAL_ONLY" \
      "external_beta_review=false" \
      "app_store_release=false" \
      > "$REPO_ROOT/native/flutter_v1/build33_testflight_source.txt"
    echo "Build 33 internal TestFlight source verified: $SOURCE_SHA"
    ;;
  products)
    test -f lib/features/profile/native_badge_transfer_preview.dart
    grep -Fq 'COMING SOON' lib/features/profile/native_badge_transfer_preview.dart
    if grep -Fq 'submit_badge_transfer_claim' lib/features/profile/native_badge_transfer_preview.dart; then
      echo "BLOCKED: unapproved badge transfers are enabled in this candidate."
      exit 1
    fi
    if grep -Fq 'Build23OwnerControlCenterScreen' lib/features/shell/fameverse_shell_build23.dart; then
      echo "BLOCKED: web-only Owner Control Center must not open inside native app."
      exit 1
    fi
    grep -Fq 'NativeBadgeTransferPreview()' lib/features/profile/creator_studio_build23.dart
    grep -Fq 'profile-fame-coins-card' lib/features/profile/native_profile_build23.dart
    grep -Fq 'get_fameverse_rankings_v2' lib/features/live/native_live_rankings.dart
    grep -Fq 'owner-host-gift-button' lib/features/live/stream_host_live_screen.dart
    test -f lib/features/profile/fame_coin_store_screen.dart
    echo "Verified Build 33 owner QA features; badge transfers remain read-only."
    ;;
  secrets)
    for name in \
      APP_STORE_CONNECT_PRIVATE_KEY \
      APP_STORE_CONNECT_KEY_IDENTIFIER \
      APP_STORE_CONNECT_ISSUER_ID \
      CM_CERTIFICATE \
      CM_CERTIFICATE_PASSWORD \
      CM_PROVISIONING_PROFILE
    do
      if [ -z "${!name:-}" ]; then
        echo "BLOCKED: Codemagic environment variable $name is missing."
        exit 1
      fi
    done
    echo "Existing App Store Connect and signing credentials present."
    ;;
  ios)
    rm -rf /tmp/fameverse_build33_testflight_ios
    flutter create \
      --platforms=ios \
      --org com.fameverse \
      --project-name live \
      --no-pub \
      /tmp/fameverse_build33_testflight_ios
    rm -rf ios
    cp -R /tmp/fameverse_build33_testflight_ios/ios ./ios
    for spec in \
      "NSCameraUsageDescription|Fameverse Live uses the camera while hosting streams." \
      "NSMicrophoneUsageDescription|Fameverse Live uses the microphone while hosting streams." \
      "NSPhotoLibraryUsageDescription|Fameverse lets you choose a profile picture."
    do
      KEY="${spec%%|*}"
      VALUE="${spec#*|}"
      /usr/libexec/PlistBuddy -c "Set :$KEY $VALUE" ios/Runner/Info.plist 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :$KEY string $VALUE" ios/Runner/Info.plist
    done
    bash tool/apply_ios_branding.sh
    bash tool/verify_ios_branding.sh
    grep -Fq 'PRODUCT_BUNDLE_IDENTIFIER = com.fameverse.live;' ios/Runner.xcodeproj/project.pbxproj || {
      echo "BLOCKED: wrong iOS bundle identifier; refusing to upload."
      exit 1
    }
    ;;
  dependencies)
    flutter pub get
    dart run tool/check_native_contract.dart
    dart format --output=none --set-exit-if-changed lib test tool
    flutter analyze
    flutter test
    find . -name Podfile -execdir pod install \;
    ;;
  sign)
    keychain initialize
    PROFILE_PATH="/tmp/fameverse_build33_appstore.mobileprovision"
    printf '%s' "$CM_PROVISIONING_PROFILE" | base64 --decode > "$PROFILE_PATH"
    security cms -D -i "$PROFILE_PATH" -o /tmp/fameverse_build33_profile.plist
    if /usr/libexec/PlistBuddy -c 'Print :ProvisionedDevices' /tmp/fameverse_build33_profile.plist >/dev/null 2>&1; then
      echo "BLOCKED: Ad Hoc profile supplied; TestFlight needs App Store distribution."
      exit 1
    fi
    TEAM_ID="$(/usr/libexec/PlistBuddy -c 'Print :TeamIdentifier:0' /tmp/fameverse_build33_profile.plist)"
    APP_ID="$(/usr/libexec/PlistBuddy -c 'Print :Entitlements:application-identifier' /tmp/fameverse_build33_profile.plist)"
    test "$APP_ID" = "$TEAM_ID.com.fameverse.live" || {
      echo "BLOCKED: App Store profile does not match com.fameverse.live."
      exit 1
    }
    CERT_PATH="/tmp/fameverse_build33_distribution.p12"
    printf '%s' "$CM_CERTIFICATE" | base64 --decode > "$CERT_PATH"
    openssl pkcs12 -in "$CERT_PATH" -passin pass:"$CM_CERTIFICATE_PASSWORD" -noout
    keychain add-certificates \
      --certificate "$CERT_PATH" \
      --certificate-password "$CM_CERTIFICATE_PASSWORD"
    xcode-project use-profiles \
      --project ios/Runner.xcodeproj \
      --profile "$PROFILE_PATH" \
      --custom-export-options='{"testFlightInternalTestingOnly": true}'
    EXPORT_OPTIONS="/Users/builder/export_options.plist"
    test -f "$EXPORT_OPTIONS" || {
      echo "BLOCKED: Codemagic export options not generated."
      exit 1
    }
    test "$(/usr/libexec/PlistBuddy -c 'Print :testFlightInternalTestingOnly' "$EXPORT_OPTIONS")" = "true" || {
      echo "BLOCKED: internal-only TestFlight export flag was not set."
      exit 1
    }
    echo "Verified App Store signing and internal-TestFlight-only export."
    ;;
  package)
    test -n "${FAMEVERSE_SOURCE_SHA:-}" || {
      echo "BLOCKED: source identity missing."
      exit 1
    }
    BUILD33_NUMBER="${BUILD_NUMBER:-1}"
    if [ -n "${APP_STORE_APPLE_ID:-}" ]; then
      LATEST_BUILD="$(app-store-connect get-latest-testflight-build-number "$APP_STORE_APPLE_ID" --all-versions)"
      if [[ "$LATEST_BUILD" =~ ^[0-9]+$ ]] && (( BUILD33_NUMBER <= LATEST_BUILD )); then
        BUILD33_NUMBER="$((LATEST_BUILD + 1))"
      fi
    fi
    if ! [[ "$BUILD33_NUMBER" =~ ^[0-9]+$ ]] || (( BUILD33_NUMBER < 1 )); then
      echo "BLOCKED: iOS build number is not valid."
      exit 1
    fi
    flutter build ipa --release \
      --build-number="$BUILD33_NUMBER" \
      --dart-define="FAMEVERSE_BUILD_FAMILY=33" \
      --dart-define="FAMEVERSE_SOURCE_SHA=$FAMEVERSE_SOURCE_SHA" \
      --dart-define="FAMEVERSE_INTERNAL_TESTFLIGHT_ONLY=true" \
      --export-options-plist=/Users/builder/export_options.plist
    test -n "$(find build/ios/ipa -maxdepth 1 -type f -name '*.ipa' -print -quit)"
    printf '%s\n' "apple_build_number=$BUILD33_NUMBER" >> build33_testflight_source.txt
    echo "Build 33 internal-only IPA is signed and ready for App Store Connect upload."
    ;;
  *)
    echo "Invalid Build 33 TestFlight stage." >&2
    exit 2
    ;;
esac
