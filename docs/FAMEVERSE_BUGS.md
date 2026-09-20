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

- Total tracked: **10**
- Open: **1**
- Fix candidates: **2**
- Locked: **6**
- Reopened right now: **0**
- Legacy recheck: **1**
- Reopens recorded since registry start: **1**

## Registry

| ID | Status | Severity | Area | Bug | First verified | Fix / candidate SHA | Regression lock | Physical acceptance | Reopens |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | ---: |
| FVB-001 | LEGACY_RECHECK | Critical | Live media | Camera could shut off while repeatedly flipping cameras. | 2026-08-25 | — | Media/camera checks exist, but legacy root cause was not preserved. | Fresh retest required before declaring current state. | 0 |
| FVB-002 | OPEN | Critical | Startup/PWA distribution | Installed test app could show stale/broken startup behavior and the owner was repeatedly deleting/reinstalling it to receive new preview builds. Current 2026-09-20 reproduction includes installs made from per-deployment Vercel preview origins that change between builds. | 2026-08-25; current reproduction 2026-09-20 | Workflow candidate: stable branch preview alias; no code fix claimed yet. | One-PWA shell guard remains active; installed-update physical acceptance must now use one stable origin across consecutive deployments. | PENDING — install once from the stable branch alias, deploy a newer candidate to the same branch, verify update without deleting the app. | 0 |
| FVB-003 | LOCKED | High | Gifts / iPhone media | 100-coin Welcome gift could play without its original audio on iPhone. | 2026-09-07 | `8c70ba4b2768e70ea8376617fce03ff521857b9c` | Premium media is prepared on the send gesture and reused; gift backend/media laws guard the path. | PASS — original audio physically accepted on iPhone. | 0 |
| FVB-004 | LOCKED | Medium | Gift tray | Welcome gift thumbnail could briefly render Safari's broken-image placeholder before the real static poster appeared. This was a recurrence of the prior thumbnail defect family. | 2026-09-07 | `d0fb59428b5430f67bce773554022d6cc9e60895` | Static poster remains mandatory; poster media preloads early, failed pixels stay hidden until `load`, retries are bounded, and the gift-tray resilience law guards the path. | PASS — repeated iPhone tray test showed no broken icon/flicker. | 1 |
| FVB-005 | LOCKED | High | Gifts / identity | Tapping a sent gift/gifter bubble had no effect. | 2026-09-07 | `812696a77e15643a97a411028e0ba321948b12a5` | Live UX law requires gifter bubble tap → sender in-Live profile and forbids exposing gift type. | PASS — user physically accepted bubble/profile interaction. | 0 |
| FVB-006 | LOCKED | Low | Live profile | Host/self in-Live profile displayed FameTaps even though the host does not want that metric shown by default. | 2026-09-07 | `6ccd93357f915e9e99879d6f75244a66cce67e95` | Live profile law requires self profile to hide FameTaps while preserving Gifts Sent. | PASS — owner approved the final self-profile contract. | 0 |
| FVB-007 | LOCKED | High | Main profile / gifter identity | Main profile was visually dry and did not expose the approved gifter level, tier progression, next unlock requirements, or locked/blurred future badges; privileged Owner/Admin identity also suppressed the progression presentation. | 2026-09-07 | `2aea5c08a9427a12dd6917f429d000ead5ae3925` | Gifter badge law now requires the saved nine-tier ladder, exact coin curve, blurred future artwork, next-level requirement, Gifts Sent, and Followers/Following/Friends order. | PASS — user physically accepted Profile Gifter Progress V1 on iPhone. | 0 |
| FVB-008 | LOCKED | Medium | Gift tray / mobile layout | Selected gift / Custom / Send footer could look cramped and become partially clipped at the bottom of the tray on iPhone browser chrome. | 2026-09-07 | `d0fb59428b5430f67bce773554022d6cc9e60895` | Tray is a shrink-safe flex column, gift grid shrinks/scrolls first, action footer reserves space, and safe-area bottom breathing room is enforced. | PASS — iPhone tray footer remained visible and uncramped. | 0 |
| FVB-009 | FIX_CANDIDATE | Medium | Co-host / mobile layout | Preview-approved Live Layout V1 refinement introduced a 5px rendered gap between the two co-host squares, violating the existing ≤2px side-by-side geometry lock. | 2026-09-07 | pending follow-up SHA | `tests/e2e/cohost-layout.spec.js` requires equal 1:1 panes and ≤2px horizontal separation for host and viewer layouts. | Automated browser recheck pending; physical co-host geometry still required. | 0 |
| FVB-010 | FIX_CANDIDATE | Critical | Co-host / audio | Co-host Live can produce an audible whistle/feedback path during the handoff from the normal host relay to the direct co-host return. | 2026-09-20 | `fcbbc014040e0b14f4258802f8c59bb9cda4bcfd` | `check-cohost-physical-contract.mjs` requires complete direct A/V readiness, mutually-exclusive relay/direct host audio, acoustic echo controls, and muted local self-preview. | PENDING — two-device physical co-host test must confirm no whistle, echo, doubled host audio, scratch/chop, or audio loss through join/leave/rejoin. | 0 |

## FVB-002 current trace

**VERIFY**  
The owner reported repeatedly deleting and reinstalling the installed test app to receive the newest build. The current test workflow had also been handing out commit-specific Vercel deployment URLs whose hostnames change from deployment to deployment.

**TRACE**  
An installed PWA and its service worker are origin-scoped. A PWA installed from one immutable per-deployment Vercel hostname cannot update itself into a later deployment served from a different hostname. The existing one-PWA updater can refresh a newer shell on the same origin, but it cannot migrate an installed app between unrelated preview origins. This explains the delete/reinstall loop without pretending that native packaging alone repairs the web distribution path.

**SPRAY**  
Stop installing commit-specific deployment URLs. Installed PWA QA must use the stable branch alias so consecutive branch deployments remain on one origin. Keep the existing no-cache shell/update machinery active; do not force the owner to delete the app for routine preview updates.

**LOCK**  
FVB-002 stays `OPEN` until a physical installed-device sequence passes: install once from the stable branch alias, load build A, deploy build B on the same branch, reopen/foreground the installed app, and confirm it reaches build B without deleting or reinstalling.

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

## FVB-010 trace

**VERIFY**  
The owner reported the recurring whistle/feedback defect during co-host Live. The self-preview tile is already muted and co-host capture already requests echo cancellation, noise suppression, and automatic gain control, so those protections alone were not sufficient evidence of a single playback path.

**TRACE**  
During self co-host, the viewer transitions from the normal relayed host stream to a direct host WebRTC return. The previous runtime selected the direct stream as soon as the stream object existed, without requiring both a live video and live audio track, and did not explicitly make relay/direct host audio mutually exclusive during that transition. That handoff could temporarily expose overlapping audible host returns, a credible feedback/whistle path.

**SPRAY**  
The candidate waits until the direct host return has both a live video track and a live audio track. At the handoff, relay audio is disabled when direct audio becomes active, and direct audio is disabled whenever relay audio is the selected path. Local self-preview remains muted. No second `<audio>` element, analyser, synthetic tone, or new audio layer was introduced.

**LOCK**  
`check-cohost-physical-contract.mjs` now guards complete A/V readiness and mutually-exclusive host audio. FVB-010 remains `FIX_CANDIDATE` until physical two-device QA passes repeated join/leave/rejoin with no whistle, echo, doubled audio, scratch/chop, or missing host audio.

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
