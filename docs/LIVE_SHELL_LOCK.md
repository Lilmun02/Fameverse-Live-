# Famaverse Canonical Live Shell Lock

Status: protected architecture.

## Canonical host Live path

- React owner: `src/components/live/LiveScreen.jsx`
- Shared geometry owner: `src/styles/live/live-layout-v1-refinement.css`
- Final active-room contract: `src/styles/live/live-contract.css`
- Camera/media lifecycle owner: `src/hooks/useLiveMedia.js`
- App entry: `src/App.jsx` renders exactly one host `LiveScreen` path.

Android and iPhone must execute this same component tree and the same visual contract. Device-specific Live presentation branches are forbidden.

## Quarantine

Historical Live CSS overrides are forensic-only and must never be imported by the app bundle:

- `src/styles/legacy/disabled/live-release-shell.css`
- `src/styles/legacy/disabled/live-qa-shell.css`

Non-Live profile/settings/studio styles preserved from the old files live in `src/styles/legacy/nonlive-preserved.css`. That file is forbidden from owning Live selectors.

## Regression lock

`scripts/check-one-pwa-shell.mjs` must fail the build if:

- quarantined legacy Live CSS is imported,
- more than one host LiveScreen path exists,
- LiveScreen contains an iOS/Android presentation branch,
- LiveScreen owns focus/pageshow/visibility media detachment,
- LiveScreen renders the legacy vignette,
- the canonical shared layout/contract imports disappear,
- the PWA worker can restore a cached app shell.

Changes to this lock require CEO-approved scope and physical acceptance on the affected device path before production promotion.
