-- Fameverse owner PayPal sandbox recharge pricing for the current native QA candidate.
-- Public production economics remain separate; these packs are owner-only while
-- PayPal remains in sandbox. Fixed packs keep the approved ~100 coins per $1
-- baseline. Custom purchases use the owner-qa-custom placeholder pack and the
-- Edge Function calculates the exact amount server-side.

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
  ('owner-qa-500', '500 Fame Coins', 500, 499, 'USD', true, true, 20),
  ('owner-qa-1000', '1,000 Fame Coins', 1000, 999, 'USD', true, true, 30),
  ('owner-qa-2500', '2,500 Fame Coins', 2500, 2499, 'USD', true, true, 40),
  ('owner-qa-5000', '5,000 Fame Coins', 5000, 4999, 'USD', true, true, 50),
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
