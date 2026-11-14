-- Remove the legacy owner-only fake pending verification state when the real
-- owner-approved eligibility requirements are not met. This does not touch a
-- legitimately eligible pending request.

with owner_metrics as (
  select
    role_row.user_id,
    (select count(*)::bigint
       from public.follows f
      where f.following_id = role_row.user_id) as follower_count,
    (select coalesce(sum(funding.cash_backed_coins), 0)::bigint
       from public.gift_events gift
       join public.gift_funding_breakdowns funding
         on funding.gift_event_id = gift.id
      where gift.recipient_user_id = role_row.user_id
        and gift.sender_user_id is not null
        and gift.sender_user_id <> gift.recipient_user_id
        and funding.cash_backed_coins > 0) as eligible_received_coins
  from public.account_roles role_row
  where role_row.role = 'owner'
)
update public.creator_verification_requests request
set status = 'unverified',
    requested_at = null,
    reviewed_at = null,
    reviewed_by = null,
    public_note = null,
    updated_at = now()
from owner_metrics metrics
where request.user_id = metrics.user_id
  and request.status = 'pending'
  and (
    metrics.follower_count < 100
    or metrics.eligible_received_coins < 500000
  );
