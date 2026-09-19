# Host Live Reset Lock

Status: HOST LIVE REMOVED BEFORE REBUILD.

Until the CEO explicitly approves the new Host Live build:

- No Host Live navigation entry may exist.
- `App.jsx` may not import, render, or initialize Host Live runtime owners.
- The retired `LiveScreen.jsx` implementation is removed.
- Retired Host Live CSS remains outside the active bundle.
- Viewer Live may remain available as a separate viewer-only experience.
- There is one PWA runtime for iPhone and Android; no platform-specific Host Live shells are allowed.
- The visible in-app updater remains a shared app-level system.

The replacement Host Live must be introduced as one fresh canonical build after this reset passes build and regression gates.
