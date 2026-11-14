# Fameverse AI Agent Instructions

These instructions apply to Codex and any other AI-assisted developer working in this repository. They are release law, not optional guidance.

## Read this first
Before inspecting, editing, or claiming anything about Fameverse, read these authoritative files in this order:

1. `docs/ENGINEERING_CONSTITUTION.md`
2. `docs/CURRENT_NATIVE_STABILIZATION_SCOPE.md`
3. `docs/SEP27_BIG_UPDATE_CONTRACT.md`

If a narrower active contract exists for the subsystem you are touching, read it too. Explicit owner approval/rejection and physical-device behavior outrank assumptions.

## Canonical source
- Canonical branch: `integration/sep27-big-update`.
- Do not work from `main` or another branch for Build 32 unless the owner explicitly authorizes a branch migration.
- Resolve and report the exact branch HEAD SHA before making changes and again before any release/build instruction.
- Do not overwrite unrelated work. One developer/agent owns one file/task at a time.

## Current mission: Build 32 stabilization / bug audit
The immediate job is to find and repair real regressions in the approved Build 32 candidate. Do not claim there are "no bugs" simply because CI is green. Prove what can be proved and identify what still requires physical QA.

Audit the currently approved repair areas, especially:
- Live gifting placement, gift tray behavior, rendering, playback completion, queue/combo behavior, and audio behavior.
- No black frame, stale previous gift, flicker, stuck playback, duplicate gift chat event, or camera shutdown caused by gift playback.
- Live host/viewer/co-host camera and media parity, including rapid flip abuse and camera off/on.
- Fameboard/rankings wiring in Live and Discover without silently redesigning approved UI.
- Creator payout request/review/provider flow, PayPal sandbox processing/sync, replay protection, and ledger correctness.
- Verification moderation/review state so a real pending application can be reviewed authoritatively.
- Startup/launch regressions, sticky keyboard regressions, profile/settings regressions, and owner-only control privacy.
- Same-build host/viewer/co-host behavior.

## Gift ownership boundary
- Gift artwork, animation, video, audio, timing, transitions, names, and intended presentation belong to the owner-approved asset/source. Do not redesign, mute, re-encode, resize, rename, replace, or otherwise alter a gift's creative presentation unless the owner explicitly instructs that change.
- System-level gift bug repairs may be made only when they preserve the owner-approved asset and intended presentation exactly as delivered.
- If the app cannot safely support an owner-approved gift as delivered, report the exact incompatibility instead of silently changing the gift.
- Do not inspect or modify another agent's in-progress gift implementation unless the owner asks for that specific review or repair.
- `Pocket Comet` remains retired because the owner explicitly removed it.

## Required bug workflow
For every bug, follow the Fameverse law:

`VERIFY -> TRACE -> smallest isolated PATCH -> TEST -> REGRESSION LOCK -> BUG SPRAY -> DEVICE TEST -> PASS`

Concretely:
1. Reproduce/verify the failure and identify the exact source/build/device context.
2. Trace the root cause before editing.
3. Make the smallest repair that preserves working systems.
4. Add or strengthen a regression guard for the repaired failure.
5. Run formatting/static analysis, relevant unit/widget tests, regression contracts, Android build, and iOS build as applicable.
6. Do not weaken, delete, or rewrite a valid law merely to make CI green. If a test is stale because an owner-approved requirement changed, explain exactly why before updating that stale contract.
7. Physical-device-sensitive behavior remains `FIX_CANDIDATE` until owner-device QA passes. External-tester acceptance is separate.

## Money / payout / gift accounting law
- Backend authority is mandatory for money, gifts, balances, roles, permissions, verification state, and payouts.
- Test/QA gifts must never create ordinary creator payable earnings, payout liabilities, verification progress, or real ranking credit.
- Promotional/test funding and real cash-backed funding must remain distinguishable in backend accounting.
- Never mark a payout production-ready from UI-only evidence.
- PayPal stays in sandbox until end-to-end fake-money proof passes.
- Payout replay/double-pay protection and ledger auditability are release blockers.

## No fake completion
Never say `fixed`, `working`, `stable`, `locked`, `release-ready`, `production-ready`, or `no bugs` unless the exact evidence supports that exact claim.

Use the repository bug states:
- `OPEN`
- `FIX_CANDIDATE`
- `LOCKED`
- `REOPENED`

A source repair plus green automated checks is normally `FIX_CANDIDATE`, not `LOCKED`, when physical QA is required.

## Output expected from Codex
When the audit is complete, report:
- exact branch + SHA inspected;
- bugs found, with root cause and affected files;
- exact files changed;
- regression tests/laws added or updated;
- automated gates run and their results;
- anything still requiring owner iPhone QA or an external tester;
- rollback path if a repair regresses something;
- release state for each repaired issue (`OPEN`, `FIX_CANDIDATE`, `LOCKED`, or `REOPENED`).

If you cannot prove something, say it is unverified. Do not guess and do not hide failures.
