# Build 48 — Host Live performance and file-cleanup gate

**Scope:** performance, livestream stability, reduced unnecessary work and network use, thermal/battery efficiency, responsive user experience. Android **and** iOS are equally required.

## Isolated repair branch
- Branch: `perf/build48-host-tap-polling-lifecycle-nov15`.
- Source: the exact Build 47 native release branch, isolated as a **draft**.
- One subsystem only: Flutter **host Live** cosmetic FameTaps polling.
- Protected: heartbeat/presence, media provider, co-host permissions, gifts, wallet, payment, approved UI layout, native foundation and signing workflows.
- No merge, production deployment, or Build 47 hotfix implied by this draft.

## Verified code path and smallest cleanup
The host screen made an API read every 2 seconds even when backgrounded, and a slow response could overlap the next timer tick. This change reuses the existing tap refresh timer and existing lifecycle framework; it does **not** introduce a second polling service.

- Register the Flutter lifecycle observer on creation, remove it during disposal.
- Run cosmetic FameTaps polling only while the app is foregrounded.
- Guard against an in-progress refresh so slow networks cannot spawn concurrent reads.
- Discard background/late results to avoid unnecessary UI updates.
- Continue authoritative 15-second room heartbeats during app backgrounding. They are a **Live stability requirement**, not cosmetic polling.
- Do not change gift receipt processing, rank labels, overlays, video layout, camera or co-host flows.

## Branch and file cleanup law
1. Prefer the **smallest isolated diff** over sweeping reformatting or new files for existing runtime logic.
2. Reuse existing state and timer architecture; no unnecessary duplicated services or timers.
3. Never delete or reorganize a file before proving its actual import and runtime consumers. Preserve platform, widget and legal gates.
4. Track each later hotspot in its own branch and tests: host polling, viewer tap queue/network flush, camera lifecycle, gift media decoding, Live discovery, and background/foreground recovery.
5. Merge only after exact-source format/analyzer/unit/widget and Android+iOS builds pass; physical-device pass is required for LOCKED status. An unsigned compile is not a distributed app.

## Tests and physical acceptance
- Automated: `dart format --output=none --set-exit-if-changed lib test tool`, `flutter analyze`, `flutter test`, Android debug APK compile, unsigned iOS release compile, existing repository laws.
- Physical Android and iPhone: host Live 15+ minutes foreground; background/resume; viewer receives uninterrupted stream; FameTaps resume accurately; audio and mic remain correct; stress toggles and camera/co-host scenarios must not regress.
- Compare equivalent device, OS, network, brightness and session length when measuring battery/thermal behavior; **no claimed battery savings or overheating prevention without device evidence**.
- On failure: stop, capture exact commit/build/device, trace root cause, revert if necessary. No premature LOCKED status.

**Current state:** FIX_CANDIDATE pending automated checks and physical Android+iOS QA.
