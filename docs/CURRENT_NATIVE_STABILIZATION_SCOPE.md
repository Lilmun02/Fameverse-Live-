# Current Native Stabilization Scope

## Release intent
This candidate is a stabilization release only.

Allowed changes:
- App performance improvements.
- Bug fixes.
- Regression fixes.
- Release-safety checks and test coverage needed to prove those fixes.
- Native file-law remediation: source files must be split by responsibility and remain at or below the existing 450-line source limit.
- Exact parity with the already-approved PWA gifter badge/level system, including the same tier ranges, progression thresholds, earned-state rules, and privileged-role hiding behavior. This is parity work, not a new badge economy.

Not allowed in this candidate:
- New Stories layouts or Story Feed redesigns.
- New Live Feed redesigns.
- New Beta/OG badge rollout beyond the already-approved PWA gifter badge/level parity.
- Verified Streamer system.
- Sleep Live.
- New creator progression systems unrelated to fixing an existing shipped/approved flow.
- New monetization features unrelated to correcting the current payout/gifting implementation.
- Any unrelated feature expansion.

## Required repair areas before candidate QA
- Live gifting placement, tray behavior, gift rendering, gift queue/combo behavior.
- Live profile card / approved gifter identity behavior.
- Live rankings wiring where already planned as part of the current broken Live baseline.
- Owner payout review/moderation workflow.
- Startup/launch regressions.
- Camera flip and keyboard regressions.
- Owner-only control privacy for normal tester accounts.
- Same-build host/viewer/co-host device parity.
- Native source organization/file-law enforcement across `lib/**/*.dart`.
- PWA-to-native gifter badge/level parity on Profile, Live profile identity, and Live chat level markers.

## Release law
PATCH -> TRACE -> TEST -> REGRESSION LOCK -> BUG SPRAY -> DEVICE TEST -> PASS.

Source tests are not a physical PASS. The candidate must be physically verified on the owner iPhone and a non-owner external tester account before external promotion or release approval.

## Canonical candidate source
The current canonical source branch is `integration/sep27-big-update` until an explicitly approved branch migration occurs.

No other branch should be treated as a TestFlight source merely because it is selected in a build UI. Codemagic's publishing workflow must continue to verify and record the exact canonical source SHA it compiles.
