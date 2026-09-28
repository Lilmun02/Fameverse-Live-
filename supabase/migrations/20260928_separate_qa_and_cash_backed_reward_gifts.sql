create or replace function public.owner_allocate_reward_reserve(
  p_amount_cents bigint,
  p_note text default null
)
returns bigint
language plpgsql
security definer
set search_path = 'public', 'pg_temp'
as $$
declare
  v_owner uuid := auth.uid();
  v_balance bigint;
begin
  if not exists (
    select 1 from public.account_roles r
    where r.user_id = v_owner and r.role = 'owner'
  ) then
    raise exception 'owner access required' using errcode = '42501';
  end if;

  if p_amount_cents is null or p_amount_cents <= 0 then
    raise exception 'reward reserve amount must be positive' using errcode = '22023';
  end if;

  if p_note is not null and char_length(p_note) > 500 then
    raise exception 'reward reserve note too long' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('fameverse-cash-reward-reserve', 0));

  update public.cash_reward_reserve
  set available_gross_cents = available_gross_cents + p_amount_cents,
      lifetime_allocated_gross_cents = lifetime_allocated_gross_cents + p_amount_cents,
      updated_at = now(),
      updated_by = v_owner
  where id = true
  returning available_gross_cents into v_balance;

  insert into public.cash_reward_reserve_ledger (
    delta_gross_cents,
    balance_after_gross_cents,
    event_type,
    actor_user_id,
    note
  ) values (
    p_amount_cents,
    v_balance,
    'allocate_funds',
    v_owner,
    nullif(trim(coalesce(p_note, '')), '')
  );

  return v_balance;
end;
$$;

create or replace function public.owner_issue_cash_backed_reward_coins(
  p_coins bigint,
  p_note text default null
)
returns table(
  wallet_balance bigint,
  issued_cash_backed_coins bigint,
  reserved_gross_cents bigint,
  reserve_remaining_gross_cents bigint
)
language plpgsql
security definer
set search_path = 'public', 'pg_temp'
as $$
declare
  v_owner uuid := auth.uid();
  v_coins_per_usd integer;
  v_required_cents bigint;
  v_reserve_after bigint;
  v_wallet_after bigint;
  v_event_key text;
begin
  if not exists (
    select 1 from public.account_roles r
    where r.user_id = v_owner and r.role = 'owner'
  ) then
    raise exception 'owner access required' using errcode = '42501';
  end if;

  if p_coins is null or p_coins <= 0 or p_coins > 1000000 then
    raise exception 'cash-backed reward coin amount must be between 1 and 1000000' using errcode = '22023';
  end if;

  if p_note is not null and char_length(p_note) > 500 then
    raise exception 'reward funding note too long' using errcode = '22023';
  end if;

  select coins_per_usd into v_coins_per_usd
  from public.fameverse_economy_config
  where id = true;

  if coalesce(v_coins_per_usd, 0) <= 0 then
    raise exception 'invalid economy configuration' using errcode = '22023';
  end if;

  v_required_cents := ((p_coins * 100) + v_coins_per_usd - 1) / v_coins_per_usd;

  perform pg_advisory_xact_lock(hashtextextended('fameverse-cash-reward-reserve', 0));

  update public.cash_reward_reserve
  set available_gross_cents = available_gross_cents - v_required_cents,
      updated_at = now(),
      updated_by = v_owner
  where id = true
    and available_gross_cents >= v_required_cents
  returning available_gross_cents into v_reserve_after;

  if v_reserve_after is null then
    raise exception 'insufficient funded cash reward reserve' using errcode = '22003';
  end if;

  v_event_key := 'owner-cash-reward-funding:' || gen_random_uuid()::text;
  v_wallet_after := public._credit_fame_coins(
    v_owner,
    p_coins,
    0,
    'owner_cash_reward_funding',
    v_event_key
  );

  insert into public.beta_coin_ledger (
    user_id,
    delta,
    balance_after,
    event_type
  ) values (
    v_owner,
    p_coins,
    v_wallet_after,
    'cash_reward_funding'
  );

  insert into public.cash_reward_reserve_ledger (
    delta_gross_cents,
    balance_after_gross_cents,
    event_type,
    actor_user_id,
    note
  ) values (
    -v_required_cents,
    v_reserve_after,
    'issue_cash_backed_reward_coins',
    v_owner,
    nullif(trim(coalesce(p_note, '')), '')
  );

  return query
  select v_wallet_after, p_coins, v_required_cents, v_reserve_after;
end;
$$;

revoke all on function public.owner_issue_cash_backed_reward_coins(bigint, text) from public, anon, authenticated;
grant execute on function public.owner_issue_cash_backed_reward_coins(bigint, text) to authenticated;

