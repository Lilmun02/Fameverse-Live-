-- REVIEW-ONLY SQL: not deployed, not part of a migration until approved.
-- The existing 3-argument gift RPC remains unchanged for existing app builds.
create table if not exists public.live_room_cohosts (
  room_id uuid primary key references public.live_rooms(id) on delete cascade,
  cohost_user_id uuid not null references auth.users(id) on delete cascade,
  activated_at timestamptz,
  updated_at timestamptz not null default now()
);
alter table public.live_room_cohosts enable row level security;
revoke all on public.live_room_cohosts from public, anon, authenticated;

-- The authenticated room host prepares a pending co-host.
create or replace function public.prepare_fameverse_live_cohost(
  p_room_id uuid, p_cohost_user_id uuid
) returns void language plpgsql security definer
set search_path to public, pg_temp as $function$
declare v_host uuid;
begin
  if auth.uid() is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  select host_user_id into v_host from public.live_rooms
  where id = p_room_id and status = 'live' and ended_at is null for share;
  if v_host is null or v_host <> auth.uid() then
    raise exception 'only the room host may prepare a co-host'
      using errcode = '42501';
  end if;
  if p_cohost_user_id is null or p_cohost_user_id = v_host then
    raise exception 'invalid co-host' using errcode = '22023';
  end if;
  insert into public.live_room_cohosts(room_id, cohost_user_id, activated_at)
  values (p_room_id, p_cohost_user_id, null)
  on conflict (room_id) do update
    set cohost_user_id = excluded.cohost_user_id,
        activated_at = null, updated_at = now();
end;
$function$;

-- Pending co-host must personally accept after joining authorized media.
create or replace function public.activate_fameverse_live_cohost(
  p_room_id uuid
) returns void language plpgsql security definer
set search_path to public, pg_temp as $function$
declare v_updated integer;
begin
  if auth.uid() is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  update public.live_room_cohosts c
    set activated_at = now(), updated_at = now()
    where c.room_id = p_room_id and c.cohost_user_id = auth.uid()
      and exists(select 1 from public.live_rooms r
                 where r.id = p_room_id and r.status = 'live'
                   and r.ended_at is null);
  get diagnostics v_updated = row_count;
  if v_updated <> 1 then
    raise exception 'co-host was not approved for an active room'
      using errcode = '42501';
  end if;
end;
$function$;

-- Either participant can revoke a co-host session; idempotent cleanup.
create or replace function public.clear_fameverse_live_cohost(
  p_room_id uuid
) returns void language plpgsql security definer
set search_path to public, pg_temp as $function$
begin
  if auth.uid() is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  delete from public.live_room_cohosts c using public.live_rooms r
    where c.room_id = p_room_id and r.id = c.room_id
      and (r.host_user_id = auth.uid() or c.cohost_user_id = auth.uid());
end;
$function$;

revoke all on function public.prepare_fameverse_live_cohost(uuid,uuid) from public,anon;
revoke all on function public.activate_fameverse_live_cohost(uuid) from public,anon;
revoke all on function public.clear_fameverse_live_cohost(uuid) from public,anon;
grant execute on function public.prepare_fameverse_live_cohost(uuid,uuid) to authenticated;
grant execute on function public.activate_fameverse_live_cohost(uuid) to authenticated;
grant execute on function public.clear_fameverse_live_cohost(uuid) to authenticated;

