# Build 48 — Gift foreground-only release blocker

**Status:** CONFIRMED DEFECT / NOT FIXED / DO NOT MARK GREEN.
**Source of evidence:** Owner-supplied iPhone screen recording "ScreenRecording_11-15-2026 11-48-47_1.mp4" (244.0667 s, 30 fps, 7,322 frames, 512×1108).
**Method:** Entire 7,322-frame decode processed for full-duration visual statistics, plus inspected timed montage and close-up keyframes covering start through final 4:04. Recording frame sampling is 33.3 ms; it does not contain a separate image for each literal millisecond.

## Observed evidence (approximate elapsed times)
- 00:27–00:43 — Abyssal Leviathan renders with a full rectangular dark ocean/space background and clip-embedded "FAMEVERSE LIVE" text; obscures live camera.
- 00:52 — lightweight Fame Burst animation appears with a horizontal yellow bar; review against owner no-underlines requirement.
- 01:05–01:15 — Celestial Phoenix video contains a whole floating-island/sky scene and branded frame, not an isolated transparent gift.
- 01:39–01:46 — Welcome to Fameverse contains an illustrated village and framed poster filling the gift video rectangle.
- 02:20–02:25 — the opaque Welcome scene remains visible behind the open gift tray.
- 02:36–03:13 — Ember Dragon / Abyssal Leviathan clips repeatedly cover much of the live camera with their own moving backgrounds.
- 03:40–03:52 — additional Welcome and Phoenix playback shows the same opaque-scene problem. Camera becomes visible afterward; end-live confirmation is shown near 04:00.

## Code-level root cause verified
- `native/flutter_v1/lib/features/live/native_live_components.dart`, `NativeGiftOverlay.build()`: cinematic playback uses `VideoPlayer(controller)` in a `SizedBox(width: size.width, height: size.height * .76)` (via `FittedBox`) above the Live stage.
- `native/flutter_v1/lib/data/fameverse_live_backend.dart`: the four affected gifts' `videoUrl` values point to `.mp4` videos without a separate foreground/alpha visual layer in the catalog.
- The observed videos already include scenery and backdrop pixels. Making the Flutter surrounding `Container` transparent cannot make those video pixels transparent. A foreground-only alpha asset, robust segmentation/compositing pipeline, or owner-approved re-render is required.
- The tray's preview `native_gift_visual.dart` also plays the same source clips as previews; this does not itself cause the live playback, but thumbnail sources must be checked after asset repair.

## Required owner's original visual contract
- Gifts are distinct, animated foreground objects over the actual camera; **no full-screen scenic background video**.
- Preserve sender identity and sequential combo/gift receipt semantics; never double-charge, replay callbacks, overlap two gifts, or double audio.
- No subtitles or underline/progress-bar decoration on gift visual; low-coin gifts remain lightweight.
- Preserve owner-approved logo/branding treatment, not a hardcoded new center watermark.
- Maintain Android+iOS parity. No camera/layout, wallet, policy, rank, DB, or platform signing changes as part of this fix.
- Do **not** silently replace premium video with emoji, hide gifts, crop out the subject, or claim successful alpha compositing without both real-device recordings.

## Acceptance / regression law
1. Rebuild/obtain cutout foreground gift layers for all four premium assets, retaining original intended animation and sound once.
2. Prove alpha composition on **both Android and iOS** over varied live-camera brightness and while the gift tray opens. Capture real-device evidence.
3. Prove 1x / 3x combo playback and authoritative gift-ledger totals independently; verify no overlapping audio or backgrounds.
4. Verify low-cost gift styling has no unexpected progress bar/underline and sender is identifiable.
5. On success, run Flutter formatting/analyze/tests, unsigned native compiles, signed device QA and protect approved live layout. Keep this defect **OPEN** until all pass.
6. Separate source branches per isolated renderer/asset/test change. Never merge unverified footage or override premium assets on assumption.

**This audit only documents the verified defect. No app visuals, source video, live ledger, wallet, Supabase schema, signing, or CodeMagic workflow are changed.**
