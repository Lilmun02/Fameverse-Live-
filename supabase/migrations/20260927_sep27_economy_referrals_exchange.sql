begin;

-- Fameverse shows one Fame Coin balance to users, while the backend keeps the
-- funding source separate so free promotional coins can never create an
-- unfunded creator-cash liability.
create table if not exists public.coin_funding_balances (
  user_id uuid primary key references auth.users(id) on delete cascade,
  cash_backed_coins bigint not null default 0 check (cash_backed_coins >= 0),
  promo_coins bigint not null default 0 check (promo_coins >= 0),
  updated_at timestamptz not null default now()
);

create table if not exists public.coin_funding_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  cash_delta bigint not null default 0,
  promo_delta bigint not null default 0,
  total_balance_after bigint not null check (total_balance_after >= 0),
  event_type text not null,
  event_key text unique,
  gift_event_id uuid references public.gift_events(id) on delete set null,
  created_at timestamptz not null default now(),
  check (cash_delta <> 0 or promo_delta <> 0)
);

create table if not exists public.gift_funding_breakdowns (
  gift_event_id uuid primary key references public.gift_events(id) on delete cascade,
  cash_backed_coins bigint not null default 0 check (cash_backed_coins >= 0),
  promo_coins bigint not null default 0 check (promo_coins >= 0),
  creator_earning_cents bigint not null default 0 check (creator_earning_cents >= 0),
  funding_rule text not null default 'promo_first',
  created_at timestamptz not null default now()
);

create table if not exists public.coin_exchange_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  amount_cents bigint not null check (amount_cents > 0),
  coins_credited bigint not null check (coins_credited > 0),
  idempotency_key text not null,
  created_at timestamptz not null default now(),
  unique (user_id, idempotency_key)
);

