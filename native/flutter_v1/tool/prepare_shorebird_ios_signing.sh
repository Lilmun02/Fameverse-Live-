#!/usr/bin/env bash
set -euo pipefail
umask 077

# No distribution: install the SAME manually provisioned Fameverse assets used by
# native-testflight, but make Xcode preserve Shorebird's exact release identity.
if [ "${FAMEVERSE_OTA_STAGE:-}" != "ios-signed-dry-run" ]; then
  echo "BLOCKED: Apple signing setup is restricted to the manual iOS dry-run."
  exit 1
fi

for name in CM_CERTIFICATE CM_CERTIFICATE_PASSWORD CM_PROVISIONING_PROFILE; do
  if [ -z "${!name:-}" ]; then
    echo "BLOCKED: required Apple signing credential is missing: $name"
    exit 1
  fi
done

PROFILES_HOME="$HOME/Library/MobileDevice/Provisioning Profiles"
mkdir -p "$PROFILES_HOME"
PROFILE_PATH="$PROFILES_HOME/fameverse_shorebird_app_store.mobileprovision"
CERT_PATH="/tmp/fameverse_shorebird_distribution.p12"
PROFILE_METADATA="/tmp/fameverse_shorebird_profile.plist"
trap 'rm -f "$CERT_PATH" "$PROFILE_METADATA"' EXIT

printf '%s' "$CM_PROVISIONING_PROFILE" | base64 --decode > "$PROFILE_PATH"
security cms -D -i "$PROFILE_PATH" > "$PROFILE_METADATA"

# Reject wrong app, wildcard, development and expired distribution profiles
# before importing credentials or attempting an IPA build.
python3 - "$PROFILE_METADATA" <<'PY'
from datetime import datetime, timezone
import plistlib
import sys

with open(sys.argv[1], 'rb') as handle:
    profile = plistlib.load(handle)
entitlements = profile.get('Entitlements', {})
app_identifier = entitlements.get('application-identifier', '')
app_id = app_identifier.split('.', 1)[-1]
if app_id != 'com.fameverse.live':
    raise SystemExit('BLOCKED: provisioning profile is not for com.fameverse.live')
if entitlements.get('get-task-allow') is not False:
    raise SystemExit('BLOCKED: provisioning profile is not an App Store distribution profile')
expires = profile.get('ExpirationDate')
if expires is None:
    raise SystemExit('BLOCKED: provisioning profile is missing an expiration date')
now = datetime.now(timezone.utc)
if expires.replace(tzinfo=timezone.utc) <= now:
    raise SystemExit('BLOCKED: Apple provisioning profile has expired')
print('App Store distribution profile matches Fameverse bundle ID and is not expired.')
PY

printf '%s' "$CM_CERTIFICATE" | base64 --decode > "$CERT_PATH"
openssl pkcs12 \
  -in "$CERT_PATH" \
  -passin pass:"$CM_CERTIFICATE_PASSWORD" \
  -noout >/dev/null
keychain initialize
keychain add-certificates \
  --certificate "$CERT_PATH" \
  --certificate-password "$CM_CERTIFICATE_PASSWORD"

xcode-project use-profiles \
  --project ios/Runner.xcodeproj \
  --profile "$PROFILE_PATH" \
  --custom-export-options='{"manageAppVersionAndBuildNumber":false}'

EXPORT_OPTIONS="/Users/builder/export_options.plist"
test -s "$EXPORT_OPTIONS"
python3 - "$EXPORT_OPTIONS" <<'PY'
import plistlib
import sys

with open(sys.argv[1], 'rb') as handle:
    export_options = plistlib.load(handle)
if export_options.get('manageAppVersionAndBuildNumber') is not False:
    raise SystemExit('BLOCKED: Xcode would rewrite the Shorebird release version/build number')
print('Shorebird-safe IPA export options verified: preserve app version and build number.')
PY

echo "Fameverse manual signing is configured for a non-publishing Shorebird dry-run."
