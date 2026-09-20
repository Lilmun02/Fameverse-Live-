# Famaverse Canonical Live Shell Lock

Status: protected architecture.

## Canonical host Live path

- React owner: `src/components/live/HostLiveV2.jsx`, following `LIVE_V2_APPROVED_UI.md`.
- Host geometry owner: `src/styles/live/host-live-v2.css`.
- Co-host geometry: `src/styles/live/host-live-v2-cohost.css`.
- Camera-slot contract: `src/styles/live/host-live-v2-video-lock.css`.
- The older shared layout and contract styles remain for the viewer and pre-live dependencies; they do not own V2 host geometry.
- Camera/media lifecycle owner: `src/hooks/useLiveMedia.js`
- App entry: `src/App.jsx` renders exactly one host `HostLiveV2` path. The retired `LiveScreen` is not mounted.

Android and iPhone must execute this same component tree and the same visual contract. Device-specific Live presentation branches are forbidden.

## Quarantine

Historical Live CSS overrides are forensic-only and must never be imported by the app bundle:

- `src/styles/legacy/disabled/live-release-shell.css`
- `src/styles/legacy/disabled/live-qa-shell.css`

Non-Live profile/settings/studio styles preserved from the old files live in `src/styles/legacy/nonlive-preserved.css`. That file is forbidden from owning Live selectors.

## Regression lock

`scripts/check-one-pwa-shell.mjs` must fail the build if:

- quarantined legacy Live CSS is imported,
- the approved HostLiveV2 path is missing or duplicated, or the retired LiveScreen is mounted,
- HostLiveV2 contains an iOS/Android presentation branch,
- HostLiveV2 owns focus/pageshow/visibility media detachment,
- HostLiveV2 renders the legacy vignette,
- the canonical shared layout/contract imports disappear,
- the PWA worker can restore a cached app shell.
- app-update deferral no longer recognizes an active HostLiveV2 session.

Changes to this lock require CEO-approved scope and physical acceptance on the affected device path before production promotion.
