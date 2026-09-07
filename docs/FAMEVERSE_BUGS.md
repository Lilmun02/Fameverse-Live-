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

- Total tracked: **8**
- Open: **0**
- Fix candidates: **2**
- Locked: **4**
- Reopened right now: **0**
- Legacy recheck: **2**
- Reopens recorded since registry start: **1**

## Registry

| ID | Status | Severity | Area | Bug | First verified | Fix / candidate SHA | Regression lock | Physical acceptance | Reopens |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: |
| FVB-001 | LEGACY_RECHECK | Critical | Live media | Camera could shut off while repeatedly flipping cameras. | 2026-08-25 | — | Media/camera checks exist, but legacy root cause was not preserved. | Fresh retest required before declaring current state. | 0 |
| FVB-002 | LEGACY_RECHECK | Critical | Startup/PWA | App could transition through black/white screens or lose the intended splash/startup behavior. | 2026-08-25 | — | Startup/device-truth checks now exist, but the historical root cause was not preserved in this registry. | Fresh installed-device retest required before declaring current state. | 0 |
| FVB-003 | LOCKED | High | Gifts / iPhone media | 100-coin Welcome gift could play without its original audio on iPhone. | 2026-09-07 | `8c70ba4b2768e70ea8376617fce03ff521857b9c` | Premium media is prepared on the send gesture and reused; gift backend/media laws guard the path. | PASS — original audio physically accepted on iPhone. | 0 |
| FVB-004 | FIX_CANDIDATE | Medium | Gift tray | Welcome gift thumbnail can briefly render Safari's broken-image placeholder before the real static poster appears. This is a recurrence of the prior thumbnail defect family. | 2026-09-07 | pending exact candidate SHA | Static poster remains mandatory; strengthened candidate preloads poster media, hides failed pixels until `load`, retries bounded failures, and adds a dedicated gift-tray resilience law. | PENDING — must open tray repeatedly on iPhone and confirm no broken icon/flicker. | 1 |
| FVB-005 | LOCKED | High | Gifts / identity | Tapping a sent gift/gifter bubble had no effect. | 2026-09-07 | `812696a77e15643a97a411028e0ba321948b12a5` | Live UX law requires gifter bubble tap → sender in-Live profile and forbids exposing gift type. | PASS — user physically accepted bubble/profile interaction. | 0 |
| FVB-006 | LOCKED | Low | Live profile | Host/self in-Live profile displayed FameTaps even though the host does not want that metric shown by default. | 2026-09-07 | `6ccd93357f915e9e99879d6f75244a66cce67e95` | Live profile law requires self profile to hide FameTaps while preserving Gifts Sent. | PASS — owner approved the final self-profile contract. | 0 |
| FVB-007 | LOCKED | High | Main profile / gifter identity | Main profile was visually dry and did not expose the approved gifter level, tier progression, next unlock requirements, or locked/blurred future badges; privileged Owner/Admin identity also suppressed the progression presentation. | 2026-09-07 | `2aea5c08a9427a12dd6917f429d000ead5ae3925` | Gifter badge law now requires the saved nine-tier ladder, exact coin curve, blurred future artwork, next-level requirement, Gifts Sent, and Followers/Following/Friends order. | PASS — user physically accepted Profile Gifter Progress V1 on iPhone. | 0 |
| FVB-008 | FIX_CANDIDATE | Medium | Gift tray / mobile layout | Selected gift / Custom / Send footer can look cramped and become partially clipped at the bottom of the tray on iPhone browser chrome. | 2026-09-07 | pending exact candidate SHA | Candidate makes the tray a shrink-safe flex column, lets the gift grid shrink/scroll first, reserves a 66px action footer, and adds safe-area bottom breathing room. | PENDING — iPhone tray footer must remain fully visible and uncramped. | 0 |

## FVB-004 recurrence trace

**VERIFY**  
Physical iPhone screenshots showed Safari's broken-image placeholder in the Welcome gift card/selected preview, followed by the correct poster after the tray rendered again.

**TRACE**  
The original static-poster repair removed fragile remote-video seeking, but `LiveGiftTray.jsx` still inserted a raw `<img src={gift.poster}>` only when the tray rendered. There was no early preload, explicit ready state, error masking, or bounded retry. A transient first request could therefore expose Safari's broken-image UI until a later remount retried the resource.

**SPRAY**  
Candidate: prime poster images when the gift tray module loads; render poster pixels only after a successful `load`; hide failed/broken-image pixels; retry the same local poster a maximum of two times.

**LOCK**  
Candidate adds `check-gift-tray-resilience.mjs` to the Engineering Gate. Physical iPhone repetition is still required before FVB-004 returns to `LOCKED`.

## FVB-008 trace

**VERIFY**  
Physical iPhone screenshot showed the Selected gift / Custom / Send area pressed against the lower edge and partially obscured by mobile browser chrome.

**TRACE**  
The tray had `max-height: min(56svh, 560px)` plus `overflow: hidden`, while the gift grid retained its own fixed maximum height and the action/footer rows could not reserve space. On shorter visual viewports, the whole sheet clipped instead of shrinking the scrollable grid first.

**SPRAY**  
Candidate converts the tray to a flex column, makes the gift grid the shrinkable/scrollable region, gives the action row its own minimum height, and reserves explicit safe-area breathing room.

**LOCK**  
Candidate regression law checks poster resilience and footer geometry. Physical iPhone tray QA is still required.

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
