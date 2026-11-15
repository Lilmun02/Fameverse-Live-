-- Fameverse external Fame Coin recharge foundation.
-- Real purchases are server-authoritative and idempotent.
-- Public recharge economics remain intentionally unlocked. Build 16 includes
-- one owner-only QA pack so the owner can run the first real end-to-end charge
-- without defining the public Fame Coin economy.

alter table public.beta_coin_ledger
  drop constraint if exists beta_coin_ledger_event_type_check;

alter table public.beta_coin_ledger
  add constraint beta_coin_ledger_event_type_check
  check (event_type in ('seed', 'refill', 'gift_send', 'purchase', 'refund'));

create table if not exists public.coin_recharge_packs (
  id text primary key,
  label text not null,
  coins integer not null check (coins > 0),
  price_cents integer not null check (price_cents > 0),
  currency text not null default 'USD',
  active boolean not null default false,
  owner_only boolean not null default false,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint coin_recharge_pack_id_check check (id ~ '^[a-z0-9][a-z0-9-]{1,48}$'),
  constraint coin_recharge_pack_label_check check (char_length(label) between 1 and 80),
  constraint coin_recharge_pack_currency_check check (currency ~ '^[A-Z]{3}$')
);

create table if not exists public.coin_recharge_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  token_hash text not null unique,
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  last_used_at timestamptz,
  revoked_at timestamptz
);

create index if not exists coin_recharge_sessions_user_created_idx
  on public.coin_recharge_sessions(user_id, created_at desc);
create index if not exists coin_recharge_sessions_expiry_idx
  on public.coin_recharge_sessions(expires_at);

create table if not exists public.coin_recharge_orders (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  pack_id text not null references public.coin_recharge_packs(id),
  provider text not null default 'paypal',
  provider_order_id text unique,
  provider_capture_id text unique,
  amount_cents integer not null check (amount_cents > 0),
  currency text not null,
  coins integer not null check (coins > 0),
  status text not null default 'created',
  created_at timestamptz not null default now(),
  approved_at timestamptz,
  completed_at timestamptz,
  refunded_at timestamptz,
  updated_at timestamptz not null default now(),
  risk_note text,
  constraint coin_recharge_provider_check check (provider in ('paypal')),
  constraint coin_recharge_status_check check (
    status in (
      'created', 'approved', 'completed', 'refund_pending', 'refunded',
      'disputed', 'failed', 'cancelled'
    )
  ),
  constraint coin_recharge_currency_check check (currency ~ '^[A-Z]{3}$'),
  constraint coin_recharge_risk_note_check check (risk_note is null or char_length(risk_note) <= 500)
);

create index if not exists coin_recharge_orders_user_created_idx
  on public.coin_recharge_orders(user_id, created_at desc);
create index if not exists coin_recharge_orders_status_created_idx
  on public.coin_recharge_orders(status, created_at asc);

alter table public.coin_recharge_packs enable row level security;
alter table public.coin_recharge_sessions enable row level security;
alter table public.coin_recharge_orders enable row level security;

-- Packs are read through a function so owner-only QA packs never leak to testers.
revoke all privileges on table public.coin_recharge_packs from anon, authenticated;
revoke all privileges on table public.coin_recharge_sessions from anon, authenticated;
revoke all privileges on table public.coin_recharge_orders from anon, authenticated;

grant select on table public.coin_recharge_orders to authenticated;

drop policy if exists "users can read own recharge orders" on public.coin_recharge_orders;
create policy "users can read own recharge orders"
on public.coin_recharge_orders for select
to authenticated
using (auth.uid() = user_id);

insert into public.coin_recharge_packs (
  id,
  label,
  coins,
  price_cents,
  currency,
  active,
  owner_only,
  sort_order
)
values (
  'owner-qa-99c',
  'Owner QA Recharge',
  1,
  99,
  'USD',
  true,
  true,
  0
)
on conflict (id) do update set
  label = excluded.label,
  coins = excluded.coins,
  price_cents = excluded.price_cents,
  currency = excluded.currency,
  active = excluded.active,
  owner_only = excluded.owner_only,
  sort_order = excluded.sort_order,
  updated_at = now();

