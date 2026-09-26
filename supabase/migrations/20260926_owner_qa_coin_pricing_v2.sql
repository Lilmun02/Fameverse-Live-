-- Fameverse owner PayPal sandbox recharge pricing for the current native QA candidate.
-- The visible fixed packages match the approved reference: 100 / 1,000 / 5,000.
-- Custom purchases stay available separately and are priced server-side.

update public.coin_recharge_packs
set active = false,
    updated_at = now()
where owner_only = true
  and id like 'owner-qa-%';

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
  ('owner-qa-100', '100 Fame Coins', 100, 99, 'USD', true, true, 10),
  ('owner-qa-1000', '1,000 Fame Coins', 1000, 999, 'USD', true, true, 20),
  ('owner-qa-5000', '5,000 Fame Coins', 5000, 4999, 'USD', true, true, 30),
  ('owner-qa-custom', 'Custom Fame Coins', 100, 100, 'USD', true, true, 999)
on conflict (id) do update set
  label = excluded.label,
  coins = excluded.coins,
  price_cents = excluded.price_cents,
  currency = excluded.currency,
  active = excluded.active,
  owner_only = excluded.owner_only,
  sort_order = excluded.sort_order,
  updated_at = now();
