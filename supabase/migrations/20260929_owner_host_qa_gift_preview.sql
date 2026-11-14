create or replace function public.record_beta_gift(
  p_room_id uuid,
  p_gift_id text,
  p_quantity integer
)
returns table(
  total_coins_sent bigint,
  gift_count bigint,
  level integer,
  wallet_balance bigint
)
language plpgsql
security definer
set search_path to 'public', 'pg_temp'
as $function$
declare
  v_sender uuid := auth.uid();
  v_role text;
  v_recipient uuid;
  v_unit_cost integer;
  v_total bigint;
  v_promo_balance bigint;
  v_balance bigint;
  v_event_key text;
begin
  if v_sender is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select role_row.role into v_role
  from public.account_roles role_row
  where role_row.user_id = v_sender;

  if coalesce(v_role, '') not in ('owner', 'admin') then
    raise exception 'beta gift sending requires owner or admin role' using errcode = '42501';
  end if;

  if p_quantity is null or p_quantity < 1 or p_quantity > 100000 then
    raise exception 'invalid gift quantity' using errcode = '22023';
  end if;

  select room.host_user_id into v_recipient
  from public.live_rooms room
  where room.id = p_room_id
    and room.status = 'live'
    and room.ended_at is null;

  if v_recipient is null then
    raise exception 'live room is not active' using errcode = 'P0002';
  end if;

  if v_recipient <> v_sender then
    return query
    select result.total_coins_sent, result.gift_count, result.level, result.wallet_balance
    from public.send_fameverse_gift(p_room_id, p_gift_id, p_quantity) result;
    return;
  end if;

  select gift.cost_coins into v_unit_cost
  from public.fameverse_gift_catalog gift
  where gift.id = p_gift_id and gift.active = true;

  if v_unit_cost is null then
    raise exception 'unknown gift' using errcode = '22023';
  end if;

  v_total := v_unit_cost::bigint * p_quantity::bigint;
  if v_total <= 0 then
    raise exception 'invalid gift total' using errcode = '22023';
  end if;

  perform public._ensure_fame_coin_wallet(v_sender);
  perform pg_advisory_xact_lock(hashtextextended('fv-coin:' || v_sender::text, 0));

  select funding.promo_coins into v_promo_balance
  from public.coin_funding_balances funding
  where funding.user_id = v_sender
  for update;

  if coalesce(v_promo_balance, 0) < v_total then
    raise exception 'insufficient promotional Fame Coins; refill the testing wallet' using errcode = '22003';
  end if;

  v_event_key := 'host-qa-gift-preview:' || gen_random_uuid()::text;
  v_balance := public._credit_fame_coins(
    v_sender,
    0,
    -v_total,
    'host_qa_gift_preview',
    v_event_key
  );

  insert into public.beta_coin_ledger(
    user_id,
    delta,
    balance_after,
    event_type
  ) values (
    v_sender,
    -v_total,
    v_balance,
    'gift_send'
  );

  insert into public.gifter_stats(
    user_id,
    total_coins_sent,
    gift_count,
    level,
    updated_at
  ) values (
    v_sender,
    v_total,
    p_quantity,
    public.compute_gifter_level(v_total),
    now()
  )
  on conflict (user_id) do update set
    total_coins_sent = public.gifter_stats.total_coins_sent + excluded.total_coins_sent,
    gift_count = public.gifter_stats.gift_count + excluded.gift_count,
    level = public.compute_gifter_level(
      public.gifter_stats.total_coins_sent + excluded.total_coins_sent
    ),
    updated_at = now();

  return query
  select stats.total_coins_sent,
         stats.gift_count,
         stats.level,
         v_balance
  from public.gifter_stats stats
  where stats.user_id = v_sender;
end;
$function$;

revoke all on function public.record_beta_gift(uuid, text, integer) from public, anon;
grant execute on function public.record_beta_gift(uuid, text, integer) to authenticated;
