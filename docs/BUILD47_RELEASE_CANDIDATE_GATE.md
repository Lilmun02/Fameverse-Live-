# Build 47 — release candidate gate (review only)

**Updated:** 2026-11-11. **Owner approval is required for each merge, production database migration, Codemagic workflow change, signing/upload, and external distribution separately.** This document neither authorizes nor executes those actions.

## Exact source status

- Staged Build 47 candidate: PR #101, branch `build47/backend-utc-rankings-nov05`; stays DRAFT. Source revisions now include Top 100, regression tests, and the owner-approved existing Codemagic workflow metadata repair.
- Native baseline: `build47/native-safe-review-nov04`; the existing staged policy acceptance service, RLS migration draft, and permission tests were copied from `build47/policy-acceptance-gate-nov05` into PR #101 for the Build 47 review.
- Native Fameboard display now calls legacy parameter values `24h`/`7d` but labels them Daily/Weekly, awaiting the paired UTC migration.
- Native host End Live button and hardware/system back route now require an affirmative confirmation dialog; unconfirmed exits retain the live session. Static Flutter regression assertions and existing Codemagic source guard are committed, but no device test has run.
- Rankings preserved without owner-invented category remapping: Supporters = legitimate cash-backed gift sends, Pulse = eligible Fametaps, Creators = eligible host Fametaps (followers secondary).
- Owner First Verse Settings and entry are hidden; non-owners retain their progress only while beta enrolled and policy accepted. On 2026-11-11 the sole `verse_pioneer` award was removed from `@dj_sosoboyzz` by an account-specific, single-row production database action, and a follow-up read verified zero remaining Pioneer records. No native Pioneer badge rendering code was deleted.
- All shopping/purchase/Stripe checkout-session/webhook integrations are **frozen** and out of scope.

## Verification completed so far

- SELECT-only Supabase UTC boundary check: 5/5 passed, including Sunday 00:00 UTC, Monday, US daylight-saving change, year rollover.
- Vercel preview build: READY for rank/native-label commits (web quality only; it does NOT run Flutter, iOS signing or TestFlight).
- Regression checks: Flutter source contracts and new policy decision/widget tests are committed, but Flutter tests are **not executed**. Latest authenticated Vercel build logs at `0ea736d` confirm Build 47 rankings Vitest (6 tests), TestFlight workflow Vitest (5 tests), and policy update Vitest (5 tests) passed. This is web/JavaScript quality only, not Flutter, iOS signing or device acceptance.

## Release blockers / QA to clear

1. **TestFlight Build 47 workflow metadata repaired; native CI unrun.** Owner-approved `codemagic.yaml` change keeps the existing native-testflight signing, bundle ID `com.fameverse.live`, App Store Connect publishing and source-SHA gate, sets `FAMEVERSE_BUILD_FAMILY: "47"`, includes `--dart-define="FAMEVERSE_BUILD_FAMILY=47"`, emits `build47_source_identity.txt`, and adds source-only checks for Top 100 and UTC labels. The pre-existing payment/payout source guard lines remain unchanged. **No Codemagic/TestFlight run was started** and no signed IPA receipt has been verified. A manual build/upload requires separate CEO authorization.
2. **Native N1/N2/N3 not yet verified for this exact source.** Run existing Flutter format, analyzer, all Flutter tests, native contract checker, unsigned iOS + Android preflights on the exact candidate commit; fix failures on an isolated branch and add regression locks. No workstation/CI native test evidence yet.
3. **Database N4 pending.** `get_fameverse_rankings_v2` production still uses rolling windows; PR #101 SQL is unapplied. Use an approved isolated database to verify real authenticated RPC and permissions, QA-exclusion/duplicate gift behavior and edge boundaries. Then request separate approval to apply exact migration before a native build displaying Daily/Weekly ships.
4. **Policy release N4 pending; CRITICAL FOR THIS UPDATE.** Build 47 now includes an authenticated account-bound policy service, staged RLS/acceptance SQL, a policy checkbox/Accept/Decline screen shown after the startup update notice, restricted browsing and native Live/First Verse entry gates. The production `policy_acceptances` table is **ABSENT** as of the last read-only SQL check. Therefore acceptance/decline CANNOT save in production yet, and unsigned users attempting Build 47 would enter restricted mode. Full coin-purchase and sensitive backend enforcement are also **not verified/complete**; the existing Stripe/Apple checkout code is deliberately unchanged. Do not claim policy functional or distribute until the exact schema, final legal terms, server-side checks and native device tests are approved and verified.
5. **Native N5 physical acceptance pending.** Test host/viewer video and mic, co-host audio cleanup on two devices, 5x gift combos across distinct gifts, exact-once animation/audio, swipe/feed performance, profiles/chat, policy restrictions and camera flips. Document exact iPhone(s), commit and build. Existing `docs/PHYSICAL_ACCEPTANCE.json` has co-host checks pending; do not mark passed without real receipts.
6. **Release N6/N7 pending.** Unique Build 47 number, signed IPA, upload to existing TestFlight, Apple processing/review, regression hold and rollback build must be verified. No claim of App Store availability until Apple confirms it.

## Approval Disclosure Gate

Before requesting approval, provide:
- the **exact action** (e.g. edit `codemagic.yaml`, apply UTC migration, merge PR, upload IPA, invite external testers);
- commit SHA, branch, affected files, observable user changes, preserved purchase/checkout scope;
- tests passed/failed/not run, bug ancestry, remaining risks and rollback path;
- exactly what **YES** would authorize; each subsequent action needs separate authorization.

**Current approval state:** Owner authorized the targeted owner First Verse repair, removal of the specific Pioneer award, and Build 47 policy startup preparation. The Pioneer database award removal is complete and verified. **No policy or rankings schema migration was applied.** No merge, signed IPA, TestFlight upload, external distribution, or production rollout is verified; PR #101 remains DRAFT. Codex's web Owner Command Center PR #112 is independent of native Build 47.
