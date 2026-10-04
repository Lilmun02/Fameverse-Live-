-- Build 32 creator verification eligibility repair.
-- Verification requests are unlocked by owner-approved requirements only:
-- 100 followers + 500,000 legitimate cash-backed Fame Coins received.
-- Promo/referral/QA gift funding does not count toward verification eligibility.

create or replace function public.get_creator_verification_progress()
returns table(
  verification_status text,
  follower_count bigint,
  follower_requirement bigint,
  eligible_received_coins bigint,
  received_coins_requirement bigint,
  eligible boolean
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $function$
declare
  v_user uuid := auth.uid();
  v_status text;
  v_followers bigint := 0;
  v_received bigint := 0;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select coalesce(r.status, 'unverified')
    into v_status
  from (select 1) seed
  left join public.creator_verification_requests r on r.user_id = v_user;

  select count(*)::bigint
    into v_followers
  from public.follows f
  where f.following_id = v_user;

  select coalesce(sum(funding.cash_backed_coins), 0)::bigint
    into v_received
  from public.gift_events gift
  join public.gift_funding_breakdowns funding
    on funding.gift_event_id = gift.id
  where gift.recipient_user_id = v_user
    and gift.sender_user_id is not null
    and gift.sender_user_id <> gift.recipient_user_id
    and funding.cash_backed_coins > 0;

  return query
  select
    coalesce(v_status, 'unverified')::text,
    v_followers,
    100::bigint,
    v_received,
    500000::bigint,
    (v_followers >= 100 and v_received >= 500000)::boolean;
end;
$function$;

create or replace function public.request_creator_verification()
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_user uuid := auth.uid();
  v_status text;
  v_followers bigint := 0;
  v_received bigint := 0;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select status into v_status
  from public.creator_verification_requests
  where user_id = v_user;

  if v_status = 'verified' then
    return 'verified';
  end if;

  if v_status = 'suspended' then
    raise exception 'verification is suspended and cannot be requested right now' using errcode = '42501';
  end if;

  select count(*)::bigint
    into v_followers
  from public.follows f
  where f.following_id = v_user;

  select coalesce(sum(funding.cash_backed_coins), 0)::bigint
    into v_received
  from public.gift_events gift
  join public.gift_funding_breakdowns funding
    on funding.gift_event_id = gift.id
  where gift.recipient_user_id = v_user
    and gift.sender_user_id is not null
    and gift.sender_user_id <> gift.recipient_user_id
    and funding.cash_backed_coins > 0;

  if v_followers < 100 or v_received < 500000 then
    raise exception 'verification eligibility requires 100 followers and 500000 eligible Fame Coins received' using errcode = '22023';
  end if;

  insert into public.creator_verification_requests (
    user_id,
    status,
    requested_at,
    reviewed_at,
    reviewed_by,
    public_note,
    updated_at
  ) values (
    v_user,
    'pending',
    now(),
    null,
    null,
    null,
    now()
  )
  on conflict (user_id) do update set
    status = case
      when creator_verification_requests.status in ('verified', 'suspended')
        then creator_verification_requests.status
      else 'pending'
    end,
    requested_at = case
      when creator_verification_requests.status in ('verified', 'suspended')
        then creator_verification_requests.requested_at
      else now()
    end,
    reviewed_at = case
      when creator_verification_requests.status in ('verified', 'suspended')
        then creator_verification_requests.reviewed_at
      else null
    end,
    reviewed_by = case
      when creator_verification_requests.status in ('verified', 'suspended')
        then creator_verification_requests.reviewed_by
      else null
    end,
    public_note = case
      when creator_verification_requests.status in ('verified', 'suspended')
        then creator_verification_requests.public_note
      else null
    end,
    updated_at = now()
  returning status into v_status;

  return v_status;
end;
$function$;

revoke all on function public.get_creator_verification_progress() from public;
revoke all on function public.get_creator_verification_progress() from anon;
grant execute on function public.get_creator_verification_progress() to authenticated;
grant execute on function public.get_creator_verification_progress() to service_role;

revoke all on function public.request_creator_verification() from public;
revoke all on function public.request_creator_verification() from anon;
grant execute on function public.request_creator_verification() to authenticated;
grant execute on function public.request_creator_verification() to service_role;
