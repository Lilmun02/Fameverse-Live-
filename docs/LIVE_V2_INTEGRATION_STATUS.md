# Host Live V2 integration candidate

Date: 2026-09-20
Repository: `Lilmun02/Fameverse-Live-`
Local branch: `fix/live-v2-integration`
Implementation combines the approved rebuild `69798f0` and camera repair `a0b4298` with the integration changes below. Use this branch's current remote SHA for acceptance.
Status: preview candidate; production and physical acceptance remain pending.

## What is included

- The approved Host Live V2 rebuild from `69798f0`, including its latest gift sender toast and quantity display.
- Camera-slot parity changes from `a0b4298` combined into that rebuild. Both camera slots use the same full-canvas compositing rules.
- App-update deferral recognizes the new V2 host room, so the updater does not deliberately reload an active V2 broadcast.
- Update notices avoid repeating identical DOM writes inside their own mutation observer.
- The canonical shell guard targets the approved V2 host and runs with the build.
- Physical acceptance fingerprints include the active V2 host, media hook, V2 styles, foreground repair, and updater.
- Browser QA runs before the physical release lock in CI. The release lock still blocks promotion until genuine device acceptance is recorded.

The approved identity/header/composer design is preserved. No production branch or database was changed.

## Verification

- `npm run build`: passed, including lint, contract typechecking, 13 unit tests, configured regression laws, and production bundle generation.
- `git diff --check`: passed.
- `npm run check:release-physical`: correctly blocked because `docs/PHYSICAL_ACCEPTANCE.json` still records pending co-host acceptance.
- Browser tests were added for both camera slots at two phone widths, co-host square geometry and cleanup, and update deferral/resumption. Execution is unverified: the local Playwright browser was unavailable and its download timed out. The cloud browser could not reach the loopback preview (`ERR_BLOCKED_BY_CLIENT`).
- Real-device camera/audio, gifting, and two-device co-host acceptance have not been performed in this session.

## Publication authorization

The owner explicitly authorized publishing this candidate branch to `Lilmun02/Fameverse-Live-` for preview testing on 2026-09-20. This resolves the earlier automatic-review publication blocker; it does not record physical acceptance.

## Next authorized continuation

Publish the authorized candidate and open a draft integration PR. Verify CI/browser QA and the preview for the exact published commit.

Then test on real target phones: start/end Live, repeated camera flips, foreground recovery, gifts and quantities, invite/accept co-host, two equal camera tiles, usable two-way audio without echo, and leave/end cleanup. Record physical acceptance only from actual results. Production promotion remains subject to `PHYSICAL_ACCEPTANCE_LAW.md` and `ENGINEERING_SAFETY_NET.md`.