create or replace function public.get_coin_recharge_packs()
returns table (
  pack_id text,
  label text,
  coins integer,
  price_cents integer,
  currency text,
  owner_only boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select
    pack.id,
    pack.label,
    pack.coins,
    pack.price_cents,
    pack.currency,
    pack.owner_only
  from public.coin_recharge_packs pack
  where pack.active = true
    and (
      pack.owner_only = false
      or exists (
        select 1
        from public.account_roles role_row
        where role_row.user_id = auth.uid()
          and role_row.role = 'owner'
      )
    )
  order by pack.sort_order, pack.price_cents;
$$;

create or replace function public.get_coin_recharge_history(p_limit integer default 20)
returns table (
  recharge_id uuid,
  pack_id text,
  amount_cents integer,
  currency text,
  coins integer,
  status text,
  provider text,
  provider_order_id text,
  provider_capture_id text,
  created_at timestamptz,
  completed_at timestamptz,
  refunded_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    recharge.id,
    recharge.pack_id,
    recharge.amount_cents,
    recharge.currency,
    recharge.coins,
    recharge.status,
    recharge.provider,
    recharge.provider_order_id,
    recharge.provider_capture_id,
    recharge.created_at,
    recharge.completed_at,
    recharge.refunded_at
  from public.coin_recharge_orders recharge
  where recharge.user_id = auth.uid()
  order by recharge.created_at desc
  limit least(greatest(coalesce(p_limit, 20), 1), 100);
$$;

-- Service-role-only completion primitive. PayPal capture details are verified by
-- the Edge Function before this function is called. This function independently
-- checks the local expected amount and provides transaction-level idempotency.
create or replace function public.finalize_coin_recharge(
  p_recharge_id uuid,
  p_provider_order_id text,
  p_provider_capture_id text,
  p_amount_cents integer,
  p_currency text
)
returns table (
  wallet_balance bigint,
  credited_coins integer,
  already_completed boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_order public.coin_recharge_orders%rowtype;
  v_balance bigint;
  v_existing boolean := false;
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

  if p_amount_cents <> v_order.amount_cents
     or upper(coalesce(p_currency, '')) <> upper(v_order.currency) then
    raise exception 'captured payment does not match recharge order' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.coin_recharge_orders other
    where other.provider_capture_id = p_provider_capture_id
      and other.id <> v_order.id
  ) then
    raise exception 'provider capture already used' using errcode = '23505';
  end if;

  insert into public.beta_coin_wallets (user_id, balance)
  values (v_order.user_id, 0)
  on conflict (user_id) do nothing;

  select balance into v_balance
  from public.beta_coin_wallets
  where user_id = v_order.user_id
  for update;

  update public.beta_coin_wallets
  set balance = balance + v_order.coins,
      updated_at = now()
  where user_id = v_order.user_id
  returning balance into v_balance;

  insert into public.beta_coin_ledger (
    user_id,
    delta,
    balance_after,
    event_type
  ) values (
    v_order.user_id,
    v_order.coins,
    v_balance,
    'purchase'
  );

  update public.coin_recharge_orders
  set status = 'completed',
      provider_order_id = p_provider_order_id,
      provider_capture_id = p_provider_capture_id,
      completed_at = now(),
      updated_at = now()
  where id = v_order.id;

  return query select v_balance, v_order.coins, v_existing;
end;
$$;

-- Service-role-only refund primitive. It never drives a wallet negative. If
-- purchased coins were already spent, the order stays in refund_pending so the
-- moderation/risk layer can resolve the account instead of silently creating debt.
create or replace function public.mark_coin_recharge_refunded(
  p_recharge_id uuid,
  p_note text default null
)
returns text
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

  if v_order.status = 'refunded' then
    return 'refunded';
  end if;

  if v_order.status <> 'completed' then
    raise exception 'only completed recharge orders can be refunded' using errcode = '22023';
  end if;

  select balance into v_balance
  from public.beta_coin_wallets
  where user_id = v_order.user_id
  for update;

  if coalesce(v_balance, 0) < v_order.coins then
    update public.coin_recharge_orders
    set status = 'refund_pending',
        risk_note = left(coalesce(p_note, 'Purchased coins already spent; manual review required.'), 500),
        updated_at = now()
    where id = v_order.id;
    return 'refund_pending';
  end if;

  update public.beta_coin_wallets
  set balance = balance - v_order.coins,
      updated_at = now()
  where user_id = v_order.user_id
  returning balance into v_balance;

  insert into public.beta_coin_ledger (
    user_id,
    delta,
    balance_after,
    event_type
  ) values (
    v_order.user_id,
    -v_order.coins,
    v_balance,
    'refund'
  );

  update public.coin_recharge_orders
  set status = 'refunded',
      refunded_at = now(),
      risk_note = left(nullif(trim(coalesce(p_note, '')), ''), 500),
      updated_at = now()
  where id = v_order.id;

  return 'refunded';
end;
$$;

revoke all on function public.get_coin_recharge_packs() from public;
grant execute on function public.get_coin_recharge_packs() to authenticated;
revoke all on function public.get_coin_recharge_history(integer) from public;
grant execute on function public.get_coin_recharge_history(integer) to authenticated;
revoke all on function public.finalize_coin_recharge(uuid, text, text, integer, text) from public, anon, authenticated;
grant execute on function public.finalize_coin_recharge(uuid, text, text, integer, text) to service_role;
revoke all on function public.mark_coin_recharge_refunded(uuid, text) from public, anon, authenticated;
grant execute on function public.mark_coin_recharge_refunded(uuid, text) to service_role;
