# Abyssal Leviathan Premium Gift Contract

Status: owner-approved integration target; implementation is not accepted until the checks below pass.

This contract is subordinate to `docs/ENGINEERING_CONSTITUTION.md`, `docs/CURRENT_NATIVE_STABILIZATION_SCOPE.md`, `docs/SEP27_BIG_UPDATE_CONTRACT.md`, and root `AGENTS.md`.

## Approved asset
The owner-approved candidate asset is the vertical premium cinematic titled **Abyssal Leviathan**.

Reference properties from the supplied preview:
- intended visible price: **5,000 Fame Coins**;
- vertical cinematic video;
- approximately 15 seconds;
- H.264 video with AAC audio;
- the current Build 32 cinematic player must keep embedded audio muted until the owner explicitly approves replacement/production audio.

Do not replace the owner-approved art/video with a different concept without approval.

## Canonical gift identity
Use exactly one canonical gift identity across client, backend catalog, tests and analytics:
- id: `abyssal-leviathan`
- label: `Abyssal Leviathan`
- cost: `5000` Fame Coins
- category: `fameverse`
- cinematic: `true`

Do not create aliases, duplicate IDs, test-only clones, or a second 5,000-coin Leviathan entry.

## Media hosting
The cinematic must use one stable production-appropriate HTTPS URL from an approved media host (Supabase Storage/public CDN or another already-approved Fameverse media host).

Do not:
- point production code at a local file path;
- use a temporary chat attachment URL;
- use an expiring preview URL;
- embed base64 video in Dart/SQL;
- silently swap to another asset if upload fails.

If a stable URL is not available, stop and report the gift as not integrated.

## Client wiring
The Flutter gift catalog must contain an `FvGiftDefinition` for `abyssal-leviathan` with the exact identity above and the stable HTTPS `videoUrl`.

The gift must use the existing cinematic playback pipeline. Do not create a second parallel player just for this gift unless a proven platform bug requires it and the owner approves that architectural change.

Required behavior:
- tray shows the correct name and 5,000-coin price;
- send path uses the existing authoritative gift transaction flow;
- video starts from frame zero on every playback;
- playback finishes and releases/advances the queue;
- failure to load video falls back cleanly and cannot leave a black/stuck overlay;
- rapid sends and back-to-back different gifts cannot display stale Leviathan frames;
- gift playback must not stop/disable the Live camera or microphone;
- gift playback must not duplicate the chat gift event;
- embedded cinematic audio remains muted in Build 32 (`setVolume(0)`) until the owner explicitly approves audio.

## Backend catalog authority
The authoritative backend gift catalog must contain the same exact gift identity and price.

Repository and deployed backend must not intentionally drift. Any catalog data change must have a repo-tracked migration/upsert or equivalent reproducible source change before it is called complete.

Do not alter schema solely to add this gift if the existing `fameverse_gift_catalog` structure already supports it.

## Economy / payout law
Abyssal Leviathan must NOT contain custom payout math.

It must use the existing authoritative funding-source and creator-earnings pipeline:
- cash-backed purchased Fame Coins follow the existing configured creator/platform split;
- promotional/referral/test/owner-QA funding remains distinguishable and must not create ordinary payable creator earnings;
- QA/test sends must not create payout liability, verification progress, or legitimate ranking credit;
- no client-side calculation may be treated as authoritative money state;
- no self-gift or replay path may bypass backend controls.

The 5,000-coin face price must not be hardcoded as a cash payout amount in UI or gift code.

## Regression requirements
Before acceptance, add/strengthen tests that prove at minimum:
1. `fvGiftById('abyssal-leviathan')` exists.
2. Its cost is exactly `5000`.
3. It is cinematic and has an HTTPS media URL.
4. `Pocket Comet` remains retired/absent from active gift behavior.
5. Cinematic playback remains muted for Build 32.
6. Playback completion cannot deadlock the gift queue.
7. Existing gift combo/queue regression tests still pass.
8. No existing gift ID is duplicated or replaced.
9. Backend catalog identity/price matches the Flutter catalog.

Do not weaken a valid existing regression law just to make this gift pass.

## Required automated gates
Run the Fameverse Build 32 workflow after integration:
- formatting/static analysis;
- unit/widget tests;
- gift regression contracts;
- iOS compile;
- Android compile.

Green automation only makes this a `FIX_CANDIDATE`/integration candidate where physical-device behavior is involved.

## Physical QA required
On the exact signed build/commit, verify at minimum:
- single Abyssal Leviathan send;
- repeated Abyssal Leviathan sends;
- 5x/10x combo or existing supported combo behavior;
- Leviathan followed immediately by another cinematic gift;
- another cinematic gift followed immediately by Leviathan;
- tray close/reopen and resend;
- camera flip and camera off/on during playback;
- background/foreground recovery;
- host receives the gift exactly once;
- second viewer/sender path if available;
- no black frame;
- no stale previous gift;
- no flicker/stuck overlay;
- no duplicate chat event;
- no camera shutdown;
- no audible robotic/embedded cinematic audio in Build 32.

## Scope boundary
This task is ONLY the Abyssal Leviathan gift integration and the minimum regression work required to make it safe.

Do not redesign rankings, payout screens, profile, Live layout, verification UI, gift tray architecture, or other gifts as part of this task.

If the implementation cannot satisfy this contract without touching unrelated systems, stop and report the dependency instead of making broad changes.

## Completion report
When done, report:
- exact branch and SHA;
- stable media URL used;
- files changed;
- backend catalog/migration change;
- tests added/updated;
- automated gate results;
- remaining physical QA;
- release state (`OPEN`, `FIX_CANDIDATE`, `LOCKED`, or `REOPENED`).

Do not call the gift complete, fixed, working, or locked before the evidence supports that claim.
