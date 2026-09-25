# Build 18 — Repair Gate

Status: **BLOCKED / DO NOT DISTRIBUTE**

Build 16 external testing and Build 17 internal testing exposed regressions that must be repaired together in Build 18. A compile, CI success, simulator render, or code inspection is **not** a product PASS.

## Release law

Build 18 may not be called green, approved, or ready for TestFlight until BOTH physical-device paths pass:

1. Owner iPhone path, including viewer -> co-host -> leave/end-live behavior.
2. External tester iPhone path, including live viewing, chat, gifts, taps, and host-ended exit.

Any physical-device failure keeps the build red even when automated checks pass.

## Owner / co-host blockers

- [ ] Co-host layout is exactly two equal square camera boxes side-by-side: `HOST □ | □ CO-HOST`. Never stacked portrait panels.
- [ ] Leaving the live always exits the live screen. Network/tap flush/transport cleanup may not trap the user in Live.
- [ ] When the host ends the broadcast, every viewer and co-host is removed from the live screen automatically.
- [ ] Live header shows the creator identity/handle clearly. Do not replace the handle with a clipped name ending in `...`.
- [ ] Chat is readable at normal iPhone distance and is not compressed into tiny text.
- [ ] Fame Tap feedback restores visible rising `F` / flame reactions while taps are registered.
- [ ] Fame Tap count remains accurate.
- [ ] Premium gift send has immediate UI feedback; the gift tray cannot look frozen while a backend request runs.
- [ ] `+10K` test-coin refill updates the balance in the already-open gift tray immediately. Closing/reopening must not be required.
- [ ] Premium gift audio works consistently across the catalog and is actually audible on physical iPhone speakers, including while co-hosting.
- [ ] A gift with no/failed audio track is a failure; one working gift does not count as an audio PASS.
- [ ] One-coin classic gifts do not take over the live screen with the large premium-gift overlay.

## External tester blockers

- [ ] Gift button/store is visible and usable on supported iPhone widths; it may not disappear because the bottom control row overflows.
- [ ] Gift previews do not show ugly empty/black thumbnail boxes.
- [ ] Chat is large enough to read and keeps the approved lower-live placement.
- [ ] Host-ended broadcast ejects the tester from the live screen.
- [ ] Gift send, chat event, wallet update, and animation agree with each other on the tester device.

## Locked approved Live layout

- Solo: camera-first / full-screen video.
- Co-host: 50/50 equal square camera boxes side-by-side.
- Top: creator identity + LIVE status; live stats remain compact.
- Host End Live stays top-right.
- Chat overlays the lower live region and remains readable.
- Bottom: normal comment composer plus compact actions; Gift remains a primary/highlighted action.
- Camera / mic / flip / co-host controls stay in the `F` menu rather than being scattered over the live canvas.
- No freestyle redesign while repairing regressions.

## Build 17 repairs carried into Build 18

- [ ] Restore the real social Profile surface.
- [ ] Keep Creator Studio separate from Profile.
- [ ] Separate payout eligibility/setup from public profile verification.
- [ ] Keep owner/internal QA out of normal user Profile/Creator Studio UI.
- [ ] Keep the payout SQL ambiguity repair.
- [ ] Recharge must render as a real checkout page rather than raw HTML/text.

## Pass evidence required

For every checked item, record physical-device evidence (screen recording or direct owner/tester confirmation). Automated checks can block a bad build, but they cannot independently certify a good build.
