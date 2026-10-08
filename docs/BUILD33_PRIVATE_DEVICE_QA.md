# Fameverse Build 33 — INTERNAL TestFlight candidate

**Status:** Native iOS/Android code has passed GitHub preflight; new Codemagic
internal TestFlight signing/upload requires a successful Codemagic run.
**Source branch:** `qa/build33-private-iphone-oct07`
**TestFlight workflow:** `native-build33-internal-testflight`
**Bundle ID:** `com.fameverse.live`

## What this does

This workflow produces a signed iPhone IPA using the existing
`appstore_credentials` and `manual_signing` variable groups in Codemagic,
then uploads it to **App Store Connect** for existing **internal TestFlight
testers**. The export is explicitly marked `testFlightInternalTestingOnly`.

- Does **not** require Ad Hoc signing, device UDID registration, or a direct IPA
  download on the iPhone.
- Does **not** submit to App Store review or publish to public customers.
- Does **not** submit to external beta review or assign external groups.
- Does **not** merge the QA branch into `main` or
  `integration/sep27-big-update`.
- Does **not** deploy unfinished badge-transfer migrations or mint test coins.
- Does **not** imply purchase verification has passed on a real iPhone.

The existing `native-testflight` Build 32 workflow is left intact.
**Never select that workflow for Build 33**: it forces the old Build 32 source.

## Start Build 33 in Codemagic

Codemagic may auto-start the workflow on a push to the QA branch if the
repository webhook and trigger settings are configured. If there is no active
Build 33 Codemagic run, manually start a build:

1. Open **Codemagic → Fameverse Live → Start new build**.
2. Select branch: `qa/build33-private-iphone-oct07`.
3. Select workflow: **Fameverse Build 33 - INTERNAL TestFlight (NOT App Store
   Release)** (`native-build33-internal-testflight`).
4. Start the workflow. The script checks the exact QA commit before signing.
5. Once Codemagic reports **App Store Connect upload succeeded**, open
   **App Store Connect → Fameverse Live → TestFlight → Internal Testing**.
6. After Apple processes the upload, select the new build for your existing
   internal tester group if it is not automatically assigned. Your iPhone
   TestFlight app then offers the build to install/update.

The TestFlight build's actual Apple build number may differ from the internal
project nickname "Build 33". Codemagic assigns its own build counter, and the
script can compare against TestFlight if optional `APP_STORE_APPLE_ID` is set
in the connected Codemagic environment.

## Existing credentials

The workflow reuses the existing `appstore_credentials` variables:
`APP_STORE_CONNECT_PRIVATE_KEY`, `APP_STORE_CONNECT_KEY_IDENTIFIER`,
`APP_STORE_CONNECT_ISSUER_ID`; and the existing `manual_signing` variables:
`CM_CERTIFICATE`, `CM_CERTIFICATE_PASSWORD`, `CM_PROVISIONING_PROFILE`.

Do not paste credentials, profiles, or certificate contents into chat.
If Codemagic fails at signing or publishing, consult the exact failed step.

## Acceptance

Automated native compilation is not device acceptance. After TestFlight
installation, check signing in, camera and co-host, live gifts and sender
avatars, Creator Studio, Fame Coins wallet/checkout, and an Apple sandbox
purchase before declaring Apple IAP launch-ready.

**Owner review/approval required** before external TestFlight groups,
public store submission, migration of badge transfers, or production launch.
