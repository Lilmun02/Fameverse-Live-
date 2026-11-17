# Fameverse Build 48 — Shorebird OTA readiness and approval gate

**Status:** OPEN — Shorebird app configuration is registered and a manual-only, non-publishing CI readiness candidate has been added to draft PR #176. No Shorebird release/patch has been created; physical acceptance and owner release authorization are outstanding.

## Owner-approved intent

Add an optional, controlled **test-track** update path so approved Dart-only Fameverse fixes can be tested on already-installed **Shorebird-enabled** Android and physical iPhone builds without rebuilding or resubmitting every eligible patch. Continue normal TestFlight/App Store/Google Play releases for new native capabilities, SDK/plugin and asset changes, and updates that require store review.

This document does **not** authorize a release, patch publication, store upload, Supabase migration, production change, or merge. Existing Build 48 repair PRs retain their independent gates.

## Verified existing repository baseline (2026-11-15)

- Build 48 development branch: `build48/performance-live-stability-android-ios-nov15`; inspected HEAD `1cf52cacb558a9024f358570b73470939a768096`.
- Flutter project root is `native/flutter_v1`; `pubspec.yaml` version is `0.2.0+1`.
- At the original baseline, no Shorebird registration existed. This draft PR now includes the owner-generated `native/flutter_v1/shorebird.yaml` with app ID `ea33cadb-6ccd-4491-af48-6a617223a462` and its `pubspec.yaml` asset entry.
- Existing `codemagic.yaml` has `native-foundation` and `native-testflight` workflows. Both regenerate the native platform directories before building; preserve their branding/signing/identity safety gates.
- `startup_update_service.dart` reads update notices from Supabase. It is **not** code push.
- Do not touch or merge existing gift, policy, ranking, layout or CI repair PRs as part of this readiness work.

## Architecture and choice

1. **Shorebird** for eligible compiled Dart-only patches to **the exact Shorebird release version** used by testers.
2. **Supabase** for safe data/config notices or pre-existing server-configurable behaviors; not arbitrary downloaded code.
3. **Store-distributed native builds** for changes to Swift, Kotlin, plugins/SDKs, Flutter version, app signing/permissions, bundled assets, and anything requiring applicable review.

The first compatible OTA-enabled app must itself be created with `shorebird release` and installed through an approved distribution channel. Existing Flutter/TestFlight builds created without Shorebird will not become patchable retroactively. A patch is not permission to bypass Apple policies.

## Owner-side setup and evidence status

1. **Completed (owner terminal output):** Signed into Shorebird and ran `shorebird init` in `native/flutter_v1` on the isolated OTA branch; the CLI reported initialization success.
2. **Completed (GitHub commit `79bfdb4`):** Committed the real owner-generated `shorebird.yaml` and `pubspec.yaml` asset entry to the draft branch, without merging.
3. **Owner-reported completed; CI verification PENDING:** Created a service-account API key and stored `SHOREBIRD_TOKEN` in Codemagic group `shorebird`, marked secure. The key has not been inspected by the assistant, and its availability has not yet been verified by a Codemagic run. Never paste keys into chat, GitHub, PR comments, or logs.
4. Approve the specific first OTA-enabled signed iOS/Android build and testers before any publication; Apple signing/App Store Connect and Play distribution approvals remain separate.

## Engineering implementation plan (future commits, one task per review)

### Task A — registered configuration, no runtime changes outside Shorebird setup

- [x] Validate the GitHub-committed `shorebird.yaml` contains the owner-generated app ID and `pubspec.yaml` includes it as an asset.
- [ ] Verify the correct Fameverse package/bundle identifiers and project root; never invent IDs or use a replacement app identifier.
- [ ] Run `shorebird doctor`, normal Flutter formatting/analyze/tests, and native contract/branding checks; record exact outputs.
- [ ] Review source diff for unrelated UI, assets, payments, policy or Live mutations. None are permitted.

### Task B — isolated, manual-only build foundation

