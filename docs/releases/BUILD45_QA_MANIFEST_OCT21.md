# Fameverse Live — Build 45 QA source manifest (October 21, 2026)

**Status: INTERNAL QA CANDIDATE ONLY — NOT SIGNED, NOT UPLOADED, NOT RELEASE APPROVED.**
Current owner-reported installed baseline: TestFlight Build 44. The Build 44 IPA source SHA
has not been independently identified; no release of this candidate is authorized until
its source is reconciled against Build 44 to avoid overwriting newer repairs.

## Source and authorized scope

- QA branch: `release-candidate/build45-safe-native-oct21`
- Starting source: `feature/verse-pioneer-profile-oct11@b4cae76a02b99f0ec8c74235326287a94b1970a1`
- This preserves Pioneer/First Verse profile changes and Codemagic's exact triggering
  commit checkout, rather than the old hardcoded integration checkout.
- Selected native repair source: draft PR #86 @ `244430d02cbcc7c0d5063aff4d2463978f432b25`
  and its stacked PR #88 @ `034b45375ab395bb61eebd335087426a2f48a983`.
- Integrated in this candidate: host/cohost camera operation serialization,
  two-person layout dimensions, active Live room discovery refresh, compact and
  silent gifts under 100 coins, and consecutive premium combo-video replay.
- Not changed: native signing keys, app bundle identifier, creator payouts, Stripe
  Checkout/webhooks, wallet, coin prices, database, server functions or TestFlight
  publishing workflow. No new workflow, install link, or production configuration.

## Tests and remaining blockers

- PR #86 earlier: Flutter analysis/tests, Android debug and unsigned iOS compile
  passed; **physical iPhone release gate failed**.
- PR #88 engineering gate passed; not proof of actual five complete videos or
  a payment ledger transaction.
- Exact Build45 QA SHA must pass native preflight after any commits.
- Prove camera flip spam, cohost audio and reconnection, room browsing/swiping,
  multiple simultaneous senders, FIFO 1/5...5/5 playback, real video
  completion with audio, receipt deduplication and server-authoritative debits.
- Owner illustration: 5 gifts at 5,000 coins each account for 25,000 coins,
  five full sequential presentations. **Do not change the actual Dragon catalog cost.**
- Codemagic must report the signed IPA source SHA and Apple TestFlight upload;
  GitHub green alone cannot prove this.
- Current Codemagic Build number is provider-assigned; not inferred from old
  `FAMEVERSE_BUILD_FAMILY` strings in source.

## Separate workstreams, intentionally not folded in

- Policy access control: Build45 policy review PR #90; staging SQL inactive,
  production backend currently has no policy-decision table. Do not activate
  before approved migration, native CI, privacy/legal and feature-gate QA.
- Manus Stripe safety proposal: GitHub issue #60 comment #6324825201 describes
  a local uncommitted fix. Do not merge/deploy an unseen diff or enable live
  purchases without sandbox webhook/one-wallet-credit proof.
- Apple repeat-IAP, web Stripe buy caller and creator PayPal payouts: remain
  open until separate tested implementation and owner approval.
- Private Inbox PR #81 remains separate, draft and unaudited for account isolation.

## Owner release boundaries

No auto-merge of draft repair PRs, no production database writes or payment events,
no signing/configuration changes, no CI gate bypass, and no external TestFlight
promotion without an explicitly approved, source-identified internal build and
physical owner/tester acceptance.