create or replace function public.send_fameverse_gift(
  p_room_id uuid,
  p_gift_id text,
  p_quantity integer
)
returns table(
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
set search_path = 'public', 'pg_temp'
as $$
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
$$;

create or replace function public.send_fameverse_cash_reward_gift(
  p_room_id uuid,
  p_gift_id text,
  p_quantity integer
)
returns table(
  total_coins_sent bigint,
  gift_count bigint,
  level integer,
  wallet_balance bigint,
  cash_backed_coins_spent bigint,
  creator_earning_micros bigint
)
language plpgsql
security definer
set search_path = 'public', 'pg_temp'
as $$
declare
  v_sender uuid := auth.uid();
  v_sender_role text;
  v_enabled boolean := false;
  v_max_gross_cents bigint := 0;
  v_recipient uuid;
  v_unit_cost integer;
  v_total bigint;
  v_balance bigint;
  v_cash_balance bigint;
  v_gift_event_id uuid;
  v_creator_micros bigint;
begin
  select role into v_sender_role
  from public.account_roles
  where user_id = v_sender;

  if v_sender_role = 'owner' then
    v_enabled := true;
    v_max_gross_cents := 10000;
  elsif v_sender_role = 'admin' then
    select cash_rewards_enabled, max_gross_cents_per_gift
      into v_enabled, v_max_gross_cents
    from public.staff_cash_reward_permissions
    where user_id = v_sender;
  else
    raise exception 'staff cash reward access required' using errcode = '42501';
  end if;

  if coalesce(v_enabled, false) is not true then
    raise exception 'cash reward gifting is disabled for this staff account' using errcode = '42501';
  end if;

  if p_quantity is null or p_quantity < 1 or p_quantity > 100000 then
    raise exception 'invalid gift quantity' using errcode = '22023';
  end if;

  select cost_coins into v_unit_cost
  from public.fameverse_gift_catalog
  where id = p_gift_id and active = true;
  if v_unit_cost is null then
    raise exception 'unknown gift' using errcode = '22023';
  end if;

  v_total := v_unit_cost::bigint * p_quantity::bigint;
  if v_total <= 0 or v_total > coalesce(v_max_gross_cents, 0) then
    raise exception 'cash reward gift exceeds the configured gross value cap' using errcode = '22023';
  end if;

  select host_user_id into v_recipient
  from public.live_rooms
  where id = p_room_id and status = 'live' and ended_at is null;
  if v_recipient is null then
    raise exception 'live room is not active' using errcode = 'P0002';
  end if;
  if v_sender = v_recipient then
    raise exception 'self gifting is not allowed' using errcode = '42501';
  end if;

  perform public._ensure_fame_coin_wallet(v_sender);
  perform pg_advisory_xact_lock(hashtextextended('fv-coin:' || v_sender::text, 0));

  select cash_backed_coins into v_cash_balance
  from public.coin_funding_balances
  where user_id = v_sender
  for update;

  if coalesce(v_cash_balance, 0) < v_total then
    raise exception 'insufficient cash-backed reward coins' using errcode = '22003';
  end if;

  insert into public.gift_events (
    room_id, sender_user_id, recipient_user_id, gift_id, quantity, coins_spent
  ) values (
    p_room_id, v_sender, v_recipient, p_gift_id, p_quantity, v_total
  ) returning id into v_gift_event_id;

  v_balance := public._credit_fame_coins(
    v_sender, -v_total, 0, 'cash_reward_gift',
    'cash-reward-gift:' || v_gift_event_id::text
  );

  update public.coin_funding_ledger
  set gift_event_id = v_gift_event_id
  where event_key = 'cash-reward-gift:' || v_gift_event_id::text;

  insert into public.beta_coin_ledger (
    user_id, delta, balance_after, event_type, gift_event_id
  ) values (
    v_sender, -v_total, v_balance, 'cash_reward_gift', v_gift_event_id
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

  v_creator_micros := public._apply_creator_cash_coin_share(v_gift_event_id, v_total);

  insert into public.gift_funding_breakdowns (
    gift_event_id, cash_backed_coins, promo_coins, creator_earning_cents,
    creator_earning_micros, funding_rule
  ) values (
    v_gift_event_id, v_total, 0,
    (v_creator_micros / 10000)::bigint, v_creator_micros,
    'explicit_staff_cash_reward'
  );

  return query
  select stats.total_coins_sent, stats.gift_count, stats.level,
         v_balance, v_total, v_creator_micros
  from public.gifter_stats stats
  where stats.user_id = v_sender;
end;
$$;

revoke all on function public.send_fameverse_cash_reward_gift(uuid, text, integer) from public, anon, authenticated;
grant execute on function public.send_fameverse_cash_reward_gift(uuid, text, integer) to authenticated;
