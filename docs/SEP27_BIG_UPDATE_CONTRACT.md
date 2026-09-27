# Fameverse Sep 27 Big Update Contract

Status: approved product scope; implementation must still pass automated and physical-device gates before release.

This contract extends, and never overrides, `docs/ENGINEERING_CONSTITUTION.md`.

## Product scope

The update is intentionally broad at the product level, but engineering work must still ship as isolated feature/repair branches and be integrated only after each slice passes its own gates.

Approved update areas:
- Live V2 stability and regression repair.
- Streaming-first Home and intentional Discover improvements.
- Profile and Settings cleanup, including privacy, safety and legal surfaces.
- Creator Studio, creator verification, moderation and analytics foundations.
- Creator Stories V1: photo/short-video stories, 24-hour expiry, story ring/viewer, basic view count and delete.
- Creator earnings and PayPal payout flow with $25 minimum available balance.
- Recharge pricing cleanup and Coin Exchange.
- Gifter/creator progression and badges.
- `First Verse` external beta-tester badge earned through actual testing missions.
- External beta-tester referrals and promotional coin rewards.
- Approximately 50 additional lightweight low-cost gifts below 100 coins; no cinematic audio/video requirement for these gifts.
- Medium maintenance/performance work: faster browsing, pagination/lazy loading where appropriate, cache-friendly media behavior, query/index review, stale listener cleanup and reduced unnecessary rebuilds.
- Owner Control Panel remains private/internal and must never be exposed in public UI, public release notes or ordinary tester-facing surfaces.

## External beta mission law

- `First Verse` is earned, never automatically granted for accepting an invite.
- The tester sees a progress bar and a visually locked/blurred badge teaser until the required missions are completed.
- Missions test normal user-facing features only.
- Payouts, payout approval, production payment-provider verification, owner/admin controls and other real-cash operational flows are explicitly excluded from external-tester missions.
- A tester may have optional/bonus missions; required badge progress must not depend on recruiting other users.
- Once legitimately earned, `First Verse` is permanent and cannot be purchased later.

## Referral reward law

- A qualified external-beta referral grants 100 promotional Fame Coins to the referring tester and 50 promotional Fame Coins to the referred user.
- Qualification must be backend-authoritative and must not reward a bare download alone.
- Promotional Fame Coins may appear in the same visible Fame Coin balance as other coins.
- Funding source remains separate in backend accounting.
- Promotional coins cannot be transferred wallet-to-wallet, sold, refunded for cash, transformed into Creator Earnings, used for Coin Exchange, withdrawn or cashed out.
- Gifts funded by referral/promotional coins create the normal visible gift/engagement experience but generate $0 Creator Earnings.
- Purchased/cash-backed portions of mixed-funded gifts remain eligible for the normal creator share.

## Gift funding classes

Backend accounting must distinguish at least:
1. cash-backed/purchased coins;
2. promotional/referral coins;
3. owner/admin promotional gift funding.

The client may show one Fame Coin balance, but the backend must never lose the funding-source distinction.

Owner/admin promotional gifts do not inherit the ordinary full face-value creator payout. A small explicit promotional creator bonus may be funded separately (for example one cent or five cents depending on the approved gift rule). It must be disclosed in Creator Studio activity as a promotional gift/bonus rather than masquerading as an ordinary paid gift.

Ordinary paid gifts remain governed by the configured creator/platform split. The currently deployed economy config remains 70/30 until the owner explicitly approves a different production split; discussion of 80/20 is not authorization to mutate the live split.

## Coin value and Coin Exchange

- Gift face-value accounting remains 100 Fame Coins = $1.00 gross gift value.
- Purchased coin packs may carry a retail premium above face value; exact production pack prices require final owner approval before launch.
- Coin Exchange is one-way: Creator Earnings -> Fame Coins.
- Exchange rate: $1.00 of available Creator Earnings -> 100 Fame Coins.
- No second creator/platform split is taken during Coin Exchange.
- Only cleared Available Creator Earnings may be exchanged; pending or payout-reserved money cannot be exchanged.
- Fame Coins -> Creator Earnings is forbidden.
- Exchange must be atomic and idempotent: debit earnings and credit coins together or do neither.

## Payout law

- PayPal first.
- Sandbox remains mandatory until end-to-end fake-money proof passes.
- $25.00 minimum uses Available cleared Creator Earnings only.
- $24.99 must fail; exactly $25.00 may request payout.
- Payout reservations must block replay/double payout.
- External beta testers do not perform payout QA as a badge mission.
- Production PayPal/live-money testing occurs only after Sandbox passes.

## Gift regression gate

The historic black-frame/stale-state/flicker gift bug is a release blocker if it returns.

Physical QA for any gift-path change must cover at least:
- single gift;
- rapid repeated gifts;
- 5x/10x combo behavior;
- different gifts back-to-back;
- tray close/reopen;
- co-host start/end interactions;
- camera flip and camera off/on while gifts are active;
- app background/foreground recovery;
- creator-side receipt;
- multiple senders;
- no black poster frame;
- no thumbnail/image flicker;
- no stale previous gift;
- no stuck playback;
- no duplicate chat event;
- no camera shutdown caused by gift playback.

A failure in any required scenario keeps the gift path in OPEN/REOPENED or FIX_CANDIDATE state. It is not LOCKED.

## Low-cost gift catalog

- Add roughly 50 low-cost gifts priced from 1 to 99 coins.
- These are lightweight/static art gifts, optionally with a small native pop/scale/sparkle effect.
- They should not each spin up cinematic video/audio playback.
- Existing premium/cinematic gifts remain visually special.
- Catalog expansion may not weaken gift regression guards.

## Stories V1 scope limit

V1 includes:
- photo or short-video story post;
- 24-hour expiry;
- active-story profile ring;
- sequential story viewer;
- basic view count;
- creator delete.

Not in V1 unless separately approved later: story DMs, gifting inside Stories, music editing, polls, filters, stickers, reposts or a full editing suite.

## Release discipline

- Build work in isolated branches by subsystem/feature.
- Do not weaken existing regression laws to make CI green.
- A green CI run is not physical acceptance.
- Keep the last known-good candidate available for rollback.
- Do not move external testers off their known build until a new candidate actually deserves outside testing.
- Never label the update fixed, stable, locked, released or production-ready without evidence for the exact build/commit.