- [x] Add `shorebird-ota-readiness`, a separate non-publishing, **manual** Codemagic OTA validation workflow; existing `native-foundation` and `native-testflight` workflow bodies were preserved.
- [ ] Pin the Shorebird/Flutter/Xcode/CocoaPods toolchain; ensure the generated platform shells are identical for a release and a patch.
- [ ] Run actual Android and iOS validation. Audit `SHOREBIRD_TOKEN` availability without logging its value.
- [ ] Inspect output artifacts, signing, installability and source SHA. Unsigned compilation alone is not device acceptance.
- [ ] Do **not** run `shorebird release` or `shorebird patch` against a real app from automatic CI; require a separate owner-authorized action.

### Task C — first test release, separately authorized

- [ ] Lock the exact source commit and release build number (never reuse an unrelated TestFlight IPA).
- [ ] Get explicit owner approval for first signed OTA-enabled TestFlight/Android distribution.
- [ ] Confirm the installed IPA/APK was produced by `shorebird release ios/android`, not by ordinary `flutter build`.
- [ ] Physically install and validate on a real iPhone and Android phone; verify app identity, Stream camera/microphone, Live, gift, policies, economy, background/resume and crash/performance behavior.
- [ ] Mark only FIX_CANDIDATE until the owner's required physical acceptance is recorded.

### Task D — test-track patch workflow, separately authorized

- [ ] Select one approved Dart-only fix and confirm it targets an existing Shorebird release.
- [ ] Before patching: confirm **no native, bundled asset, Flutter engine or build-flag changes** and verify exact release version/toolchain.
- [ ] Run Flutter tests, Android/iOS compilation and `shorebird patch <platform> --release-version=<exact-version> --dry-run` using the approved test configuration; preserve full outputs.
- [ ] Review diff, dependency overlap, rollout track, attribution, device restart behavior and rollback options.
- [ ] Publish to a **testing-only track** only after explicit owner approval; verify patch on physical Android+iPhone. Do not silently promote to stable/production.

## CI readiness candidate (GitHub commit `6ec5f7a`)

The new `shorebird-ota-readiness` workflow imports the secure `shorebird` environment group, targets Flutter 3.47.9, and contains **no** `triggering`, `publishing`, `shorebird release`, or `shorebird patch` step. It exits unless Codemagic identifies a manual run, the exact isolated source branch, matching `CM_COMMIT`, the real Shorebird app ID, and nonempty `SHOREBIRD_TOKEN` (never echoed). It installs the official CLI and verifies the service-account credential using the read-only `GET https://api.shorebird.dev/api/v1/apps` endpoint (without logging its value), then runs `flutter pub get`, `flutter analyze`, and `flutter test`. The initial CI attempt was blocked before Flutter checks because `shorebird auth status` requested a person-only account route and returned `service_account_forbidden`; this was corrected in isolated commit `2e5e605` and requires a fresh manual CI run for verification.

**Owner-reported status:** After correcting the service-account authentication command, the owner reported a green manual Codemagic readiness build. An exact run ID, commit SHA and full log have not yet been independently reviewed in this report; do not call that run an independently verified PASS. The workflow does not create signed/installed binaries and does not prove OTA viability on a phone.

The first signed Shorebird release, separately reviewed iOS/Android native-shell/signing workflow, matching release/patch toolchains, and testing-track patch remain separately authorized follow-up work.

## Android Shorebird release dry-run candidate (manual, non-publishing)

The isolated draft PR also adds `shorebird-android-dry-run` to `codemagic.yaml`, a one-purpose generated Android shell script at `native/flutter_v1/tool/bootstrap_shorebird_android.sh`, and contract tests at `tests/unit/shorebirdAndroidDryRunWorkflow.test.js`.

