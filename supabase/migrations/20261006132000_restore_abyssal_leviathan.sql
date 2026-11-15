begin;

insert into public.fameverse_gift_catalog
  (id, label, cost_coins, category, symbol, cinematic, video_url, active, sort_order)
values
  (
    'abyssal-leviathan',
    'Abyssal Leviathan',
    5000,
    'fameverse',
    '🐋',
    true,
    'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/5f7cc621-ffd0-4edd-b585-56ec76a0907e.mp4',
    true,
    113
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

commit;
