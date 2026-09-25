# Build 18 Repair Changelog

Status: **in repair — not passed**

Implemented in this branch so far:

- Restored the approved two equal square host/co-host camera layout side-by-side.
- Increased Live chat readability from the tiny Build 16 presentation.
- Restored rising Fame Tap `F` / flame visual feedback.
- Reworked viewer leave so network/tap cleanup cannot block the Live route from closing.
- Added Stream call-state handling so viewer/co-host exits when the host ends the call.
- Changed the Live header to expose the creator handle instead of only a clipped display name.
- Reduced the bottom viewer action row so Gift remains visible on narrower iPhones; removed the crowded one-tap Rose shortcut.
- Made Gift the highlighted action while Share remains available from the F menu.
- Made gift tray send respond immediately instead of visually waiting on the backend request.
- Made owner/admin `+10K` update the already-open gift tray balance.
- Prevented 1-coin classic gifts from using the premium full-screen takeover overlay.
- Replaced black/empty remote-video gift thumbnails with deterministic Fameverse poster art.
- Allowed cinematic gift video playback to mix with active Live audio; physical iPhone audio validation is still required.
- Carried the Build 17 Profile / Creator Studio / payout repair work into Build 18.
- Replaced the protected Vercel recharge page with a native Fameverse owner-QA PayPal sandbox flow. Supabase now stays API-only and returns PayPal's real approval URL; Vercel is not part of recharge.
- Hard-locked the Codemagic TestFlight candidate to `build18/live-repair` and added a source-identity artifact containing the exact commit used for the IPA.
- Enabled the native preflight on the Build 18 branch itself and added Build 18 regression checks before static analysis/tests.

Nothing in this file is a physical QA PASS. See `BUILD18_TEST_MATRIX.md`.