- **No triggers, publishing, or distributable artifacts** in the new workflow. Only the owner can select the manual build; it rejects unexpected branch, commit, and missing CI token.
- Reconstructs an ephemeral Android shell via the existing Flutter tooling, using `--org com.fameverse --project-name live` for application ID `com.fameverse.live`; checks the identifier, retains minSdk 24 and the original Fameverse branding law, and fails rather than replacing tracked native files.
- Runs the existing native contract, Dart formatting, Flutter analysis and widget tests *before* Shorebird compilation.
- Uses `shorebird release android --dry-run --flutter-version=3.47.9`. Official Shorebird docs say `--dry-run` builds/checks without uploading a release. No public app update, Shorebird baseline, Google Play distribution, or TestFlight submission is authorized or attempted.
- **Not yet CI verified**: This newly added workflow has not run, nor have its static contract tests been observed passing. A dry-run result is not a signed/store-ready binary. The ephemeral Android shell and eventual production signing must be reconciled with the intended release version, current version code, keystore and package name before a real release.
- The first real `shorebird release` is a separate, explicitly owner-approved operation and will upload release metadata/artifacts to Shorebird; do not add it to this dry-run workflow.
- iOS TestFlight signing, native shell consistency, production Android keystore and real-device OTA tests remain separate approval gates.

## iOS unsigned Shorebird release dry-run candidate (manual, no signing/upload)

The owner elected to prioritize iOS preflight while the Android physical device is unavailable. This does not waive the Android physical acceptance gate.

- New isolated `shorebird-ios-dry-run` workflow in `codemagic.yaml`, with no `triggering`, `publishing`, signing credentials, or exported IPA artifacts. It is restricted to manual Codemagic runs on the reviewed OTA branch with matching `CM_COMMIT` and a nonempty secret `SHOREBIRD_TOKEN`.
- Flutter 3.47.9 and Xcode 26.0 are chosen for the dry-run; Shorebird's current Flutter 3.47.9/Xcode 27 Dart-symbol caveat motivates Xcode 26 for this non-obfuscated preflight. A later signed release must reconcile toolchain, symbols and the approved signing/export setup.
- `tool/bootstrap_shorebird_ios.sh` generates the same ephemeral iOS shell inputs as the existing `native-testflight` bootstrap: `--org com.fameverse --project-name live`, verified `com.fameverse.live` bundle ID, camera and microphone usage strings, the existing iOS icon/dark-launch branding scripts and safety check against overwriting tracked native directories.
- Flutter package resolution, native contract, formatting, static analysis, widget tests and CocoaPods run before the compile check.
- The compile-only command is `shorebird release ios --dry-run --no-codesign --flutter-version=3.47.9`; **dry-run** avoids uploading a Shorebird release, and **no-codesign** avoids generating a signed, distributable IPA.
- Regression file `tests/unit/shorebirdIosDryRunWorkflow.test.js` asserts these constraints; its actual Vitest run and the new Codemagic iOS dry-run have **not yet executed**. Source-level static review is not native build verification.
- Signed Shorebird iOS release for TestFlight is still **OPEN**: first confirm a unique App Store Connect build/version, source identity, Apple distribution provisioning, privacy manifest, physical iPhone acceptance, no unapproved runtime/UI/commerce changes, and owner authorization. The store upload must use the Shorebird-generated release artifact rather than a separate ordinary `flutter build ipa`.
- The existing `native-testflight` workflow remains unchanged and keeps its original release identity/signing gates; none are bypassed.

## iOS signed Shorebird dry-run candidate (manual, no release registration or TestFlight upload)

Owner asked to continue iOS after reporting that the unsigned iOS dry-run was green. This is owner-reported CI status, not independent confirmation of the exact Codemagic run and full logs.

**Purpose:** Check whether the existing manual Apple distribution certificate/profile can export a signed, identity-consistent Shorebird IPA. This job does **not** create a Shorebird baseline release and does **not** publish to TestFlight.

