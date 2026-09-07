# Fameverse Bugs

This file is the single bug registry for Fameverse. Bugs are never deleted from history. A bug may be closed, locked, or reopened, but its ID and record remain here so recurrence can be measured over time.

## Bug Spray Law

**VERIFY → TRACE → SPRAY → LOCK ’EM UP FOREVER.**

1. **VERIFY** — reproduce the actual failure. Screenshots, recordings, logs, physical-device behavior, and backend evidence outrank guesses.
2. **TRACE** — identify the controlling code/backend path and the root cause. If an older historical bug predates this registry and the root cause was not preserved, mark it `LEGACY_RECHECK`; do not invent one.
3. **SPRAY** — fix the specific cause with the smallest safe scope.
4. **LOCK** — add a regression check where practical, run the Engineering Gate, then obtain physical acceptance whenever device/media/realtime/payment behavior is involved.

A green regression check is not a promise that a bug can never return. If it breaks loose, change the same bug to `REOPENED`, increment its reopen count, record the new trigger/root cause, and strengthen the lock. Do not create a duplicate ID for the same defect family.

## Tracer Watch Law

The dev tracing a verified bug must keep an open eye on the bug's immediate dependency, state, backend, media, and UI path for the **same failure pattern**.

- Confirmed nearby defects receive their own Fameverse Bug ID.
- A suspicious risk that has not been reproduced is documented as a risk, not falsely promoted to a bug.
- The tracer may strengthen a shared regression guard when multiple confirmed bugs have the same root-cause pattern.
- Tracing one bug is not permission to refactor unrelated systems or expand scope.

This law exists to catch bug cousins while the responsible system is already under inspection without creating imaginary repairs.

## Status definitions

- `OPEN` — verified and not yet repaired.
- `FIX_CANDIDATE` — code/backend repair exists; automated and/or physical acceptance is still pending.
- `LOCKED` — repair passed the required acceptance path and has a regression lock where practical.
- `REOPENED` — previously locked bug reproduced again and does not yet have a new fix candidate.
- `LEGACY_RECHECK` — historical verified bug from before this registry; current status/root cause requires a fresh physical reproduction before any new claim.

## Live statistics

- Total tracked: **9**
- Open: **0**
- Fix candidates: **1**
- Locked: **6**
- Reopened right now: **0**
- Legacy recheck: **2**
- Reopens recorded since registry start: **1**

## Registry

| ID | Status | Severity | Area | Bug | First verified | Fix / candidate SHA | Regression lock | Physical acceptance | Reopens |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: |
| FVB-001 | LEGACY_RECHECK | Critical | Live media | Camera could shut off while repeatedly flipping cameras. | 2026-08-25 | — | Media/camera checks exist, but legacy root cause was not preserved. | Fresh retest required before declaring current state. | 0 |
| FVB-002 | LEGACY_RECHECK | Critical | Startup/PWA | App could transition through black/white screens or lose the intended splash/startup behavior. | 2026-08-25 | — | Startup/device-truth checks now exist, but the historical root cause was not preserved in this registry. | Fresh installed-device retest required before declaring current state. | 0 |
| FVB-003 | LOCKED | High | Gifts / iPhone media | 100-coin Welcome gift could play without its original audio on iPhone. | 2026-09-07 | `8c70ba4b2768e70ea8376617fce03ff521857b9c` | Premium media is prepared on the send gesture and reused; gift backend/media laws guard the path. | PASS — original audio physically accepted on iPhone. | 0 |
| FVB-004 | LOCKED | Medium | Gift tray | Welcome gift thumbnail could briefly render Safari's broken-image placeholder before the real static poster appeared. This was a recurrence of the prior thumbnail defect family. | 2026-09-07 | `d0fb59428b5430f67bce773554022d6cc9e60895` | Static poster remains mandatory; poster media preloads early, failed pixels stay hidden until `load`, retries are bounded, and the gift-tray resilience law guards the path. | PASS — repeated iPhone tray test showed no broken icon/flicker. | 1 |
| FVB-005 | LOCKED | High | Gifts / identity | Tapping a sent gift/gifter bubble had no effect. | 2026-09-07 | `812696a77e15643a97a411028e0ba321948b12a5` | Live UX law requires gifter bubble tap → sender in-Live profile and forbids exposing gift type. | PASS — user physically accepted bubble/profile interaction. | 0 |
| FVB-006 | LOCKED | Low | Live profile | Host/self in-Live profile displayed FameTaps even though the host does not want that metric shown by default. | 2026-09-07 | `6ccd93357f915e9e99879d6f75244a66cce67e95` | Live profile law requires self profile to hide FameTaps while preserving Gifts Sent. | PASS — owner approved the final self-profile contract. | 0 |
| FVB-007 | LOCKED | High | Main profile / gifter identity | Main profile was visually dry and did not expose the approved gifter level, tier progression, next unlock requirements, or locked/blurred future badges; privileged Owner/Admin identity also suppressed the progression presentation. | 2026-09-07 | `2aea5c08a9427a12dd6917f429d000ead5ae3925` | Gifter badge law now requires the saved nine-tier ladder, exact coin curve, blurred future artwork, next-level requirement, Gifts Sent, and Followers/Following/Friends order. | PASS — user physically accepted Profile Gifter Progress V1 on iPhone. | 0 |
| FVB-008 | LOCKED | Medium | Gift tray / mobile layout | Selected gift / Custom / Send footer could look cramped and become partially clipped at the bottom of the tray on iPhone browser chrome. | 2026-09-07 | `d0fb59428b5430f67bce773554022d6cc9e60895` | Tray is a shrink-safe flex column, gift grid shrinks/scrolls first, action footer reserves space, and safe-area bottom breathing room is enforced. | PASS — iPhone tray footer remained visible and uncramped. | 0 |
| FVB-009 | FIX_CANDIDATE | Medium | Co-host / mobile layout | Preview-approved Live Layout V1 refinement introduced a 5px rendered gap between the two co-host squares, violating the existing ≤2px side-by-side geometry lock. | 2026-09-07 | pending follow-up SHA | `tests/e2e/cohost-layout.spec.js` requires equal 1:1 panes and ≤2px horizontal separation for host and viewer layouts. | Automated browser recheck pending; physical co-host geometry still required. | 0 |

