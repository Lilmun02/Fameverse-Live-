# Fameverse Build 33 — private owner-device QA only

**Status:** candidate; no signed device IPA confirmed yet.
**Source branch:** `qa/build33-private-iphone-oct07`
**Base repair commit:** `f3dcf6f361551205fd5f70bb1ca0d51affc390c8`
**Codemagic workflow ID:** `native-owner-private-qa`
**GitHub validation workflow:** `Build 33 Private QA Source Validation`

## Boundary / product requirements

This source is for a **private physical iPhone test of the repaired native product**.
It is not a merge into `integration/sep27-big-update` or `main`, and has no
`publishing` stage. Do not distribute it to TestFlight groups or external
testers, or submit it to App Store Review, without further owner approval.

- Native Creator Studio **Bring Your Badge** is read-only until the owner
  approves the actual conversion policy and the secure backend is deployed.
- Existing member QA/promo coins were retired via audited balance events;
  no additional test coins are minted by this build.
- The QA builder cannot override real purchases or alter production wallet,
  creator payout, and owner role controls.
- The physical acceptance gate remains pending, **by design**, until the
  exact signed build runs on owner and external tester devices as appropriate.
- No user report of gift animation/streaming parity is considered proven from
  compilation alone.

## To start / inspect the private build in Codemagic

1. Open the **Fameverse Live** app in Codemagic, then check **Builds** for
   the automatic `native-owner-private-qa` run triggered by the QA branch.
   If no run started (webhook missing), select **Start new build**.
2. Branch: `qa/build33-private-iphone-oct07`.
3. Workflow: **Fameverse Build 33 - PRIVATE owner iPhone QA (NO PUBLISH)**.
4. Make sure the existing `manual_signing` variable group contains
   `CM_CERTIFICATE` (base64-encoded Apple Distribution P12),
   `CM_CERTIFICATE_PASSWORD`, and
   **`CM_QA_ADHOC_PROVISIONING_PROFILE`** (base64 Ad Hoc provisioning
   profile for `com.fameverse.live`, including owner's physical iPhone UDID).
   The older `CM_PROVISIONING_PROFILE` is accepted only if its actual Apple
   profile proves it is Ad Hoc; an **App Store profile is rejected**.
5. If using a Codemagic **personal** account, register the iPhone's UDID in
   the Apple Developer portal manually, regenerate/download the Ad Hoc
   profile, and set `CM_QA_ADHOC_PROVISIONING_PROFILE` securely in
   Codemagic. Do not paste profile/certificate/API credentials into chat.
6. Once the Mac build passes, download the signed
   `build/ios/ipa/*.ipa` from Codemagic. Codemagic offers an install
   method / QR code for an appropriately provisioned device. Ensure the
   device is included in the signed profile before attempting install.
7. Check `build33_private_qa_source.txt` matches the **exact** source
   commit and states `publishing=disabled`. Document physical iPhone
   acceptance and failures against that commit/build before any promotion.

The workflow also compiles `build/app/outputs/flutter-apk/app-debug.apk`
for the owner's Android if desired, but does **not** upload Android artifacts
to the public GitHub Actions project.

## Build-source integrity

The branch is separate from the draft PR. Every QA push may produce a new
commit/build. Always use the latest candidate from the QA branch and inspect
its source SHA. Codemagic builds from its checked-out QA commit and never
performs the older TestFlight workflow's forced Build 32 checkout.

The existing `native-testflight` configuration has not been touched.
