# Build 18 — Four-Role Dev Signoff

Build isolation: **Build 18 only** (`build18/live-repair`). Build 16 and Build 17 are evidence sources, not merge targets. No code is to be copied back into those tester builds.

## 1. BUILDER — implementation
Status: **DONE FOR CURRENT PATCHSET**

Responsibilities completed in this patchset:
- Preserved the approved equal-square side-by-side co-host stage.
- Camera-off now keeps the participant visually present using their Stream/Fameverse profile photo when available, with name and Camera off state instead of a black empty box.
- Host Stream identity now carries the Fameverse profile photo so the host camera-off state can render correctly.
- Reworked Live chat to match the V2 hierarchy: larger readable message text, avatar/initial, name, level badge, clean separation, and gift-state styling.
- When co-hosting, chat is positioned immediately below the two camera squares instead of being pushed to the bottom under a large empty purple gap.
- Replaced the single-line typewriter composer with a multiline composer that visibly wraps from 1 to 3 lines.
- Kept the End action red.
- Reworked the Fame action so the `F` itself is purple/high-contrast rather than a blank/pale control.
- Preserved the repaired viewer Gift button, host-ended exit, leave-live cleanup, gift tray responsiveness, one-coin gift behavior, Fame Tap reactions, and Build 17 profile/payout/recharge repairs.

## 2. REVIEWER — code and law review
Status: **DONE FOR CURRENT PATCHSET**

Review rules enforced:
- No unrelated redesign.
- Far-right V2 mockup remains the Live visual/layout authority.
- Equal square co-host cameras remain locked; no stacked portrait panels.
- Camera-off profile state is now a regression contract.
- Multiline composer and readable V2 chat are regression contracts.
- Fame control remains purple; End remains red.
- No Build 16/17 branch mixing.
- No fake PASS from static inspection.

## 3. QA AGENT — automated + physical validation
Status: **AUTOMATED QA RUNNING / PHYSICAL QA PENDING**

Automated requirements:
- Dart formatting.
- Static analysis.
- Unit/widget tests.
- Build 18 regression law.
- Native foundation laws.
- iOS/Android compile preflight.

Physical requirements:
- Owner iPhone matrix.
- External tester iPhone matrix.
- Camera-off profile presentation on physical device.
- Multiline composer visibility/wrapping.
- V2 chat readability and placement below co-host cameras.
- Premium gift audio across the catalog, including while co-hosting.
- Viewer Gift button on the external tester path.
- Host End must eject viewers/co-hosts.

QA may block a build. QA may not declare physical success from CI.

## 4. RELEASE ENG — production protection
Status: **LOCKED RED**

- PR stays draft.
- Build 18 is not release-approved.
- Physical iPhone acceptance manifest remains pending.
- TestFlight upload is a candidate only, never a PASS.
- Any change to protected native Live/Profile code after physical acceptance invalidates the fingerprint and requires another physical test.

## Screenshot / recording authority
The tester screenshot with the red **End** button is the host path. The newer owner recording and V2 mockups establish the intended Live composition: equal square cameras, organized readable chat directly underneath during co-hosting, multiline visible typing, purple Fame control, red End action, and profile-backed camera-off state.
