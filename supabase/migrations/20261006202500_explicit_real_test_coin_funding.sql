
create or replace function public.owner_grant_test_coins(
  p_username text,
  p_amount integer default 10000
)
returns table (
  user_id uuid,
  username text,
  test_coins bigint,
  total_balance bigint
)
language plpgsql
security definer
set search_path to 'public','pg_temp'
as $$
declare
  v_owner uuid := auth.uid();
  v_target uuid;
  v_username text := lower(trim(leading '@' from trim(coalesce(p_username,''))));
  v_balance bigint;
  v_test bigint;
begin
  if not exists (
    select 1 from public.account_roles r
    where r.user_id = v_owner and r.role = 'owner'
  ) then
    raise exception 'owner access required' using errcode='42501';
  end if;

  if char_length(v_username) < 3 then
    raise exception 'valid tester username required' using errcode='22023';
  end if;

  if p_amount is null or p_amount < 1 or p_amount > 1000000 then
    raise exception 'test coin grant must be between 1 and 1000000' using errcode='22023';
  end if;

  select p.id into v_target
  from public.profiles p
  where lower(p.username) = v_username
  limit 1;

  if v_target is null then
    raise exception 'tester profile not found' using errcode='P0002';
  end if;

  v_balance := public._credit_fame_coins(
    v_target,
    0,
    p_amount,
    'owner_test_grant',
    'owner-test-grant:' || v_target::text || ':' || gen_random_uuid()::text
  );

  insert into public.beta_coin_ledger(
    user_id, delta, balance_after, event_type
  ) values (
    v_target, p_amount, v_balance, 'owner_test_grant'
  );

  select f.promo_coins into v_test
  from public.coin_funding_balances f
  where f.user_id = v_target;

  return query
  select v_target, v_username, coalesce(v_test,0), coalesce(v_balance,0);
end;
$$;

revoke all on function public.owner_grant_test_coins(text,integer) from public;
grant execute on function public.owner_grant_test_coins(text,integer) to authenticated;

create or replace function public.send_fameverse_gift_v2(
  p_room_id uuid,
  p_gift_id text,
  p_quantity integer,
  p_funding_mode text default 'auto'
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
set search_path to 'public','pg_temp'
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
  v_cash_spent bigint := 0;
  v_promo_spent bigint := 0;
  v_creator_micros bigint := 0;
  v_mode text := lower(trim(coalesce(p_funding_mode,'auto')));
begin
  if v_sender is null then
    raise exception 'authentication required' using errcode='42501';
  end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > 100000 then
    raise exception 'invalid gift quantity' using errcode='22023';
  end if;
  if v_mode not in ('auto','real','test') then
    raise exception 'invalid gift funding mode' using errcode='22023';
  end if;

  select role into v_sender_role
  from public.account_roles
  where user_id = v_sender;

  select gift.cost_coins into v_unit_cost
  from public.fameverse_gift_catalog gift
  where gift.id = p_gift_id and gift.active = true;
  if v_unit_cost is null then
    raise exception 'unknown gift' using errcode='22023';
  end if;

  select room.host_user_id into v_recipient
  from public.live_rooms room
  where room.id = p_room_id and room.status='live' and room.ended_at is null;
  if v_recipient is null then
    raise exception 'live room is not active' using errcode='P0002';
  end if;
  if v_sender = v_recipient then
    raise exception 'self gifting is not allowed' using errcode='42501';
  end if;

  v_total := v_unit_cost::bigint * p_quantity::bigint;
  if v_total <= 0 then
    raise exception 'invalid gift total' using errcode='22023';
  end if;

  perform public._ensure_fame_coin_wallet(v_sender);
  perform pg_advisory_xact_lock(hashtextextended('fv-coin:' || v_sender::text,0));

  select f.cash_backed_coins, f.promo_coins
    into v_cash_balance, v_promo_balance
  from public.coin_funding_balances f
  where f.user_id = v_sender
  for update;

  if coalesce(v_sender_role,'') in ('owner','admin') then
    if v_mode = 'real' then
      raise exception 'ordinary owner/admin gifts cannot spend real coins; use the explicit cash reward flow' using errcode='42501';
    end if;
    if coalesce(v_promo_balance,0) < v_total then
      raise exception 'insufficient promotional Fame Coins' using errcode='22003';
    end if;
    v_promo_spent := v_total;
  elsif v_mode = 'test' then
    if coalesce(v_promo_balance,0) < v_total then
      raise exception 'insufficient test Fame Coins' using errcode='22003';
    end if;
    v_promo_spent := v_total;
  elsif v_mode = 'real' then
    if coalesce(v_cash_balance,0) < v_total then
      raise exception 'insufficient real Fame Coins' using errcode='22003';
    end if;
    v_cash_spent := v_total;
  else
    v_promo_spent := least(coalesce(v_promo_balance,0), v_total);
    v_cash_spent := v_total - v_promo_spent;
    if coalesce(v_cash_balance,0) < v_cash_spent then
      raise exception 'insufficient Fame Coin balance' using errcode='22003';
    end if;
  end if;

  insert into public.gift_events(
    room_id,sender_user_id,recipient_user_id,gift_id,quantity,coins_spent
  ) values (
    p_room_id,v_sender,v_recipient,p_gift_id,p_quantity,v_total
  ) returning id into v_gift_event_id;

  v_balance := public._credit_fame_coins(
    v_sender,-v_cash_spent,-v_promo_spent,'gift_send',
    'gift-send:' || v_gift_event_id::text
  );

  update public.coin_funding_ledger
  set gift_event_id = v_gift_event_id
  where event_key = 'gift-send:' || v_gift_event_id::text;

  insert into public.beta_coin_ledger(
    user_id,delta,balance_after,event_type,gift_event_id
  ) values (
    v_sender,-v_total,v_balance,'gift_send',v_gift_event_id
  );

  insert into public.gifter_stats(
    user_id,total_coins_sent,gift_count,level,updated_at
  ) values (
    v_sender,v_total,p_quantity,public.compute_gifter_level(v_total),now()
  )
  on conflict(user_id) do update set
    total_coins_sent = public.gifter_stats.total_coins_sent + excluded.total_coins_sent,
    gift_count = public.gifter_stats.gift_count + excluded.gift_count,
    level = public.compute_gifter_level(
      public.gifter_stats.total_coins_sent + excluded.total_coins_sent
    ),
    updated_at = now();

  if v_cash_spent > 0 then
    v_creator_micros := public._apply_creator_cash_coin_share(
      v_gift_event_id,v_cash_spent
    );
  end if;

  insert into public.gift_funding_breakdowns(
    gift_event_id,cash_backed_coins,promo_coins,creator_earning_cents,
    creator_earning_micros,funding_rule
  ) values (
    v_gift_event_id,v_cash_spent,v_promo_spent,
    (v_creator_micros/10000)::bigint,v_creator_micros,
    case
      when coalesce(v_sender_role,'') in ('owner','admin') then 'staff_test_only_zero_earnings'
      when v_mode='test' then 'explicit_test_zero_earnings'
      when v_mode='real' then 'explicit_real_cash_backed_earnings'
      else 'auto_test_first_then_real'
    end
  );

  return query
  select s.total_coins_sent,s.gift_count,s.level,v_balance,
         v_cash_spent,v_promo_spent,v_creator_micros,0::bigint
  from public.gifter_stats s
  where s.user_id=v_sender;
end;
$$;

revoke all on function public.send_fameverse_gift_v2(uuid,text,integer,text) from public;
grant execute on function public.send_fameverse_gift_v2(uuid,text,integer,text) to authenticated;
