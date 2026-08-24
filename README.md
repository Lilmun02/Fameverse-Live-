# Fameverse Live

Mobile-first streaming platform prototype. This repository is intentionally separate from AIWCORE and Zenith Drift.

## Beta 0.1

Current testing scope:

- Installable React/Vite PWA shell
- Host live-room controls
- One co-host slot with invite/remove flow
- Host/co-host split-screen layout
- Discover and profile shells
- Owner-local test coins for gift-flow testing
- Rose, Crown and Dragon gift test actions
- Clear disabled/placeholders for unfinished production systems

## Run in Codespaces

```bash
npm install
npm run dev
```

Open the forwarded Vite port (normally `5173`) to test the beta.

## Production boundary

Beta 0.1 does **not** contain real video streaming transport, production authentication, production wallet accounting, creator payouts, battles or events. Owner test coins are stored locally in the browser for development only and must not be treated as purchased or earned currency.

Before production wallet testing, Fameverse Live should receive its own backend project and server-authorized owner/admin role checks.
