# Build 23 Internal Bug Patch Status

This file records the current patch-before-lock state for the Sep 27 Build 23 repair branch.

## Persisted source patches

- Owner Control Center `$0` string parse blocker fixed.
- Host flip-camera calls serialized with `_flipCameraBusy`; flip control disables while a flip is active.
- Build 23 profile verification uses `creator_verification_requests.status == verified`; owner premium remains separate from verification.
- Host Live no longer renders an unconditional fake verification check.
- Host/viewer comment sends dismiss software-keyboard focus.
- Viewer gift tray opening and gift sending dismiss software-keyboard focus.
- Gift activity chat keeps the event marker but no longer renders the oversized purple card/background/border/shadow.

## Verification state

- Source patch: persisted.
- Flutter static analysis: must pass on the persisted patch SHA.
- Flutter regression/unit/widget tests: must pass on the persisted patch SHA.
- Android debug compile: must pass on the persisted patch SHA.
- Unsigned iOS release compile: must pass on the persisted patch SHA.
- Physical iPhone owner/external-tester QA: required before DEVICE PASS.

Regression tests do not substitute for the physical-device verification of camera, keyboard, Live, gift playback, and co-host behavior.
