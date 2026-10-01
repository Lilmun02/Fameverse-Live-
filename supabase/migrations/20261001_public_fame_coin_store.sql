-- Public Fame Coin store foundation for native in-app purchases.
-- StoreKit / Play receipts are verified server-side before this ledger can mint coins.
-- Provider transaction IDs are globally idempotent per platform.

create table if not exists public.fame_coin_store_products (
  product_id text not null,
  platform text not null,
  coins integer not null check (coins > 0),
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (platform, product_id),
  constraint fame_coin_store_products_platform_check
    check (platform in ('ios', 'android')),
  constraint fame_coin_store_products_product_id_check
    check (char_length(product_id) between 3 and 120)
);

create table if not exists public.fame_coin_store_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  platform text not null,
  product_id text not null,
  transaction_id text not null,
  original_transaction_id text,
  environment text,
  app_account_token text,
  coins integer not null check (coins > 0),
  status text not null default 'processing',
  purchase_date timestamptz,
  created_at timestamptz not null default now(),
  completed_at timestamptz,
  constraint fame_coin_store_transactions_platform_check
    check (platform in ('ios', 'android')),
  constraint fame_coin_store_transactions_status_check
    check (status in ('processing', 'completed', 'revoked')),
  constraint fame_coin_store_transactions_provider_tx_unique
    unique (platform, transaction_id),
  foreign key (platform, product_id)
    references public.fame_coin_store_products(platform, product_id)
);

create index if not exists fame_coin_store_transactions_user_created_idx
  on public.fame_coin_store_transactions(user_id, created_at desc);

alter table public.fame_coin_store_products enable row level security;
alter table public.fame_coin_store_transactions enable row level security;

revoke all privileges on table public.fame_coin_store_products from anon, authenticated;
revoke all privileges on table public.fame_coin_store_transactions from anon, authenticated;
grant select on table public.fame_coin_store_transactions to authenticated;

drop policy if exists "users can read own store transactions"
  on public.fame_coin_store_transactions;
create policy "users can read own store transactions"
on public.fame_coin_store_transactions for select
to authenticated
using ((select auth.uid()) = user_id);

insert into public.fame_coin_store_products (product_id, platform, coins, active, sort_order)
values
  ('fame_coins_100', 'ios', 100, true, 10),
  ('fame_coins_500', 'ios', 500, true, 20),
  ('fame_coins_1000', 'ios', 1000, true, 30),
  ('fame_coins_2500', 'ios', 2500, true, 40),
  ('fame_coins_5000', 'ios', 5000, true, 50),
  ('fame_coins_10000', 'ios', 10000, true, 60),
  ('fame_coins_100', 'android', 100, true, 10),
  ('fame_coins_500', 'android', 500, true, 20),
  ('fame_coins_1000', 'android', 1000, true, 30),
  ('fame_coins_2500', 'android', 2500, true, 40),
  ('fame_coins_5000', 'android', 5000, true, 50),
  ('fame_coins_10000', 'android', 10000, true, 60)
on conflict (platform, product_id) do update set
  coins = excluded.coins,
  active = excluded.active,
  sort_order = excluded.sort_order,
  updated_at = now();

create or replace function public.get_fame_coin_store_products(
  p_platform text default 'ios'
)
returns table (
  product_id text,
  coins integer,
  sort_order integer
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select product.product_id, product.coins, product.sort_order
  from public.fame_coin_store_products product
  where product.platform = lower(coalesce(p_platform, 'ios'))
    and product.active = true
  order by product.sort_order, product.coins;
$$;

revoke all on function public.get_fame_coin_store_products(text) from public;
grant execute on function public.get_fame_coin_store_products(text) to authenticated;

create or replace function public.finalize_fame_coin_store_purchase(
  p_user_id uuid,
  p_platform text,
  p_product_id text,
  p_transaction_id text,
  p_original_transaction_id text default null,
  p_environment text default null,
  p_app_account_token text default null,
  p_purchase_date timestamptz default null
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
  v_platform text := lower(coalesce(p_platform, ''));
  v_product public.fame_coin_store_products%rowtype;
  v_tx_id uuid;
  v_existing public.fame_coin_store_transactions%rowtype;
  v_balance bigint;
begin
  if p_user_id is null or p_transaction_id is null or btrim(p_transaction_id) = '' then
    raise exception 'invalid store purchase identity' using errcode = '22023';
  end if;

  select * into v_product
  from public.fame_coin_store_products product
  where product.platform = v_platform
    and product.product_id = p_product_id
    and product.active = true;

  if v_product.product_id is null then
    raise exception 'unknown or inactive store product' using errcode = '22023';
  end if;

  insert into public.fame_coin_store_transactions (
    user_id,
    platform,
    product_id,
    transaction_id,
    original_transaction_id,
    environment,
    app_account_token,
    coins,
    status,
    purchase_date
  ) values (
    p_user_id,
    v_platform,
    v_product.product_id,
    p_transaction_id,
    nullif(btrim(coalesce(p_original_transaction_id, '')), ''),
    nullif(btrim(coalesce(p_environment, '')), ''),
    nullif(btrim(coalesce(p_app_account_token, '')), ''),
    v_product.coins,
    'processing',
    p_purchase_date
  )
  on conflict (platform, transaction_id) do nothing
  returning id into v_tx_id;

  if v_tx_id is null then
    select * into v_existing
    from public.fame_coin_store_transactions tx
    where tx.platform = v_platform
      and tx.transaction_id = p_transaction_id;

    if v_existing.user_id <> p_user_id then
      raise exception 'store transaction belongs to another account' using errcode = '42501';
    end if;

    if v_existing.status <> 'completed' then
      raise exception 'store transaction is not complete' using errcode = '55000';
    end if;

    select wallet.balance into v_balance
    from public.beta_coin_wallets wallet
    where wallet.user_id = p_user_id;

    return query select coalesce(v_balance, 0), v_existing.coins, true;
    return;
  end if;

  insert into public.beta_coin_wallets (user_id, balance)
  values (p_user_id, 0)
  on conflict (user_id) do nothing;

  select wallet.balance into v_balance
  from public.beta_coin_wallets wallet
  where wallet.user_id = p_user_id
  for update;

  update public.beta_coin_wallets
  set balance = balance + v_product.coins,
      updated_at = now()
  where user_id = p_user_id
  returning balance into v_balance;

  insert into public.beta_coin_ledger (
    user_id,
    delta,
    balance_after,
    event_type
  ) values (
    p_user_id,
    v_product.coins,
    v_balance,
    'purchase'
  );

  update public.fame_coin_store_transactions
  set status = 'completed',
      completed_at = now()
  where id = v_tx_id;

  return query select v_balance, v_product.coins, false;
end;
$$;

revoke all on function public.finalize_fame_coin_store_purchase(
  uuid, text, text, text, text, text, text, timestamptz
) from public, anon, authenticated;
grant execute on function public.finalize_fame_coin_store_purchase(
  uuid, text, text, text, text, text, text, timestamptz
) to service_role;
