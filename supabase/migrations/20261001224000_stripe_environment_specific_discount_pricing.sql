-- Fameverse Stripe environment-specific pricing.
--
-- Product decision (2026-10-01): Stripe test checkout may validate the planned
-- ~30% discount before any live Stripe price is changed. The matching Apple
-- target prices are configured in App Store Connect, not in this database.
--
-- Locked economy reminder: 100 Fame Coins = $1 gross gift value and creators
-- receive 70% of cash-backed gift value. Stripe test prices below are selected
-- to remain above creator liability after standard domestic-card processing.

alter table public.coin_recharge_packs
  add column if not exists stripe_test_price_cents integer,
  add column if not exists stripe_live_price_cents integer;

alter table public.coin_recharge_packs
  drop constraint if exists coin_recharge_packs_stripe_test_price_positive;
alter table public.coin_recharge_packs
  add constraint coin_recharge_packs_stripe_test_price_positive
  check (stripe_test_price_cents is null or stripe_test_price_cents > 0);

alter table public.coin_recharge_packs
  drop constraint if exists coin_recharge_packs_stripe_live_price_positive;
alter table public.coin_recharge_packs
  add constraint coin_recharge_packs_stripe_live_price_positive
  check (stripe_live_price_cents is null or stripe_live_price_cents > 0);

-- Test-mode prices are approximately 30% below the approved Apple target:
--   100 coins: Apple target $1.99 -> Stripe test $1.39
-- 1,000 coins: Apple target $12.99 -> Stripe test $9.09
-- 5,000 coins: Apple target $59.99 -> Stripe test $41.99
--
-- Live Stripe remains on its existing price objects until sandbox purchase,
-- webhook fulfillment, wallet credit, and physical-device QA pass.
update public.coin_recharge_packs
set stripe_test_price_cents = 139,
    stripe_live_price_cents = 99,
    stripe_test_price_id = 'price_1ULsXqGeOlZfST4Ee00wiGch',
    stripe_live_price_id = 'price_1ULs4YKIbh48nm6iNMWTr860'
where id = 'stripe-100';

update public.coin_recharge_packs
set stripe_test_price_cents = 909,
    stripe_live_price_cents = 999,
    stripe_test_price_id = 'price_1ULsXuGeOlZfST4EGJPGeDKe',
    stripe_live_price_id = 'price_1ULs4oKIbh48nm6i1P88Rfu3'
where id = 'stripe-1000';

update public.coin_recharge_packs
set stripe_test_price_cents = 4199,
    stripe_live_price_cents = 4999,
    stripe_test_price_id = 'price_1ULsXzGeOlZfST4EUHiURh4p',
    stripe_live_price_id = 'price_1ULs4sKIbh48nm6iDAaH6nL3'
where id = 'stripe-5000';

comment on column public.coin_recharge_packs.stripe_test_price_cents is
  'Authoritative Stripe Checkout amount for STRIPE_ENVIRONMENT=test.';
comment on column public.coin_recharge_packs.stripe_live_price_cents is
  'Authoritative Stripe Checkout amount for STRIPE_ENVIRONMENT=live.';
