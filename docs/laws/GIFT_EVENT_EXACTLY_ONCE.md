# Fameverse Law — Gift Event Exactly Once
**Status:** OWNER REQUESTED, review-only until tests and backend changes approved. Issue: #60.

## Nonnegotiable invariant
A successful **one-gift** intent creates precisely one accepted backend gift event, precisely one wallet debit and applicable creator share calculation, exactly one observer activity message, and exactly one queued cinematic playback per observer. Retried delivery of that **same** accepted event must never replay, double-debit, double-credit creator earnings, or double-render emotes/subtitles. A genuinely distinct accepted gift with the same product ID remains valid and must play as the next queued event.

A user-intended quantity/combo (×5, ×10, custom) is one logical purchase request with authoritative quantity and ledger charge, with intentional serialized visual subevents showing combo indices; it is **not** a second accidental gift send or accidental video replay. Do not dedupe distinct combo entries by gift ID.

## Server authority
Client generates stable unique request ID per user intent and reuses it on timeout retry. Backend enforces unique `(authenticated_sender, request_id)` or equivalent, atomically binds request to wallet debit, gift event, cash/promo allocation and creator share, returns same result on repeat. Store server event ID and pass it to realtime/chat/renderers. Do not implement this as a frontend-only flag or time-window heuristic.

**Current state / stop gate:** deployed `send_fameverse_gift(p_room_id,p_gift_id,p_quantity)` takes no request ID and creates a new gift event on each accepted call. Production schema/payment RPC changes need a separate reviewed migration, sandbox fake-money verification and CEO approval.

## Playback / image / UI
- Only one media/audio source for one accepted cinematic event per client, no parallel echo or 2x render.
- Each event transitions QUEUED → ACTIVE → FINISHED exactly once. One on-ended completion advances one item; an optional timeout is a recovery condition, not a shorter replacement for approved media duration.
- Previous event video/audio and art fully clean before next begins; no stale previous frame, flicker, double chat, default emote or visible subtitle beneath cinematic. Preserve media duration, original sound and approved watermark.
- Low-cost under-100 coins never spin up premium cinematic audio/video.
- A failed/declined backend transaction never renders as accepted or contributes creator payout/ranks; owner/test promotions remain distinguishable.

## Regression cases (each platform)
(1) One accepted single gift, (2) same network event delivered twice, (3) timed-out request retried with same id, (4) two legitimate separate sends of same gift, (5) ×5 and ×10 combos charged correctly, (6) rapid different gift queue, (7) viewer joins mid-playback/reconnect, (8) two devices same host/viewer, (9) animation/audio all the way to end, (10) promo-only never payable, (11) network/error/rejected balance with no ghost visuals, (12) host Live end clears queue.
Measure counts: ledger debits, gift_events IDs, realtime notifications, chat, queued playback, rendering, eventual payout eligibility.

FAIL in any scenario blocks release. Fix candidate != iPhone PASS. Separate independent issue, PR, reproducible test and rollback per client/backend.
