# Build 48 — backend-only release staging (review gate)

**Status: started, isolated; NOT deployed, merged, built, or published.**

## Frozen product scope
Build 48 is reserved for existing server/backend bug patches and regression
locks. Do not add front-end controls, Live layouts, Liquid Glass, gifts,
wallet changes, new product features, or creator-payout functionality.
Do not touch Apple/Android signing, CodeMagic/TestFlight workflows, or
Vercel web deployments while servicing these backend defects.

The future iOS Liquid Glass candidate remains independently saved in
draft PR #122 and is NOT to be included in Build 48.

## First specific defect (Stream token)
The `stream-token` Edge Function authorized a new viewer token solely on
`live_rooms.status='live'`. A room can retain this status after its host
heartbeat expires. Production SELECT-only baseline, November 13:
1 `live` record, 0 heartbeat-fresh, 1 stale. No live data was changed.

Fix: check `heartbeat_at` using the established 45-second presence rule
before issuing NEW viewer JWTs. Allow 30 seconds of future clock skew,
reject absent/malformed/far-future values, and return HTTP 409
`room-presence-expired`. Host token logic is unchanged for recovery,
including the existing policy gate.

## Evidence and outstanding checks
- Twelve pure helper boundary tests PASSED locally under Node 22 using
  TypeScript stripping. The committed Vitest tests extend those checks
  with a source-level verification that the viewer gate precedes signing.
- Edge bundle, `npm run verify`, Deno/Supabase integration, authenticated
  host/viewer reconnection on real iPhones, and CodeMagic are NOT run here.
- New viewer tokens for stale rooms are rejected, but existing tokens are
  not revoked; native discovery might still list stale cards until its
  own separately authorized fix. No broad claim of ghost-room elimination.

No Edge deploy, production DB write, schema/RLS change, Stripe/PayPal, payout,
native UI, or TestFlight action. Keep fix on its own branch, review one
repair at a time, require CEO approval for each merge or deployment.