## FVB-004 recurrence trace

**VERIFY**  
Physical iPhone screenshots showed Safari's broken-image placeholder in the Welcome gift card/selected preview, followed by the correct poster after the tray rendered again.

**TRACE**  
The original static-poster repair removed fragile remote-video seeking, but `LiveGiftTray.jsx` still inserted a raw `<img src={gift.poster}>` only when the tray rendered. There was no early preload, explicit ready state, error masking, or bounded retry. A transient first request could therefore expose Safari's broken-image UI until a later remount retried the resource.

**SPRAY**  
Poster images now prime when the gift tray module loads; poster pixels render only after a successful `load`; broken pixels remain hidden; the same local poster retries at most twice.

**LOCK**  
`check-gift-tray-resilience.mjs` runs in the Engineering Gate. Physical iPhone repetition passed at `d0fb59428b5430f67bce773554022d6cc9e60895`; FVB-004 is locked again with reopen count 1.

## FVB-008 trace

**VERIFY**  
Physical iPhone screenshot showed the Selected gift / Custom / Send area pressed against the lower edge and partially obscured by mobile browser chrome.

**TRACE**  
The tray had `max-height: min(56svh, 560px)` plus `overflow: hidden`, while the gift grid retained its own fixed maximum height and the action/footer rows could not reserve space. On shorter visual viewports, the whole sheet clipped instead of shrinking the scrollable grid first.

**SPRAY**  
The tray now uses a flex column, the gift grid is the shrinkable/scrollable region, the action row owns a minimum height, and the footer reserves explicit safe-area breathing room.

**LOCK**  
The gift-tray resilience law guards footer geometry. Physical iPhone tray QA passed at `d0fb59428b5430f67bce773554022d6cc9e60895`; FVB-008 is locked.

## FVB-009 trace

**VERIFY**  
Engineering Gate run `34169027380` rendered both host and viewer co-host pairs with a 5px horizontal separation. The existing browser contract allows no more than 2px.

**TRACE**  
The visual refinement added `--fv-cohost-gap: 6px` and a 5px mobile override. The underlying equal-square layout remained correct; only the new decorative spacing violated the established geometry lock.

**SPRAY**  
Keep the approved equal-square refinement, but constrain the host/co-host separation to 2px on all mobile widths instead of weakening the regression test.

**LOCK**  
`tests/e2e/cohost-layout.spec.js` remains unchanged and must pass for both host and viewer. Physical dual-device square geometry remains required before FVB-009 can become `LOCKED`.

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
