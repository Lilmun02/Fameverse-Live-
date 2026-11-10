# Build 47 — release candidate gate (review only)

**Date:** 2026-11-10. **Owner approval is required for each merge, production database migration, Codemagic workflow change, signing/upload, and external distribution separately.** This document neither authorizes nor executes those actions.

## Exact source status

- Staged Build 47 candidate: PR #101, branch `build47/backend-utc-rankings-nov05`; stays DRAFT. Source revisions now include Top 100, regression tests, and the owner-approved existing Codemagic workflow metadata repair.
- Native baseline: `build47/native-safe-review-nov04`; separate policy schema draft: `build47/policy-acceptance-gate-nov05`.
- Native Fameboard display now calls legacy parameter values `24h`/`7d` but labels them Daily/Weekly, awaiting the paired UTC migration.
- Rankings preserved without owner-invented category remapping: Supporters = legitimate cash-backed gift sends, Pulse = eligible Fametaps, Creators = eligible host Fametaps (followers secondary).
- All shopping/purchase/Stripe checkout-session/webhook integrations are **frozen** and out of scope.

## Verification completed so far

- SELECT-only Supabase UTC boundary check: 5/5 passed, including Sunday 00:00 UTC, Monday, US daylight-saving change, year rollover.
- Vercel preview build: READY for rank/native-label commits (web quality only; it does NOT run Flutter, iOS signing or TestFlight).
- Regression checks: native Flutter source contract, cross-backend ranking Vitest contracts, and existing TestFlight workflow Vitest contracts committed. Static source checks passed; the latest Vercel preview status is SUCCESS, but this is **not** evidence of Flutter runtime execution, signed iOS build or device acceptance.

## Release blockers / QA to clear

1. **TestFlight Build 47 workflow metadata repaired; native CI unrun.** Owner-approved `codemagic.yaml` change keeps the existing native-testflight signing, bundle ID `com.fameverse.live`, App Store Connect publishing and source-SHA gate, sets `FAMEVERSE_BUILD_FAMILY: "47"`, includes `--dart-define="FAMEVERSE_BUILD_FAMILY=47"`, emits `build47_source_identity.txt`, and adds source-only checks for Top 100 and UTC labels. The pre-existing payment/payout source guard lines remain unchanged. **No Codemagic/TestFlight run was started** and no signed IPA receipt has been verified. A manual build/upload requires separate CEO authorization.
2. **Native N1/N2/N3 not yet verified for this exact source.** Run existing Flutter format, analyzer, all Flutter tests, native contract checker, unsigned iOS + Android preflights on the exact candidate commit; fix failures on an isolated branch and add regression locks. No workstation/CI native test evidence yet.
3. **Database N4 pending.** `get_fameverse_rankings_v2` production still uses rolling windows; PR #101 SQL is unapplied. Use an approved isolated database to verify real authenticated RPC and permissions, QA-exclusion/duplicate gift behavior and edge boundaries. Then request separate approval to apply exact migration before a native build displaying Daily/Weekly ships.
4. **Policy release N4 pending.** `policy_acceptances` is staged on a separate branch but not integrated or deployed; native policy screen currently displays terms rather than a server-backed acceptance/decline gate. Do not claim restricted feature enforcement until the backend and native tests demonstrate it. Do **not** modify checkout/purchases while resolving policy behavior.
5. **Native N5 physical acceptance pending.** Test host/viewer video and mic, co-host audio cleanup on two devices, 5x gift combos across distinct gifts, exact-once animation/audio, swipe/feed performance, profiles/chat, policy restrictions and camera flips. Document exact iPhone(s), commit and build. Existing `docs/PHYSICAL_ACCEPTANCE.json` has co-host checks pending; do not mark passed without real receipts.
6. **Release N6/N7 pending.** Unique Build 47 number, signed IPA, upload to existing TestFlight, Apple processing/review, regression hold and rollback build must be verified. No claim of App Store availability until Apple confirms it.

## Approval Disclosure Gate

Before requesting approval, provide:
- the **exact action** (e.g. edit `codemagic.yaml`, apply UTC migration, merge PR, upload IPA, invite external testers);
- commit SHA, branch, affected files, observable user changes, preserved purchase/checkout scope;
- tests passed/failed/not run, bug ancestry, remaining risks and rollback path;
- exactly what **YES** would authorize; each subsequent action needs separate authorization.

**Current approval state:** Owner approved the scoped existing Codemagic workflow preparation only. No authorization or completion evidence for a Codemagic build/upload, database migration, PR merge, TestFlight external distribution or production rollout. PR #101 remains DRAFT and nothing here changes production. Codex engineering on PR #112 is independent of native Build 47.
