alter table public.coin_recharge_packs
  add column if not exists stripe_test_price_id text,
  add column if not exists stripe_live_price_id text;

alter table public.coin_recharge_orders
  drop constraint if exists coin_recharge_provider_check;

alter table public.coin_recharge_orders
  add constraint coin_recharge_provider_check
  check (provider = any (array['paypal'::text, 'stripe'::text]));

create unique index if not exists coin_recharge_packs_stripe_test_price_uidx
  on public.coin_recharge_packs (stripe_test_price_id)
  where stripe_test_price_id is not null;

create unique index if not exists coin_recharge_packs_stripe_live_price_uidx
  on public.coin_recharge_packs (stripe_live_price_id)
  where stripe_live_price_id is not null;

insert into public.coin_recharge_packs (
  id,
  label,
  coins,
  price_cents,
  currency,
  active,
  owner_only,
  sort_order,
  stripe_test_price_id,
  stripe_live_price_id
)
values
  ('stripe-100', '100 Fame Coins', 100, 99, 'USD', true, false, 110, 'price_1ULs5AGeOlZfST4EbpHKcr6j', 'price_1ULs4YKIbh48nm6iNMWTr860'),
  ('stripe-1000', '1,000 Fame Coins', 1000, 999, 'USD', true, false, 130, 'price_1ULs5EGeOlZfST4E1sqkDTLA', 'price_1ULs4oKIbh48nm6i1P88Rfu3'),
  ('stripe-5000', '5,000 Fame Coins', 5000, 4999, 'USD', true, false, 150, 'price_1ULs5IGeOlZfST4EZhBlpPQk', 'price_1ULs4sKIbh48nm6iDAaH6nL3')
on conflict (id) do update set
  label = excluded.label,
  coins = excluded.coins,
  price_cents = excluded.price_cents,
  currency = excluded.currency,
  active = excluded.active,
  owner_only = excluded.owner_only,
  sort_order = excluded.sort_order,
  stripe_test_price_id = excluded.stripe_test_price_id,
  stripe_live_price_id = excluded.stripe_live_price_id,
  updated_at = now();
