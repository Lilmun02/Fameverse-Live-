-- Fameverse payout-prep wallet lock.
-- Existing tester balances are preserved. New regular accounts start at 0.
-- Test refills are reserved for owner/admin roles.
-- Self-gifting is temporarily blocked during payout testing and may be revisited
-- when Stripe-backed purchase and payout flows replace the beta wallet.

alter table public.beta_coin_wallets
  alter column balance set default 0;

-- Preserve the existing @owner / INFAMOUS account as an explicit owner role
-- without hardcoding a generated user id.
insert into public.account_roles (user_id, role)
select p.id, 'owner'
from public.profiles p
where lower(coalesce(p.username, '')) = 'owner'
on conflict (user_id) do update
set role = 'owner',
    updated_at = now();

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'display_name', split_part(new.email, '@', 1), 'Fameverse User')
  )
  on conflict (id) do nothing;

  -- New regular accounts do not receive free test coins.
  insert into public.beta_coin_wallets (user_id, balance)
  values (new.id, 0)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

create or replace function public.record_beta_gift(
  p_room_id uuid,
  p_gift_id text,
  p_quantity integer
)
returns table (
  total_coins_sent bigint,
  gift_count bigint,
  level integer,
  wallet_balance bigint
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
begin
  if v_sender is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if p_quantity is null or p_quantity < 1 or p_quantity > 100000 then
    raise exception 'invalid gift quantity' using errcode = '22023';
  end if;

  if p_gift_id in ('ember-dragon', 'celestial-phoenix') and p_quantity <> 1 then
    raise exception 'premium cinematic gifts send one at a time' using errcode = '22023';
  end if;

  v_unit_cost := case p_gift_id
    when 'welcome-to-fameverse' then 100
    when 'ember-dragon' then 1000
    when 'celestial-phoenix' then 1000
    when 'rose' then 1
    when 'heart' then 1
    when 'fire' then 1
    when 'star' then 1
    when 'crown' then 1
    else null
  end;

  if v_unit_cost is null then
    raise exception 'unknown gift' using errcode = '22023';
  end if;

  select host_user_id into v_recipient
  from public.live_rooms
  where id = p_room_id
    and status = 'live'
    and ended_at is null;

  if v_recipient is null then
    raise exception 'live room is not active' using errcode = 'P0002';
  end if;

  -- Temporary payout-test safety rule: hosts cannot gift their own Live.
  if v_sender = v_recipient then
    raise exception 'hosts cannot gift their own live during payout testing' using errcode = '42501';
  end if;

  v_total := v_unit_cost::bigint * p_quantity::bigint;

  -- Missing wallets are created empty; gift sends never mint beta coins.
  insert into public.beta_coin_wallets (user_id, balance)
  values (v_sender, 0)
  on conflict (user_id) do nothing;

  select balance into v_balance
  from public.beta_coin_wallets
  where user_id = v_sender
  for update;

  if v_balance < v_total then
    raise exception 'insufficient beta coin balance' using errcode = 'P0001';
  end if;

  insert into public.gift_events (
    room_id,
    sender_user_id,
    recipient_user_id,
    gift_id,
    quantity,
    coins_spent
  )
  values (
    p_room_id,
    v_sender,
    v_recipient,
    p_gift_id,
    p_quantity,
    v_total
  )
  returning id into v_gift_event_id;

  update public.beta_coin_wallets
  set balance = balance - v_total,
      updated_at = now()
  where user_id = v_sender
  returning balance into v_balance;

  insert into public.beta_coin_ledger (
    user_id,
    delta,
    balance_after,
    event_type,
    gift_event_id
  )
  values (
    v_sender,
    -v_total,
    v_balance,
    'gift_send',
    v_gift_event_id
  );

  insert into public.gifter_stats (
    user_id,
    total_coins_sent,
    gift_count,
    level,
    updated_at
  )
  values (
    v_sender,
    v_total,
    p_quantity,
    public.compute_gifter_level(v_total),
    now()
  )
  on conflict (user_id) do update set
    total_coins_sent = public.gifter_stats.total_coins_sent + excluded.total_coins_sent,
    gift_count = public.gifter_stats.gift_count + excluded.gift_count,
    level = public.compute_gifter_level(public.gifter_stats.total_coins_sent + excluded.total_coins_sent),
    updated_at = now();

  return query
  select stats.total_coins_sent,
         stats.gift_count,
         stats.level,
         v_balance
  from public.gifter_stats stats
  where stats.user_id = v_sender;
end;
$$;

create or replace function public.refill_beta_wallet(p_amount integer default 10000)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_balance bigint;
  v_role text;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select role into v_role
  from public.account_roles
  where user_id = v_user_id;

  if coalesce(v_role, '') not in ('owner', 'admin') then
    raise exception 'test coin refill is restricted to Fameverse owner/admin accounts' using errcode = '42501';
  end if;

  if p_amount <> 10000 then
    raise exception 'beta refill amount must be 10000' using errcode = '22023';
  end if;

  insert into public.beta_coin_wallets (user_id, balance)
  values (v_user_id, 0)
  on conflict (user_id) do nothing;

  update public.beta_coin_wallets
  set balance = balance + p_amount,
      updated_at = now()
  where user_id = v_user_id
  returning balance into v_balance;

  insert into public.beta_coin_ledger (user_id, delta, balance_after, event_type)
  values (v_user_id, p_amount, v_balance, 'refill');

  return v_balance;
end;
$$;

revoke all on function public.record_beta_gift(uuid, text, integer) from public;
grant execute on function public.record_beta_gift(uuid, text, integer) to authenticated;
revoke all on function public.refill_beta_wallet(integer) from public;
grant execute on function public.refill_beta_wallet(integer) to authenticated;

-- This backend behavior change is revisioned so installed PWAs show the
-- pre-entry update splash on their next open.
update public.app_release_state
set backend_revision = backend_revision + 1,
    release_label = 'wallet-payout-prep-v1',
    updated_at = now()
where channel = 'pwa';