- New `shorebird-ios-signed-dry-run` workflow in `codemagic.yaml`, manually run only on the exact OTA branch/triggering SHA. No automatic triggers or `publishing` block. Uses the existing `manual_signing` group and separate `shorebird` group. App Store Connect API credentials are not loaded.
- Reuses `tool/bootstrap_shorebird_ios.sh` with an additional exact permitted stage `ios-signed-dry-run`. Same ephemeral `com.fameverse.live` iOS platform generation, permissions, branding, and native foundation contract as the iOS unsigned preflight and existing TestFlight workflow.
- New `tool/prepare_shorebird_ios_signing.sh` reuses the existing `CM_CERTIFICATE`, `CM_CERTIFICATE_PASSWORD`, and `CM_PROVISIONING_PROFILE`, rejects wrong/expired/development provisioning profiles and imports signing assets only on the ephemeral Codemagic builder.
- Calls `xcode-project use-profiles --custom-export-options='{"manageAppVersionAndBuildNumber":false}'` and verifies that the generated `/Users/builder/export_options.plist` really has **false**. Xcode must not rewrite the IPA version/build or patch eligibility is lost.
- Pins Flutter 3.47.9, Xcode 26.0, CocoaPods 1.16.2 for this signed dry-run. A real baseline and every subsequent patch must use compatible toolchains and the same native shell / Dart defines.
- After format/analyze/tests/Pods, runs `shorebird release ios --dry-run --flutter-version=3.47.9 --build-number="$BUILD_NUMBER" --dart-define="FAMEVERSE_BUILD_FAMILY=47" --dart-define="FAMEVERSE_SOURCE_SHA=$CM_COMMIT" --export-options-plist=/Users/builder/export_options.plist`. This retains the **current TestFlight Build 47 Dart runtime define** deliberately; changing the feature flag to 48 is a separate release decision and not authorized here.
- If an IPA is produced, extracts its bundle identifier and build number and compares with `com.fameverse.live` and Codemagic's `BUILD_NUMBER`. The signed IPA and a non-secret source identity receipt become Codemagic artifacts; **artifact retention is not Apple publication**.
- New `tests/unit/shorebirdIosSignedDryRunWorkflow.test.js` is a regression-contract candidate. **Neither its Vitest run nor this signed Codemagic workflow has yet executed**; the source-level review is not a successful signed build.

**Before any actual OTA-enabled iOS release:** Query actual App Store Connect build/version occupancy, select a unique build number, review and approve exact source commit and native shell, confirm store/export identity & app/privacy requirements, obtain explicit owner authorization to run real `shorebird release ios` (which registers a baseline), explicitly authorize uploading **that same Shorebird-built IPA** to TestFlight, install on physical iPhone and validate Live/co-host/gifts/policies/performance. The existing automatic-publishing `native-testflight` workflow must remain separate; never substitute its ordinary `flutter build ipa` artifact for a Shorebird-enabled baseline.

## Stop conditions

- Missing real Shorebird app registration or CI credentials.
- Source/branch mismatch, unknown release identity, or a mismatch with existing Codemagic platform shell generation.
- Native dependency/asset changes or patch rejected by the Shorebird compatibility checks.
- Failing formatting/analyze/unit/widget/native CI, or no physical-device acceptance where required.
- A requested update requires store review or would violate store policies.
- Unapproved Live UI, gift, economy, rank, policy or server changes.

## Status vocabulary

- **OPEN:** work planned, no verified implementation.
- **FIX_CANDIDATE:** configuration/release work exists with recorded tests; device and owner gates outstanding.
- **LOCKED:** relevant regression protection, real-device Android/iPhone acceptance and owner acceptance documented.
- **REOPENED:** later evidence contradicts accepted behavior.

## Authoritative implementation references

- Initialization: https://docs.shorebird.dev/code-push/initialize/
- Codemagic: https://docs.shorebird.dev/code-push/ci/codemagic/
- CI toolchain and dry-run guidance: https://docs.shorebird.dev/code-push/ci/generic/
- iOS binary requirements: https://docs.shorebird.dev/guides/submitting/app-store/
- Patch restrictions: https://docs.shorebird.dev/code-push/patch/