-- The additive 4-argument RPC retains the proven wallet debit, ledger,
-- gift events, level calculations and cash-backed creator-share transaction.
CREATE OR REPLACE FUNCTION public.send_fameverse_gift(p_room_id uuid, p_gift_id text, p_quantity integer, p_recipient_user_id uuid)
 RETURNS TABLE(total_coins_sent bigint, gift_count bigint, level integer, wallet_balance bigint, cash_backed_coins_spent bigint, promo_coins_spent bigint, creator_earning_micros bigint, owner_promo_bonus_cents bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_temp'
AS $function$
declare
  v_sender uuid := auth.uid();
  v_sender_role text;
  v_recipient uuid;
  v_unit_cost integer;
  v_total bigint;
  v_balance bigint;
  v_gift_event_id uuid;
  v_cash_balance bigint;
  v_promo_balance bigint;
  v_cash_spent bigint;
  v_promo_spent bigint;
  v_creator_micros bigint := 0;
begin
  if v_sender is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > 100000 then
    raise exception 'invalid gift quantity' using errcode = '22023';
  end if;

  select role into v_sender_role
  from public.account_roles
  where user_id = v_sender;

  select gift.cost_coins into v_unit_cost
  from public.fameverse_gift_catalog gift
  where gift.id = p_gift_id and gift.active = true;
  if v_unit_cost is null then
    raise exception 'unknown gift' using errcode = '22023';
  end if;

  select room.host_user_id into v_recipient
  from public.live_rooms room
  where room.id = p_room_id and room.status = 'live' and room.ended_at is null;
  if v_recipient is null then
    raise exception 'live room is not active' using errcode = 'P0002';
  end if;
  if p_recipient_user_id is not null
     and p_recipient_user_id <> v_recipient then
    perform 1 from public.live_room_cohosts c
    where c.room_id = p_room_id
      and c.cohost_user_id = p_recipient_user_id
      and c.activated_at is not null
    for share;
    if not found then
      raise exception 'gift recipient is not the active co-host'
        using errcode = '42501';
    end if;
    v_recipient := p_recipient_user_id;
  end if;
  if v_sender = v_recipient then
    raise exception 'self gifting is not allowed' using errcode = '42501';
  end if;

  v_total := v_unit_cost::bigint * p_quantity::bigint;
  if v_total <= 0 then
    raise exception 'invalid gift total' using errcode = '22023';
  end if;

  perform public._ensure_fame_coin_wallet(v_sender);
  perform pg_advisory_xact_lock(hashtextextended('fv-coin:' || v_sender::text, 0));

  select funding.cash_backed_coins, funding.promo_coins
    into v_cash_balance, v_promo_balance
  from public.coin_funding_balances funding
  where funding.user_id = v_sender
  for update;

  if coalesce(v_sender_role, '') in ('owner', 'admin') then
    -- QA law: ordinary staff gifts are promo-only. They can never silently
    -- fall through to cash-backed coins and create creator payout liability.
    if coalesce(v_promo_balance, 0) < v_total then
      raise exception 'insufficient promotional Fame Coins; refill the testing wallet or use the explicit cash reward flow' using errcode = '22003';
    end if;
    v_promo_spent := v_total;
    v_cash_spent := 0;
  else
    v_promo_spent := least(coalesce(v_promo_balance, 0), v_total);
    v_cash_spent := v_total - v_promo_spent;
    if coalesce(v_cash_balance, 0) < v_cash_spent then
      raise exception 'insufficient Fame Coin balance' using errcode = '22003';
    end if;
  end if;

  insert into public.gift_events (
    room_id, sender_user_id, recipient_user_id, gift_id, quantity, coins_spent
  ) values (
    p_room_id, v_sender, v_recipient, p_gift_id, p_quantity, v_total
  ) returning id into v_gift_event_id;

  v_balance := public._credit_fame_coins(
    v_sender, -v_cash_spent, -v_promo_spent, 'gift_send',
    'gift-send:' || v_gift_event_id::text
  );

  update public.coin_funding_ledger
  set gift_event_id = v_gift_event_id
  where event_key = 'gift-send:' || v_gift_event_id::text;

  insert into public.beta_coin_ledger (
    user_id, delta, balance_after, event_type, gift_event_id
  ) values (
    v_sender, -v_total, v_balance, 'gift_send', v_gift_event_id
  );

  insert into public.gifter_stats (
    user_id, total_coins_sent, gift_count, level, updated_at
  ) values (
    v_sender, v_total, p_quantity, public.compute_gifter_level(v_total), now()
  )
  on conflict (user_id) do update set
    total_coins_sent = public.gifter_stats.total_coins_sent + excluded.total_coins_sent,
    gift_count = public.gifter_stats.gift_count + excluded.gift_count,
    level = public.compute_gifter_level(
      public.gifter_stats.total_coins_sent + excluded.total_coins_sent
    ),
    updated_at = now();

  if v_cash_spent > 0 then
    v_creator_micros := public._apply_creator_cash_coin_share(
      v_gift_event_id, v_cash_spent
    );
  end if;

  insert into public.gift_funding_breakdowns (
    gift_event_id, cash_backed_coins, promo_coins, creator_earning_cents,
    creator_earning_micros, funding_rule
  ) values (
    v_gift_event_id, v_cash_spent, v_promo_spent,
    (v_creator_micros / 10000)::bigint, v_creator_micros,
    case when coalesce(v_sender_role, '') in ('owner', 'admin')
      then 'staff_promo_only_zero_earnings'
      else 'promo_first_cash_backed_earnings'
    end
  );

  return query
  select stats.total_coins_sent, stats.gift_count, stats.level, v_balance,
         v_cash_spent, v_promo_spent, v_creator_micros, 0::bigint
  from public.gifter_stats stats
  where stats.user_id = v_sender;
end;
$function$;

revoke all on function public.send_fameverse_gift(uuid,text,integer,uuid)
  from public,anon;
grant execute on function public.send_fameverse_gift(uuid,text,integer,uuid)
  to authenticated;
