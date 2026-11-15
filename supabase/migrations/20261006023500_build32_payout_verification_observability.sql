drop function if exists public.get_creator_verification_progress();

create function public.get_creator_verification_progress()
returns table(
  verification_status text,
  follower_count bigint,
  follower_requirement bigint,
  eligible_received_coins bigint,
  received_coins_requirement bigint,
  eligible boolean,
  requested_at timestamptz,
  reviewed_at timestamptz,
  public_note text,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_status text := 'unverified';
  v_followers bigint := 0;
  v_received bigint := 0;
  v_requested_at timestamptz;
  v_reviewed_at timestamptz;
  v_public_note text;
  v_updated_at timestamptz;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select
    coalesce(r.status, 'unverified'),
    r.requested_at,
    r.reviewed_at,
    r.public_note,
    r.updated_at
  into
    v_status,
    v_requested_at,
    v_reviewed_at,
    v_public_note,
    v_updated_at
  from (select 1) seed
  left join public.creator_verification_requests r on r.user_id = v_user;

  select count(*)::bigint into v_followers
  from public.follows f
  where f.following_id = v_user;

  select coalesce(sum(funding.cash_backed_coins), 0)::bigint into v_received
  from public.gift_events gift
  join public.gift_funding_breakdowns funding on funding.gift_event_id = gift.id
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
    (v_followers >= 100 and v_received >= 500000)::boolean,
    v_requested_at,
    v_reviewed_at,
    v_public_note,
    v_updated_at;
end;
$$;

revoke all on function public.get_creator_verification_progress() from public;
grant execute on function public.get_creator_verification_progress() to authenticated, service_role;

drop function if exists public.get_creator_payout_requests(integer);

create function public.get_creator_payout_requests(p_limit integer default 20)
returns table(
  payout_id uuid,
  amount_cents bigint,
  status text,
  requested_at timestamptz,
  reviewed_at timestamptz,
  paid_at timestamptz,
  moderation_note text,
  external_reference text,
  provider_status text,
  provider_batch_id text,
  provider_status_updated_at timestamptz
)
language sql
stable
set search_path = public
as $$
  select
    request.id,
    request.amount_cents,
    request.status,
    request.requested_at,
    request.reviewed_at,
    request.paid_at,
    request.moderation_note,
    request.external_reference,
    request.provider_status,
    request.provider_batch_id,
    request.provider_status_updated_at
  from public.creator_payout_requests request
  where request.creator_user_id = auth.uid()
  order by request.requested_at desc
  limit least(greatest(coalesce(p_limit, 20), 1), 100);
$$;

revoke all on function public.get_creator_payout_requests(integer) from public;
grant execute on function public.get_creator_payout_requests(integer) to authenticated, service_role;
