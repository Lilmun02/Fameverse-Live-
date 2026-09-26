-- Build 16 internal QA-only Fame Coin recharge packages.
-- These values are intentionally not the public Fame Coin economy.
-- They are visible only to the Fameverse owner while PayPal remains in sandbox.
-- QA pricing preserves the intended baseline of about 100 Fame Coins per $1.

update public.coin_recharge_packs
set active = false,
    updated_at = now()
where id = 'owner-qa-99c';

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
values
  ('owner-qa-100', 'QA Starter', 100, 99, 'USD', true, true, 10),
  ('owner-qa-1000', 'QA Gift Pack', 1000, 999, 'USD', true, true, 20),
  ('owner-qa-5000', 'QA Stress Pack', 5000, 4999, 'USD', true, true, 30)
on conflict (id) do update set
  label = excluded.label,
  coins = excluded.coins,
  price_cents = excluded.price_cents,
  currency = excluded.currency,
  active = excluded.active,
  owner_only = excluded.owner_only,
  sort_order = excluded.sort_order,
  updated_at = now();
