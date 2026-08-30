# Fameverse source architecture

Fameverse uses strict system boundaries so a bug in one core feature has a wall around it instead of leaking into unrelated behavior.

## Core architecture invariant

**One file = one system responsibility.**

A core file may own one feature system and the functions that belong to that system. It must not quietly own a second system. When another system is required, it is imported through a clear contract.

The professional order is:

```text
UI component
    ↓
coordinator hook
    ↓
feature system file
    ↓
service / browser API / backend
```

And the isolation rule is:

```text
1 file
  = 1 system responsibility
  = 1 core feature boundary
  = only the functions required by that boundary
```

Coordinator files are the only exception: they may compose systems, but they may not contain the implementation of those systems. `App.jsx`, `useAccount.js`, `useLiveMedia.js`, and `useGiftSystem.js` are coordinators/facades only.

## Why Fameverse uses this model

The goal is not to pretend bugs disappear. The goal is containment. Camera failures should remain in the camera system. Gift combo failures should remain in the combo system. Authentication failures should remain in auth. A fix in one system should not require editing unrelated systems.

No core feature may reach into another feature's private state or implementation. Shared behavior must cross a named system boundary through imports, parameters, return values, events, or a dedicated shared service.

## Hard file rule

No `.js`, `.jsx`, or `.css` file under `src/` may exceed **450 lines**.

`npm run check:lines` enforces the limit, and `npm run build` runs the line guard before Vite. If a file grows past 450 lines, split it by responsibility before merging or deploying.

## Current system map

```text
src/
  App.jsx                         application coordinator

  hooks/
    useAccount.js                 account coordinator only
    useLiveMedia.js               live-media coordinator only
    useGiftSystem.js              gift coordinator only
    usePwaInstall.js              PWA install coordinator

  systems/
    account/
      authSystem.js               authentication only
      profileSystem.js            profile data only

    device/
      wakeLockSystem.js           screen wake lock only

    media/
      liveStreamSystem.js         live A/V stream creation + disposal only
      cameraSystem.js             camera acquisition/swap/render attachment only
      microphoneSystem.js         microphone track state only

    gifts/
      giftWalletSystem.js         gift quantity/cost/balance rules only
      giftComboSystem.js          combo state/count rules only
      giftPresentationSystem.js   gift activity/overlay/renderer dispatch only

  services/
    supabase.js                   Supabase client only
```

## Entry points

- `main.jsx` mounts React, loads approved runtime integrations, and imports styles in deterministic order.
- `App.jsx` composes systems and screens. Core implementation does not belong in `App.jsx`.

## Components

UI components render and emit user intent. They do not own system rules.

- `components/auth/` — authentication UI.
- `components/live/` — live screen and controls.
- `components/gifts/` — gift presentation UI.
- `components/discover/` — discovery UI.
- `components/profile/` — profile/creator UI.
- `components/settings/` — settings/legal UI.
- `components/layout/` — navigation/header UI.

## Systems

System files own the behavior behind core features. A system may call lower-level services or browser APIs, but it does not render UI and it does not mutate another system's private state.

Examples:

- camera flip code belongs only in `systems/media/cameraSystem.js`;
- microphone behavior belongs only in `systems/media/microphoneSystem.js`;
- wake-lock behavior belongs only in `systems/device/wakeLockSystem.js`;
- gift combo math belongs only in `systems/gifts/giftComboSystem.js`;
- gift balance/cost rules belong only in `systems/gifts/giftWalletSystem.js`;
- authentication belongs only in `systems/account/authSystem.js`;
- profile persistence belongs only in `systems/account/profileSystem.js`.

## Styles

Styles are grouped by ownership under `styles/`.

- `styles/base/` — global shell, foundation, and viewport rules.
- `styles/live/` — live surface, sheets, and polish.
- `styles/gifts/` — gift grid, renderer, and gift UI.
- `styles/feedback/` — beta feedback UI.
- `styles/legacy/` — older patch layers that still affect production and must be removed carefully, not casually edited.

CSS follows the same containment principle: feature CSS stays with the feature ownership layer instead of becoming an unrelated global patch.

## Disabled legacy experiments

`legacy/disabled/` is debugging history only. Files there must not be imported back into runtime without explicit review and device verification.

Current disabled experiments:

- `media-session.js` — created a second Live state machine outside React and caused state races.
- `flip-guard.js` — visual freeze-frame masking experiment. Camera switching now crosses the dedicated camera-system boundary instead.

## Required refactor behavior going forward

When a bug exposes mixed responsibilities, do not patch across unrelated files. First identify the owning system. If the owning system does not exist yet, create it and move the behavior behind that boundary before adding more feature logic.

This architecture is a product requirement for Fameverse, not a suggestion or future guideline.