create table if not exists public.beta_referral_codes (
  user_id uuid primary key references auth.users(id) on delete cascade,
  code text not null unique,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.beta_referrals (
  id uuid primary key default gen_random_uuid(),
  referrer_user_id uuid not null references auth.users(id) on delete cascade,
  referred_user_id uuid not null unique references auth.users(id) on delete cascade,
  referral_code text not null,
  status text not null default 'qualified' check (status in ('qualified', 'revoked')),
  referrer_reward_coins integer not null default 100 check (referrer_reward_coins >= 0),
  referred_reward_coins integer not null default 50 check (referred_reward_coins >= 0),
  qualified_at timestamptz not null default now(),
  check (referrer_user_id <> referred_user_id)
);

alter table public.coin_funding_balances enable row level security;
alter table public.coin_funding_ledger enable row level security;
alter table public.gift_funding_breakdowns enable row level security;
alter table public.coin_exchange_transactions enable row level security;
alter table public.beta_referral_codes enable row level security;
alter table public.beta_referrals enable row level security;

revoke all on public.coin_funding_balances from anon, authenticated;
revoke all on public.coin_funding_ledger from anon, authenticated;
revoke all on public.gift_funding_breakdowns from anon, authenticated;
revoke all on public.coin_exchange_transactions from anon, authenticated;
revoke all on public.beta_referral_codes from anon, authenticated;
revoke all on public.beta_referrals from anon, authenticated;

-- Existing beta/test balances are deliberately classified as promotional.
-- This is conservative: it prevents old free QA coins from becoming creator
-- cash. New verified PayPal captures and Coin Exchange credits are cash-backed.
insert into public.coin_funding_balances (user_id, cash_backed_coins, promo_coins)
select wallet.user_id, 0, greatest(wallet.balance, 0)
from public.beta_coin_wallets wallet
on conflict (user_id) do nothing;

create or replace function public._ensure_fame_coin_wallet(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  insert into public.beta_coin_wallets (user_id, balance)
  values (p_user_id, 0)
  on conflict (user_id) do nothing;

  insert into public.coin_funding_balances (user_id, cash_backed_coins, promo_coins)
  values (p_user_id, 0, 0)
  on conflict (user_id) do nothing;
end;
$$;

create or replace function public._credit_fame_coins(
  p_user_id uuid,
  p_cash_delta bigint,
  p_promo_delta bigint,
  p_event_type text,
  p_event_key text default null
)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_total_delta bigint := coalesce(p_cash_delta, 0) + coalesce(p_promo_delta, 0);
  v_balance bigint;
  v_cash bigint;
  v_promo bigint;
begin
  if p_user_id is null then
    raise exception 'user required' using errcode = '22023';
  end if;
  if v_total_delta = 0 then
    raise exception 'coin delta required' using errcode = '22023';
  end if;

  perform public._ensure_fame_coin_wallet(p_user_id);
  perform pg_advisory_xact_lock(hashtextextended('fv-coin:' || p_user_id::text, 0));

  select cash_backed_coins, promo_coins
    into v_cash, v_promo
  from public.coin_funding_balances
  where user_id = p_user_id
  for update;

  if v_cash + coalesce(p_cash_delta, 0) < 0 or
     v_promo + coalesce(p_promo_delta, 0) < 0 then
    raise exception 'insufficient funded coin balance' using errcode = '22003';
  end if;

  update public.coin_funding_balances
  set cash_backed_coins = cash_backed_coins + coalesce(p_cash_delta, 0),
      promo_coins = promo_coins + coalesce(p_promo_delta, 0),
      updated_at = now()
  where user_id = p_user_id;

  update public.beta_coin_wallets
  set balance = balance + v_total_delta,
      updated_at = now()
  where user_id = p_user_id
  returning balance into v_balance;

  if v_balance < 0 then
    raise exception 'coin wallet would become negative' using errcode = '22003';
  end if;

  insert into public.coin_funding_ledger (
    user_id, cash_delta, promo_delta, total_balance_after, event_type, event_key
  ) values (
    p_user_id, coalesce(p_cash_delta, 0), coalesce(p_promo_delta, 0),
    v_balance, p_event_type, p_event_key
  )
  on conflict (event_key) where event_key is not null do nothing;

  return v_balance;
end;
$$;

create or replace function public.get_fame_coin_balance()
returns table (balance bigint)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select coalesce((
    select wallet.balance
    from public.beta_coin_wallets wallet
    where wallet.user_id = auth.uid()
  ), 0)::bigint;
$$;

-- PayPal captures credit the visible wallet and the cash-backed funding bucket
-- atomically. A duplicated capture remains idempotent.
create or replace function public.finalize_coin_recharge(
  p_recharge_id uuid,
  p_provider_order_id text,
  p_provider_capture_id text,
  p_amount_cents integer,
  p_currency text
)
returns table(wallet_balance bigint, credited_coins integer, already_completed boolean)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_order public.coin_recharge_orders%rowtype;
  v_balance bigint;
begin
  select * into v_order
  from public.coin_recharge_orders
  where id = p_recharge_id
  for update;

  if v_order.id is null then
    raise exception 'recharge order not found' using errcode = 'P0002';
  end if;

  if v_order.status = 'completed' then
    select balance into v_balance
    from public.beta_coin_wallets
    where user_id = v_order.user_id;
    return query select coalesce(v_balance, 0), v_order.coins, true;
    return;
  end if;

  if v_order.status not in ('created', 'approved') then
    raise exception 'recharge order cannot be completed from current status' using errcode = '22023';
  end if;

  if p_amount_cents <> v_order.amount_cents or
     upper(coalesce(p_currency, '')) <> upper(v_order.currency) then
    raise exception 'captured payment does not match recharge order' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.coin_recharge_orders other
    where other.provider_capture_id = p_provider_capture_id
      and other.id <> v_order.id
  ) then
    raise exception 'provider capture already used' using errcode = '23505';
  end if;

  v_balance := public._credit_fame_coins(
    v_order.user_id,
    v_order.coins,
    0,
    'purchase',
    'recharge:' || v_order.id::text
  );

  insert into public.beta_coin_ledger(user_id, delta, balance_after, event_type)
  values(v_order.user_id, v_order.coins, v_balance, 'purchase');

  update public.coin_recharge_orders
  set status = 'completed',
      provider_order_id = p_provider_order_id,
      provider_capture_id = p_provider_capture_id,
      completed_at = now(),
      updated_at = now()
  where id = v_order.id;

  return query select v_balance, v_order.coins, false;
end;
$$;

create or replace function public.exchange_creator_earnings_for_coins(
  p_amount_cents bigint,
  p_idempotency_key text
)
returns table (
  exchange_id uuid,
  amount_cents bigint,
  coins_credited bigint,
  fame_coin_balance bigint,
  creator_available_cents bigint
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_available bigint;
  v_reserved bigint;
  v_withdrawable bigint;
  v_exchange public.coin_exchange_transactions%rowtype;
  v_balance bigint;
  v_key text := trim(coalesce(p_idempotency_key, ''));
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_amount_cents is null or p_amount_cents < 1 then
    raise exception 'exchange amount must be at least one cent' using errcode = '22023';
  end if;
  if length(v_key) < 8 or length(v_key) > 120 then
    raise exception 'valid idempotency key required' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('fv-earnings:' || v_user::text, 0));

  select * into v_exchange
  from public.coin_exchange_transactions
  where user_id = v_user and idempotency_key = v_key;

  if found then
    select coalesce(balance, 0) into v_balance
    from public.beta_coin_wallets where user_id = v_user;
    select coalesce(sum(amount_cents) filter (where state in ('available','paid','reversed')), 0)::bigint
      into v_available
    from public.creator_earnings_ledger where creator_user_id = v_user;
    select coalesce(sum(amount_cents) filter (where status in ('pending_review','approved','processing','held')), 0)::bigint
      into v_reserved
    from public.creator_payout_requests where creator_user_id = v_user;
    return query select v_exchange.id, v_exchange.amount_cents,
      v_exchange.coins_credited, coalesce(v_balance, 0),
      greatest(v_available - v_reserved, 0);
    return;
  end if;

  select coalesce(sum(amount_cents) filter (where state in ('available','paid','reversed')), 0)::bigint
    into v_available
  from public.creator_earnings_ledger
  where creator_user_id = v_user;

  select coalesce(sum(amount_cents) filter (where status in ('pending_review','approved','processing','held')), 0)::bigint
    into v_reserved
  from public.creator_payout_requests
  where creator_user_id = v_user;

  v_withdrawable := greatest(v_available - v_reserved, 0);
  if p_amount_cents > v_withdrawable then
    raise exception 'insufficient available creator earnings' using errcode = '22003';
  end if;

  insert into public.coin_exchange_transactions (
    user_id, amount_cents, coins_credited, idempotency_key
  ) values (
    v_user, p_amount_cents, p_amount_cents, v_key
  ) returning * into v_exchange;

  insert into public.creator_earnings_ledger (
    creator_user_id, amount_cents, state, source_type, source_key, note, available_at
  ) values (
    v_user,
    -p_amount_cents,
    'available',
    'coin_exchange',
    'coin_exchange:' || v_exchange.id::text,
    'Creator earnings exchanged one-way into Fame Coins',
    now()
  );

  -- $1.00 creator earnings = 100 Fame Coins, therefore 1 US cent = 1 coin.
  -- Exchanged coins are cash-backed and may create normal 70/30 earnings when
  -- later gifted to another creator.
  v_balance := public._credit_fame_coins(
    v_user,
    p_amount_cents,
    0,
    'creator_earnings_exchange',
    'exchange:' || v_exchange.id::text
  );

  v_withdrawable := v_withdrawable - p_amount_cents;
  return query select v_exchange.id, p_amount_cents, p_amount_cents,
    v_balance, v_withdrawable;
end;
$$;

create or replace function public.get_creator_coin_exchange_history(p_limit integer default 30)
returns table (
  exchange_id uuid,
  amount_cents bigint,
  coins_credited bigint,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select x.id, x.amount_cents, x.coins_credited, x.created_at
  from public.coin_exchange_transactions x
  where x.user_id = auth.uid()
  order by x.created_at desc
  limit least(greatest(coalesce(p_limit, 30), 1), 100);
$$;

create or replace function public.ensure_beta_referral_code()
returns text
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_code text;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if not exists (
    select 1 from public.beta_program_members member
    where member.user_id = v_user and member.status in ('active', 'earned')
  ) then
    raise exception 'external beta tester enrollment required' using errcode = '42501';
  end if;

  select code into v_code from public.beta_referral_codes where user_id = v_user;
  if found then return v_code; end if;

  v_code := 'FV' || upper(substr(md5(v_user::text || ':first-verse'), 1, 8));
  insert into public.beta_referral_codes(user_id, code)
  values(v_user, v_code)
  on conflict (user_id) do update set active = true
  returning code into v_code;
  return v_code;
end;
$$;

create or replace function public.qualify_beta_referral(p_code text)
returns table (
  accepted boolean,
  referrer_reward_coins integer,
  referred_reward_coins integer,
  referred_balance bigint
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_code text := upper(trim(coalesce(p_code, '')));
  v_referrer uuid;
  v_balance bigint;
  v_referral_id uuid;
  v_display text;
  v_username text;
begin
  if v_user is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if length(v_code) < 4 then
    raise exception 'valid referral code required' using errcode = '22023';
  end if;

  select code.user_id into v_referrer
  from public.beta_referral_codes code
  join public.beta_program_members member on member.user_id = code.user_id
  where code.code = v_code
    and code.active = true
    and member.status in ('active', 'earned');

  if v_referrer is null then
    raise exception 'referral code unavailable' using errcode = 'P0002';
  end if;
  if v_referrer = v_user then
    raise exception 'self referral is not allowed' using errcode = '42501';
  end if;

  select trim(coalesce(display_name, '')), trim(coalesce(username, ''))
    into v_display, v_username
  from public.profiles
  where id = v_user;

  if coalesce(v_display, '') = '' or coalesce(v_username, '') = '' then
    raise exception 'complete your Fameverse profile before referral rewards unlock' using errcode = '22023';
  end if;

  if exists (select 1 from public.beta_referrals where referred_user_id = v_user) then
    select coalesce(wallet.balance, 0) into v_balance
    from public.beta_coin_wallets wallet where wallet.user_id = v_user;
    return query select false, 100, 50, coalesce(v_balance, 0);
    return;
  end if;

  insert into public.beta_referrals (
    referrer_user_id, referred_user_id, referral_code,
    referrer_reward_coins, referred_reward_coins
  ) values (
    v_referrer, v_user, v_code, 100, 50
  ) returning id into v_referral_id;

  perform public._credit_fame_coins(
    v_referrer, 0, 100, 'beta_referral_reward',
    'beta-referrer:' || v_referral_id::text
  );
  v_balance := public._credit_fame_coins(
    v_user, 0, 50, 'beta_referral_welcome',
    'beta-referred:' || v_referral_id::text
  );

  return query select true, 100, 50, v_balance;
end;
$$;

create or replace function public.get_beta_referral_summary()
returns table (
  referral_code text,
  qualified_referrals bigint,
  promo_coins_earned bigint
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    (select code from public.beta_referral_codes where user_id = auth.uid() and active = true),
    (select count(*)::bigint from public.beta_referrals where referrer_user_id = auth.uid() and status = 'qualified'),
    (select coalesce(sum(referrer_reward_coins), 0)::bigint from public.beta_referrals where referrer_user_id = auth.uid() and status = 'qualified');
$$;

revoke all on function public._ensure_fame_coin_wallet(uuid) from public;
revoke all on function public._credit_fame_coins(uuid,bigint,bigint,text,text) from public;
revoke all on function public.get_fame_coin_balance() from public;
revoke all on function public.exchange_creator_earnings_for_coins(bigint,text) from public;
revoke all on function public.get_creator_coin_exchange_history(integer) from public;
revoke all on function public.ensure_beta_referral_code() from public;
revoke all on function public.qualify_beta_referral(text) from public;
revoke all on function public.get_beta_referral_summary() from public;

grant execute on function public.get_fame_coin_balance() to authenticated;
grant execute on function public.exchange_creator_earnings_for_coins(bigint,text) to authenticated;
grant execute on function public.get_creator_coin_exchange_history(integer) to authenticated;
grant execute on function public.ensure_beta_referral_code() to authenticated;
grant execute on function public.qualify_beta_referral(text) to authenticated;
grant execute on function public.get_beta_referral_summary() to authenticated;

comment on table public.coin_funding_balances is
  'Internal funding split for one visible Fame Coin balance. Promotional coins never imply creator-cash backing.';
comment on table public.gift_funding_breakdowns is
  'Per-gift attribution used to ensure only cash-backed coins create normal creator earnings.';
comment on table public.coin_exchange_transactions is
  'One-way creator earnings to Fame Coins exchanges; coins can never be converted back into earnings.';
comment on table public.beta_referrals is
  'Qualified beta referrals. Referrer earns 100 promo coins and referred user earns 50 promo coins.';

commit;
