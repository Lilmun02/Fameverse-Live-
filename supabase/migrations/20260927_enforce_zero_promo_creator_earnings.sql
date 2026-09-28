begin;

-- Current Fameverse policy: promotional/test/referral Fame Coins are engagement
-- currency only. They may be spent on gifts, but they never create creator cash
-- earnings. Only the cash-backed portion of a gift participates in the locked
-- 70/30 creator/platform split. The legacy owner_promo_bonus_cents return field
-- stays for client compatibility and is always zero for new sends.
create or replace function public.send_fameverse_gift(
  p_room_id uuid,
  p_gift_id text,
  p_quantity integer
)
returns table (
  total_coins_sent bigint,
  gift_count bigint,
  level integer,
  wallet_balance bigint,
  cash_backed_coins_spent bigint,
  promo_coins_spent bigint,
  creator_earning_micros bigint,
  owner_promo_bonus_cents bigint
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_sender uuid := auth.uid();
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

  select gift.cost_coins into v_unit_cost
  from public.fameverse_gift_catalog gift
  where gift.id = p_gift_id and gift.active = true;

  if v_unit_cost is null then
    raise exception 'unknown gift' using errcode = '22023';
  end if;

  select room.host_user_id into v_recipient
  from public.live_rooms room
  where room.id = p_room_id
    and room.status = 'live'
    and room.ended_at is null;

  if v_recipient is null then
    raise exception 'live room is not active' using errcode = 'P0002';
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

  -- Keep one visible balance while spending promotional coins first. Funding
  -- provenance remains private and authoritative in the backend.
  v_promo_spent := least(coalesce(v_promo_balance, 0), v_total);
  v_cash_spent := v_total - v_promo_spent;

  if coalesce(v_cash_balance, 0) < v_cash_spent then
    raise exception 'insufficient Fame Coin balance' using errcode = '22003';
  end if;

  insert into public.gift_events (
    room_id, sender_user_id, recipient_user_id, gift_id, quantity, coins_spent
  ) values (
    p_room_id, v_sender, v_recipient, p_gift_id, p_quantity, v_total
  ) returning id into v_gift_event_id;

  v_balance := public._credit_fame_coins(
    v_sender,
    -v_cash_spent,
    -v_promo_spent,
    'gift_send',
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

  -- Only cash-backed coins create creator earnings. Promotional/test/referral
  -- coins intentionally create zero creator cash liability.
  if v_cash_spent > 0 then
    v_creator_micros := public._apply_creator_cash_coin_share(
      v_gift_event_id,
      v_cash_spent
    );
  end if;

  insert into public.gift_funding_breakdowns (
    gift_event_id,
    cash_backed_coins,
    promo_coins,
    creator_earning_cents,
    creator_earning_micros,
    funding_rule
  ) values (
    v_gift_event_id,
    v_cash_spent,
    v_promo_spent,
    (v_creator_micros / 10000)::bigint,
    v_creator_micros,
    'promo_first_zero_promo_earnings'
  );

  return query
  select
    stats.total_coins_sent,
    stats.gift_count,
    stats.level,
    v_balance,
    v_cash_spent,
    v_promo_spent,
    v_creator_micros,
    0::bigint
  from public.gifter_stats stats
  where stats.user_id = v_sender;
end;
$$;

comment on function public.send_fameverse_gift(uuid,text,integer) is
  'Authoritative gift send: promo-first spend; promo/test/referral coins create zero creator earnings; cash-backed coins use locked 70/30; self-gift blocked.';

commit;
