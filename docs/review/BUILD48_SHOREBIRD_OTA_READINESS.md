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

The new `shorebird-ota-readiness` workflow imports the secure `shorebird` environment group, targets Flutter 3.47.9, and contains **no** `triggering`, `publishing`, `shorebird release`, or `shorebird patch` step. It exits unless Codemagic identifies a manual run, the exact isolated source branch, matching `CM_COMMIT`, the real Shorebird app ID, and nonempty `SHOREBIRD_TOKEN` (never echoed). It installs the official CLI and attempts `shorebird auth status`, `flutter pub get`, `flutter analyze`, and `flutter test`.

**Verification pending:** The workflow has not been executed in Codemagic. A manual preflight run may expose existing Flutter test failures or CI environment differences; do not label it PASS until exact Codemagic output is reviewed. This check does not create signed/installed binaries and does not prove OTA viability on a phone.

The first signed Shorebird release, separately reviewed iOS/Android native-shell/signing workflow, matching release/patch toolchains, and testing-track patch remain separately authorized follow-up work.

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
