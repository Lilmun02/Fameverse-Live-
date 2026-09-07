# Fameverse Bugs

This file is the single bug registry for Fameverse. Bugs are never deleted from history. A bug may be closed, locked, or reopened, but its ID and record remain here so recurrence can be measured over time.

## Bug Spray Law

**VERIFY → TRACE → SPRAY → LOCK ’EM UP FOREVER.**

1. **VERIFY** — reproduce the actual failure. Screenshots, recordings, logs, physical-device behavior, and backend evidence outrank guesses.
2. **TRACE** — identify the controlling code/backend path and the root cause. If an older historical bug predates this registry and the root cause was not preserved, mark it `LEGACY_RECHECK`; do not invent one.
3. **SPRAY** — fix the specific cause with the smallest safe scope.
4. **LOCK** — add a regression check where practical, run the Engineering Gate, then obtain physical acceptance whenever device/media/realtime/payment behavior is involved.

A green regression check is not a promise that a bug can never return. If it breaks loose, change the same bug to `REOPENED`, increment its reopen count, record the new trigger/root cause, and strengthen the lock. Do not create a duplicate ID for the same defect family.

## Status definitions

- `OPEN` — verified and not yet repaired.
- `FIX_CANDIDATE` — code/backend repair exists; automated and/or physical acceptance is still pending.
- `LOCKED` — repair passed the required acceptance path and has a regression lock where practical.
- `REOPENED` — previously locked bug reproduced again.
- `LEGACY_RECHECK` — historical verified bug from before this registry; current status/root cause requires a fresh physical reproduction before any new claim.

## Live statistics

- Total tracked: **7**
- Open: **1**
- Fix candidates: **0**
- Locked: **4**
- Reopened: **0**
- Legacy recheck: **2**
- Reopens recorded since registry start: **0**

## Registry

| ID | Status | Severity | Area | Bug | First verified | Fix / candidate SHA | Regression lock | Physical acceptance | Reopens |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: |
| FVB-001 | LEGACY_RECHECK | Critical | Live media | Camera could shut off while repeatedly flipping cameras. | 2026-08-25 | — | Media/camera checks exist, but legacy root cause was not preserved. | Fresh retest required before declaring current state. | 0 |
| FVB-002 | LEGACY_RECHECK | Critical | Startup/PWA | App could transition through black/white screens or lose the intended splash/startup behavior. | 2026-08-25 | — | Startup/device-truth checks now exist, but the historical root cause was not preserved in this registry. | Fresh installed-device retest required before declaring current state. | 0 |
| FVB-003 | LOCKED | High | Gifts / iPhone media | 100-coin Welcome gift could play without its original audio on iPhone. | 2026-09-07 | `8c70ba4b2768e70ea8376617fce03ff521857b9c` | Premium media is prepared on the send gesture and reused; gift backend/media laws guard the path. | PASS — original audio physically accepted on iPhone. | 0 |
| FVB-004 | LOCKED | Medium | Gift tray | Welcome gift thumbnail depended on Safari video seeking and could render a blurry/fallback preview. | 2026-09-07 | `274c9a5a…` | Gift tray law forbids video-seek thumbnails and requires the static poster path. | PASS as part of the accepted Gifting V1 tray candidate. | 0 |
| FVB-005 | LOCKED | High | Gifts / identity | Tapping a sent gift/gifter bubble had no effect. | 2026-09-07 | `812696a77e15643a97a411028e0ba321948b12a5` | Live UX law requires gifter bubble tap → sender in-Live profile and forbids exposing gift type. | PASS — user physically accepted bubble/profile interaction. | 0 |
| FVB-006 | LOCKED | Low | Live profile | Host/self in-Live profile displayed FameTaps even though the host does not want that metric shown by default. | 2026-09-07 | `6ccd93357f915e9e99879d6f75244a66cce67e95` | Live profile law requires self profile to hide FameTaps while preserving Gifts Sent. | PASS — owner approved the final self-profile contract. | 0 |
| FVB-007 | OPEN | High | Main profile / gifter identity | Main profile is visually dry and does not expose the approved gifter level, tier progression, next unlock requirements, or locked/blurred future badges; privileged Owner/Admin identity also suppresses the earned gifter badge presentation. | 2026-09-07 | — | Approved profile preview will be implemented with gifter progression + profile regression laws. | Pending implementation and phone QA. | 0 |

## FVB-007 trace record

**VERIFY**  
The main Profile screen was physically shown without the approved gifter progression UI, level/tier path, unlock requirements, or future locked badges.

**TRACE**  
`ProfileScreen.jsx` already loads real `gifter_stats`, and the gifter progression/tiers already exist. `ProfileView.jsx` only renders a small earned badge when coins were sent and suppresses that badge for privileged roles; it does not mount the progression/tier gallery on the real profile. The badge gallery currently exists as a separate visual-QA component instead of the main profile experience.

**SPRAY**  
Pending approved implementation: wire the real main Profile to the existing server-backed gifter stats and exact level curve; show current level/tier, lifetime gift coins, progress to next level, and all nine locked tiers with unearned artwork blurred. Owner/Admin keeps role identity while still seeing personal gifter progression.

**LOCK**  
Pending: profile regression law + Engineering Gate + exact-SHA Vercel preview + physical phone acceptance.

## Reporting rule

Every future bug report must answer these fields in this file before it is called fixed:

- What failed?
- Where did it fail?
- How was it reproduced?
- What was the root cause?
- What exact SHA/backend migration repaired it?
- What regression lock protects it?
- What physical acceptance was required and who passed it?
- How many times has the same bug been reopened?
