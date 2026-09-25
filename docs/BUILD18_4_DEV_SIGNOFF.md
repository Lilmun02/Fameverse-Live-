# Build 18 — Four-Role Dev Signoff

Build isolation: **Build 18 only** (`build18/live-repair`). Build 16 and Build 17 are evidence sources, not merge targets. No code is to be copied back into those tester builds.

## 1. BUILDER — implementation
Status: **DONE FOR CURRENT PATCHSET**

Responsibilities completed in this patchset:
- Fixed host Live header to show the creator handle rather than a truncated display name.
- Removed ellipsis behavior from the host identity and scale the full handle down when space is tight.
- Increased host chat viewport to match the repaired viewer experience.
- Forced white `End` text on the red button for physical contrast.
- Forced a purple/high-contrast host `F` control so the button cannot appear as an unlabeled pale circle.
- Preserved the already-repaired Build 18 square side-by-side co-host stage, tap flames/Fs, viewer Gift button, host-ended exit, gift tray responsiveness, one-coin gift behavior, and Build 17 profile/payout/recharge repairs.

## 2. REVIEWER — code and law review
Status: **DONE FOR CURRENT PATCHSET**

Review rules:
- No unrelated redesign.
- Approved Live layout remains locked.
- No Build 16/17 branch mixing.
- No fake PASS from static inspection.
- Regression tests now lock the tester-screenshot failures: full host handle, no ellipsis, visible End text, visible F button, readable chat, square co-host geometry.

## 3. QA AGENT — automated + physical validation
Status: **AUTOMATED QA RUNNING / PHYSICAL QA PENDING**

Automated requirements:
- Dart formatting.
- Static analysis.
- Unit/widget tests.
- Native foundation laws.
- iOS/Android compile preflight.

Physical requirements:
- Owner iPhone matrix.
- External tester iPhone matrix.
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

## Screenshot classification
The tester screenshot with the red **End** button is the **host path**, not the viewer path. Therefore the missing Gift button in that specific screenshot is expected for a host who cannot gift their own Live. The screenshot still proves separate host-side regressions: truncated identity, low-contrast End text, invisible/blank-looking F control, tiny chat presentation, and the old vertically stacked co-host stage.
