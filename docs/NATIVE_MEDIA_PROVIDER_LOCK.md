# Fameverse Native Media Provider Lock

## Approved architecture

- **Stream Video** is the approved and locked native realtime media provider for Fameverse camera, microphone, WebRTC host/viewer transport, future co-host media, and future battle media.
- **Supabase** remains the authoritative Fameverse backend for authentication, profiles, follows, `live_rooms`, presence, comments, FameTaps, gifts, wallets, moderation, battle state, earnings, and payouts.
- The Flutter client may receive the Stream **API key** and a short-lived user token after Fameverse authentication. The Stream **API secret must remain server-side** and must never be embedded in the app, committed to GitHub, or exposed to clients.
- Stream user tokens are issued only through an authenticated Fameverse server path. The current path is the Supabase Edge Function `stream-token`.

## Change-control law

A switch away from Stream Video, the addition of a second native media provider, or a parallel replacement transport requires **explicit product-owner approval before implementation**.

Do not silently substitute LiveKit, Agora, raw WebRTC, or another provider because of SDK friction, debugging difficulty, pricing assumptions, or implementation convenience.

If Stream Video is blocked, stop at the dependency or configuration gate, record the evidence, and request an architecture decision. Do not route around the lock.

## Regression law

Provider work must not modify the already-proven App Store/TestFlight signing path unless there is direct evidence that signing itself is broken. Build 13 established that path on a physical iPhone.

Home, Discover, Profile, authentication, Supabase authority, and approved product UI are separate regression surfaces. Media-provider changes do not authorize redesigns or unrelated rewrites.
