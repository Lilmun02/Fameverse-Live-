# Fameverse Live — Live Stability QA Candidate (October 15, 2026)

**State: SOURCE INTEGRATION CANDIDATE / NOT YET TESTFLIGHT-READY.**
**Branch:** `release-candidate/live-stability-oct15-qa`
**Base:** `integration/sep27-big-update` at `7bbe68c933d96d1e303b32521ac18bbad27d2d81`.
**Goal:** A small, auditable native stabilization update, no feature rollout. This branch is not the production/TestFlight source until the owner explicitly approves the source-selection and release process.

## Included and traceable repairs

| Repair | Source PR | Integrated exact paths | Evidence / remaining gates |
| --- | --- | --- | --- |
| Serialize host and cohost camera power changes with camera flip lock | [#48](https://github.com/Lilmun02/Fameverse-Live-/pull/48), source `680f64bccb72195744cbcdf528ee063f3e250653` | `native/flutter_v1/lib/features/live/stream_host_live_screen.dart`; `native/flutter_v1/lib/features/live/stream_viewer_live_screen.dart`; `native/flutter_v1/test/camera_operation_serialization_contract_test.dart` | Source PR's quality, iOS and Android preflight passed. Still requires repeated host/cohost flips and on/off during active Live on physical devices. |
| Correct approved two-square cohost gap from 8 to 2 pixels | [#51](https://github.com/Lilmun02/Fameverse-Live-/pull/51), source `d1e2b54a165c5a435ce964f54d494c23c1219ed5` | `native/flutter_v1/lib/features/live/native_live_stage.dart`; `native/flutter_v1/test/cohost_box_geometry_lock_test.dart` | Source PR's quality, iOS and Android preflight passed. Physical host + cohost layout must still be inspected. |
| Refresh active broadcasts independently on Home/Discover every 20 seconds when visible, with one request in flight | [#52](https://github.com/Lilmun02/Fameverse-Live-/pull/52), source `641b8d697978a1ef2928b9f38f55222dd59390d3` | `native/flutter_v1/lib/features/shell/fameverse_shell_build23.dart`; `native/flutter_v1/test/live_discovery_refresh_contract_test.dart` | Source PR's quality, iOS and Android preflight passed. Two-device join, room availability, tab changes and disconnect/expiry remain device QA. |

**Integration method:** copied exactly the seven files from their individual tested branches into this new branch after verifying each matches the corresponding seven files on the older QA combination PR #59. Did **not** merge whole PR #59 because it includes a Codemagic/TestFlight source-lock change plus an associated native-contract change not authorized for this integration. New branch preserves canonical `codemagic.yaml` and `native/flutter_v1/tool/check_native_contract.dart`.

## Explicitly excluded

- PR #85: large draft Live/Home/Inbox surface changes, owner-disputed combo edits and unresolved video/audio/swipe/financial issues. No #85 files or audit comments pulled in.
- PR #81: private Inbox implementation needs missing reviewed backend tables/RLS and privacy testing. Disabled/unmerged.
- PR #77/#78: lightweight-gift and duplicate-gift-audio candidates contain separate workflow changes in their PR diffs; investigate/validate as separately isolated follow-on inputs, including physical owner confirmation of the 100-coin doubled-audio repro before labeling fixed.
- PR #49: fixed-UTC Fameboard reset is still unverified pending approved database migration and staging/device QA.
- PR #80: password reset needs authorized site URL/redirect setup and device verification.
- Manus `refactor/system-boundaries`: reported camera keyboard and simple gift improvements were uncommitted locally as of last read-only GitHub inspection; not included.
- Apple repeated IAP failure #65, web Stripe purchase caller/checkout #66, creator payout CTA #67: unresolved money-path blockers. **Do not advertise or launch payments as fixed**, reconfigure provider, or run real transactions without explicit separate owner review.

## Release gates and honest status

1. New candidate must run clean format/analyze/unit-widget/contract and Android/iOS build CI on the **exact final source SHA**; prior component-level CI does not substitute for integrated CI.
2. Physical iPhone and a separate non-owner viewer/cohost test must confirm camera flip spam, mic/video stability, chat/gift nonregression, active-room discovery and stream uptime. Capture exact candidate SHA/build and failures.
3. This integration is a **source-only QA branch**. Canonical `native-testflight` currently hard-checkouts `integration/sep27-big-update`, so triggering it on this branch would build different code. An exact-source TestFlight plan must be **separately reviewed and expressly authorized by the owner**, with no unauthorized workflow rewrite, no install link, and no implicit canonical merge.
4. Only after the owner approves candidate composition and source wiring, verified signing, uploaded TestFlight IPA and internal device acceptance may anyone call a named build available; external distribution requires separate owner signoff.
5. If a regression is found, revert only the affected isolated candidate on the QA branch; protect known-good internal TestFlight and integration.

## Audit

**No release, CI rerun, workflow rewrite, production backend mutation, payment/payout operation or TestFlight upload has been performed as part of this integration record.** The resulting branch commit SHA and current CI statuses must be cited in the review PR; never assume an automatically running check is green.
