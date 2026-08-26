# Fameverse source architecture

Fameverse uses a feature-first layout so bugs have one obvious home and unrelated systems are not edited together.

## Hard rule

No `.js`, `.jsx`, or `.css` file under `src/` may exceed **450 lines**.

`npm run check:lines` enforces the limit, and `npm run build` runs the line guard before Vite. If a file grows past 450 lines, split it by responsibility before merging or deploying.

## Entry points

- `main.jsx` — mounts React, loads approved runtime integrations, and imports styles in deterministic order.
- `App.jsx` — application coordinator only. It composes hooks and screens; feature implementation does not belong here.

## Components

- `components/auth/` — sign in and sign up UI.
- `components/live/` — live screen and controls.
- `components/gifts/` — React gift overlays and repeat controls.
- `components/discover/` — discovery UI.
- `components/profile/` — profile, creator studio, and profile editing.
- `components/settings/` — settings, legal, privacy, and account detail screens.
- `components/layout/` — shared navigation/header UI.

## Hooks

- `hooks/useAccount.js` — auth session, profile loading, profile saving, and sign out.
- `hooks/useLiveMedia.js` — camera, microphone, wake lock, live state, and camera flipping.
- `hooks/useGiftSystem.js` — test balance, gift transactions, combo state, and renderer dispatch.
- `hooks/usePwaInstall.js` — installed-PWA detection and installation prompt state.

## Features and services

- `features/gifts/renderer/` — standalone cinematic renderer queue.
- `features/feedback/` — beta feedback widget.
- `services/supabase.js` — the single Supabase client and startup-auth compatibility patch.
- `config/` — static gift, creator, and legal configuration.
- `utils/` — small pure/shared helpers.

## Styles

Styles are grouped by ownership under `styles/`.

- `styles/base/` — global shell, foundation, and viewport rules.
- `styles/live/` — live surface, sheets, and polish.
- `styles/gifts/` — gift grid, renderer, and gift UI.
- `styles/feedback/` — beta feedback UI.
- `styles/legacy/` — older patch layers that still affect production and must be removed carefully, not casually edited.

## Disabled legacy experiments

`legacy/disabled/` contains code intentionally removed from runtime. Files there are preserved for debugging history only and must not be imported without a Linear issue, review, and device verification.

Current disabled experiments:

- `media-session.js` — created a second Live state machine outside React and caused state races.
- `flip-guard.js` — visual freeze-frame masking experiment. The approved camera-first flip logic now belongs in `hooks/useLiveMedia.js` instead.
