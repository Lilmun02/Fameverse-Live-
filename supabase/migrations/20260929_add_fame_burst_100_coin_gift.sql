insert into public.fameverse_gift_catalog (
  id,
  label,
  cost_coins,
  category,
  symbol,
  cinematic,
  video_url,
  active,
  sort_order,
  updated_at
) values (
  'fame-burst',
  'Fame Burst',
  100,
  'fameverse',
  '✦',
  false,
  null,
  true,
  905,
  now()
)
on conflict (id) do update set
  label = excluded.label,
  cost_coins = excluded.cost_coins,
  category = excluded.category,
  symbol = excluded.symbol,
  cinematic = excluded.cinematic,
  video_url = excluded.video_url,
  active = excluded.active,
  sort_order = excluded.sort_order,
  updated_at = now();
