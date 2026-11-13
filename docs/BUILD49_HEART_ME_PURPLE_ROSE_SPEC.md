# Fameverse Live — Build 49 feature reservation (SPEC ONLY)

**Owner decision, November 13, 2026:** Reserve the Heart Me feature
and the creator-name bubble's purple-heart presentation for **Build 49**.
This file is a product requirements record, NOT an implementation,
release approval, backend migration, or production configuration change.

## Feature 1: Creator oval name bubble / Fame Taps

- Show the creator's name in the existing oval-shaped bubble.
- Directly underneath their name, show the creator's LIVE Fame Taps total
  using Fameverse-branded **purple heart** iconography.
- Free Fame Taps remain separate from real-money gifts and from Heart Me.
- Display real verified tap counts using the existing legitimate Fame Taps
  backend. Never invent counts, grant free coins, or double count.
- Keep long creator names truncated and preserve full-screen Live layout.
- No platform-specific replica of another app's branding.

## Feature 2: Heart Me / daily Purple Rose

- Viewer must FOLLOW the creator first. The server, not a client flag,
  validates the follow relationship at time of redemption.
- After following, the viewer may choose to support that creator through
  **Heart Me** with a **Purple Rose** gift.
- Owner-requested value: **USD $0.01 per Purple Rose**.
- Proposed default pending owner sign-off: one manual Purple Rose send
  per follower, per creator, per UTC calendar day; no automatic charge
  or recurring subscription. No user is charged absent a deliberate tap
  and a successful, confirmed wallet debit.
- Use a dedicated original Fameverse-branded purple rose asset. Follow
  existing small-gift rules: compact visual, no disruptive cinematic
  animation, no duplicate audio, accurate sender name, and watermark
  if using custom media.
- Atomic balance debit, gift receipt and one-per-day eligibility check
  must be idempotent and checked server-side. Handle failure/refund,
  concurrency, insufficient funds and follow/unfollow races correctly.
- Never silently translate $0.01 into a coin amount: define the actual
  coin denomination, wallet accounting, revenue split and settlement
  economics only after confirming the existing financial configuration.
- **Policy conflict to resolve before coding:** prior owner rule
  discouraged NEW gifts valued below $0.10. The Purple Rose is an
  owner-requested $0.01 exception candidate; document and explicitly
  approve the exception before release rather than silently changing
  the entire gift catalog's minimum.
- Design the actual Heart Me label and distinction from free Fame Taps
  so users do not confuse likes with purchases.

## Explicitly OUT of Build 49 unless separately authorized

- Build 48 backend-only security, heartbeat and reliability fixes remain
  on their own isolated staging and repair branches.
- iOS 27 native Liquid Glass is held separately in draft PR #122.
- Sleep Lives require at least 100 signed-up accounts and creator
  eligibility, with the 10k/month qualifying metric still undefined.
  That feature remains a later separately planned release.
- The swipe-in Live Dashboard with elapsed time and active viewers is
  a separate proposed feature and is NOT silently included here.
- No payouts or financial reserves are enabled by this record.

## Release and workflow law

1. Design and approve requirements (including the 1-cent gift exception).
2. One isolated implementation branch per coherent repair or feature.
3. Regression locks, account-isolation, abuse and wallet-ledger testing.
4. Flutter compile/analyze/tests plus two-device iOS/Android Live QA.
5. Owner authorizes each merge, migration, build, signing, TestFlight
   distribution and production action separately.

No source code, Live backend, Stripe, Supabase, workflows or real funds
are changed by this specification. Build 49 has NOT been assembled,
built, tested or submitted.
