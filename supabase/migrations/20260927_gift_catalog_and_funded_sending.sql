begin;

create table if not exists public.fameverse_gift_catalog (
  id text primary key,
  label text not null,
  cost_coins integer not null check (cost_coins > 0),
  category text not null,
  symbol text not null,
  cinematic boolean not null default false,
  video_url text,
  active boolean not null default true,
  sort_order integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.fameverse_gift_catalog enable row level security;
revoke all on public.fameverse_gift_catalog from anon, authenticated;

delete from public.fameverse_gift_catalog;

insert into public.fameverse_gift_catalog
  (id,label,cost_coins,category,symbol,cinematic,video_url,active,sort_order)
values
  ('rose','Rose',1,'classic','🌹',false,null,true,1),
  ('heart','Heart',1,'classic','💜',false,null,true,2),
  ('fire','Fire',1,'classic','🔥',false,null,true,3),
  ('star','Star',1,'classic','⭐',false,null,true,4),
  ('crown','Crown',1,'classic','👑',false,null,true,5),
  ('sparkle','Sparkle',2,'reactions','✨',false,null,true,10),
  ('clap','Clap',2,'reactions','👏',false,null,true,11),
  ('smile','Smile',2,'reactions','😊',false,null,true,12),
  ('cool','Cool',3,'reactions','😎',false,null,true,13),
  ('laugh','Laugh',3,'reactions','😂',false,null,true,14),
  ('party','Party',3,'reactions','🎉',false,null,true,15),
  ('coffee','Coffee',5,'snacks','☕',false,null,true,20),
  ('cookie','Cookie',5,'snacks','🍪',false,null,true,21),
  ('cupcake','Cupcake',5,'snacks','🧁',false,null,true,22),
  ('donut','Donut',5,'snacks','🍩',false,null,true,23),
  ('pizza','Pizza',5,'snacks','🍕',false,null,true,24),
  ('taco','Taco',5,'snacks','🌮',false,null,true,25),
  ('popcorn','Popcorn',5,'snacks','🍿',false,null,true,26),
  ('strawberry','Strawberry',5,'snacks','🍓',false,null,true,27),
  ('cherry','Cherries',5,'snacks','🍒',false,null,true,28),
  ('sunflower','Sunflower',7,'flowers','🌻',false,null,true,30),
  ('tulip','Tulip',7,'flowers','🌷',false,null,true,31),
  ('bouquet','Bouquet',10,'flowers','💐',false,null,true,32),
  ('balloon','Balloon',10,'celebrate','🎈',false,null,true,40),
  ('confetti','Confetti',10,'celebrate','🎊',false,null,true,41),
  ('music','Music',10,'creator','🎵',false,null,true,42),
  ('headphones','Headphones',12,'creator','🎧',false,null,true,43),
  ('microphone','Microphone',12,'creator','🎤',false,null,true,44),
  ('gamepad','Gamepad',12,'creator','🎮',false,null,true,45),
  ('camera','Camera',12,'creator','📸',false,null,true,46),
  ('football','Football',15,'sports','🏈',false,null,true,50),
  ('basketball','Basketball',15,'sports','🏀',false,null,true,51),
  ('soccer','Soccer Ball',15,'sports','⚽',false,null,true,52),
  ('baseball','Baseball',15,'sports','⚾',false,null,true,53),
  ('gem','Gem',20,'fame','💎',false,null,true,60),
  ('rocket','Rocket',20,'fame','🚀',false,null,true,61),
  ('moon','Moon',20,'fame','🌙',false,null,true,62),
  ('rainbow','Rainbow',20,'fame','🌈',false,null,true,63),
  ('butterfly','Butterfly',20,'fame','🦋',false,null,true,64),
  ('unicorn','Unicorn',25,'fame','🦄',false,null,true,65),
  ('panda','Panda',25,'animals','🐼',false,null,true,70),
  ('lion','Lion',25,'animals','🦁',false,null,true,71),
  ('dolphin','Dolphin',25,'animals','🐬',false,null,true,72),
  ('sunglasses','Sunglasses',30,'fame','🕶️',false,null,true,80),
  ('gold-medal','Gold Medal',30,'fame','🥇',false,null,true,81),
  ('trophy','Trophy',35,'fame','🏆',false,null,true,82),
  ('party-face','Party Face',35,'celebrate','🥳',false,null,true,83),
  ('crystal-ball','Crystal Ball',40,'fame','🔮',false,null,true,84),
  ('purple-heart','Purple Heart',40,'fame','💜',false,null,true,85),
  ('lightning','Lightning',45,'fame','⚡',false,null,true,86),
  ('planet','Planet',50,'fame','🪐',false,null,true,87),
  ('shooting-star','Shooting Star',60,'fame','🌠',false,null,true,88),
  ('castle','Castle',70,'fame','🏰',false,null,true,89),
  ('race-car','Race Car',75,'fame','🏎️',false,null,true,90),
  ('airplane','Airplane',80,'fame','✈️',false,null,true,91),
  ('helicopter','Helicopter',85,'fame','🚁',false,null,true,92),
  ('yacht','Yacht',90,'fame','🛥️',false,null,true,93),
  ('galaxy','Galaxy',99,'fame','🌌',false,null,true,94),
  ('welcome-to-fameverse','Welcome to Fameverse',100,'fameverse','✦',true,
   'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/8d3fd7e2-9073-4e1b-8ef6-843a1514aae6.mp4',true,100),
  ('ember-dragon','Ember Dragon',1000,'fameverse','🐉',true,
   'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/6ef5d526-e0d8-42ca-a382-28d53d3fe2aa.mp4',true,110),
  ('celestial-phoenix','Celestial Phoenix',1000,'fameverse','🔥',true,
   'https://d2ol7oe51mr4n9.cloudfront.net/user_3IL6AXXAqcrsLZJmbjvrquIP0Bd/e4da59e7-2d55-4ee2-b546-cae61cf56de3.mp4',true,111),
  ('pocket-comet','Pocket Comet',1000,'fameverse','☄️',true,null,true,112)
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

create or replace function public.get_fameverse_gift_catalog()
returns table (
  gift_id text,
  label text,
  cost_coins integer,
  category text,
  symbol text,
  cinematic boolean,
  video_url text
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select gift.id, gift.label, gift.cost_coins, gift.category, gift.symbol,
         gift.cinematic, gift.video_url
  from public.fameverse_gift_catalog gift
  where gift.active = true
  order by gift.sort_order, gift.cost_coins, gift.label;
$$;

-- Only the cash-backed portion of a mixed gift creates normal creator earnings.
-- Promotional/referral coins can still animate and count as engagement without
-- generating a cash liability Fameverse never collected.
create or replace function public._apply_creator_cash_coin_share(
  p_gift_event_id uuid,
  p_cash_backed_coins bigint
)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_creator uuid;
  v_creator_bps integer;
  v_gross_micros bigint;
  v_creator_micros bigint;
  v_platform_micros bigint;
  v_remainder bigint;
  v_total_micros bigint;
  v_post_cents bigint;
begin
  if coalesce(p_cash_backed_coins, 0) <= 0 then
    return 0;
  end if;

  if exists (
    select 1 from public.creator_gift_share_accruals accrual
    where accrual.gift_event_id = p_gift_event_id
  ) then
    select accrual.creator_micros into v_creator_micros
    from public.creator_gift_share_accruals accrual
    where accrual.gift_event_id = p_gift_event_id;
    return coalesce(v_creator_micros, 0);
  end if;

  select event.recipient_user_id into v_creator
  from public.gift_events event
  where event.id = p_gift_event_id;

  if v_creator is null then
    raise exception 'gift event unavailable for earnings' using errcode = 'P0002';
  end if;

  select config.creator_share_bps into v_creator_bps
  from public.fameverse_economy_config config
  where config.id = true;

  if v_creator_bps <> 7000 then
    raise exception 'creator split configuration is not the locked 70 percent' using errcode = '22023';
  end if;

  -- One cash-backed Fame Coin represents one US cent of gross gift value.
  v_gross_micros := p_cash_backed_coins * 10000;
  v_creator_micros := (v_gross_micros * v_creator_bps) / 10000;
  v_platform_micros := v_gross_micros - v_creator_micros;

  insert into public.creator_gift_share_accruals (
    gift_event_id, creator_user_id, source_type, gross_coins, gross_micros,
    creator_share_bps, creator_micros, platform_micros
  ) values (
    p_gift_event_id, v_creator, 'paid_gift', p_cash_backed_coins,
    v_gross_micros, v_creator_bps, v_creator_micros, v_platform_micros
  );

  perform pg_advisory_xact_lock(hashtextextended(v_creator::text, 7000));

  insert into public.creator_earnings_fractional (creator_user_id, remainder_micros)
  values (v_creator, 0)
  on conflict (creator_user_id) do nothing;

  select remainder_micros into v_remainder
  from public.creator_earnings_fractional
  where creator_user_id = v_creator
  for update;

  v_total_micros := coalesce(v_remainder, 0) + v_creator_micros;
  v_post_cents := v_total_micros / 10000;
  v_remainder := mod(v_total_micros, 10000);

  update public.creator_earnings_fractional
  set remainder_micros = v_remainder,
      updated_at = now()
  where creator_user_id = v_creator;

  if v_post_cents > 0 then
    insert into public.creator_earnings_ledger (
      creator_user_id, amount_cents, state, source_type, source_key, note, available_at
    ) values (
      v_creator, v_post_cents, 'available', 'gift_share',
      'gift_share:' || p_gift_event_id::text,
      'Creator share from the cash-backed portion of a Fameverse gift',
      now()
    );
  end if;

  return v_creator_micros;
end;
$$;

alter table public.gift_funding_breakdowns
  add column if not exists creator_earning_micros bigint not null default 0
  check (creator_earning_micros >= 0);

create or replace function public.send_fameverse_gift(
  p_room_id uuid,
  p_gift_id text,
  p_quantity integer
)
returns table (
  total_coins_sent bigint,
  gift_count bigint,
  level integer,
  wallet_balance bigint,
  cash_backed_coins_spent bigint,
  promo_coins_spent bigint,
  creator_earning_micros bigint,
  owner_promo_bonus_cents bigint
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_sender uuid := auth.uid();
  v_sender_role text;
  v_recipient uuid;
  v_unit_cost integer;
  v_total bigint;
  v_balance bigint;
  v_gift_event_id uuid;
  v_cash_balance bigint;
  v_promo_balance bigint;
  v_cash_spent bigint;
  v_promo_spent bigint;
  v_creator_micros bigint := 0;
  v_owner_bonus bigint := 0;
  v_reserve bigint;
begin
  if v_sender is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > 100000 then
    raise exception 'invalid gift quantity' using errcode = '22023';
  end if;

  select gift.cost_coins into v_unit_cost
  from public.fameverse_gift_catalog gift
  where gift.id = p_gift_id and gift.active = true;

  if v_unit_cost is null then
    raise exception 'unknown gift' using errcode = '22023';
  end if;

  select room.host_user_id into v_recipient
  from public.live_rooms room
  where room.id = p_room_id
    and room.status = 'live'
    and room.ended_at is null;

  if v_recipient is null then
    raise exception 'live room is not active' using errcode = 'P0002';
  end if;
  if v_sender = v_recipient then
    raise exception 'self gifting is not allowed' using errcode = '42501';
  end if;

  v_total := v_unit_cost::bigint * p_quantity::bigint;
  if v_total <= 0 then
    raise exception 'invalid gift total' using errcode = '22023';
  end if;

  perform public._ensure_fame_coin_wallet(v_sender);
  perform pg_advisory_xact_lock(hashtextextended('fv-coin:' || v_sender::text, 0));

  select funding.cash_backed_coins, funding.promo_coins
    into v_cash_balance, v_promo_balance
  from public.coin_funding_balances funding
  where funding.user_id = v_sender
  for update;

  -- Promotional coins are intentionally spent first. Users still see one
  -- simple Fame Coin balance while the ledger preserves funding provenance.
  v_promo_spent := least(coalesce(v_promo_balance, 0), v_total);
  v_cash_spent := v_total - v_promo_spent;

  if coalesce(v_cash_balance, 0) < v_cash_spent then
    raise exception 'insufficient Fame Coin balance' using errcode = '22003';
  end if;

  insert into public.gift_events (
    room_id, sender_user_id, recipient_user_id, gift_id, quantity, coins_spent
  ) values (
    p_room_id, v_sender, v_recipient, p_gift_id, p_quantity, v_total
  ) returning id into v_gift_event_id;

  v_balance := public._credit_fame_coins(
    v_sender,
    -v_cash_spent,
    -v_promo_spent,
    'gift_send',
    'gift-send:' || v_gift_event_id::text
  );

  update public.coin_funding_ledger
  set gift_event_id = v_gift_event_id
  where event_key = 'gift-send:' || v_gift_event_id::text;

  insert into public.beta_coin_ledger (
    user_id, delta, balance_after, event_type, gift_event_id
  ) values (
    v_sender, -v_total, v_balance, 'gift_send', v_gift_event_id
  );

  insert into public.gifter_stats (
    user_id, total_coins_sent, gift_count, level, updated_at
  ) values (
    v_sender, v_total, p_quantity, public.compute_gifter_level(v_total), now()
  )
  on conflict (user_id) do update set
    total_coins_sent = public.gifter_stats.total_coins_sent + excluded.total_coins_sent,
    gift_count = public.gifter_stats.gift_count + excluded.gift_count,
    level = public.compute_gifter_level(public.gifter_stats.total_coins_sent + excluded.total_coins_sent),
    updated_at = now();

  if v_cash_spent > 0 then
    v_creator_micros := public._apply_creator_cash_coin_share(
      v_gift_event_id, v_cash_spent
    );
  end if;

  select role_row.role into v_sender_role
  from public.account_roles role_row
  where role_row.user_id = v_sender;

  -- Owner/admin promotional gifts are engagement-first. Their promotional
  -- portion can award only a tiny explicitly funded creator bonus: 1 promo
  -- coin -> 1 cent, while any larger promo amount is capped at five cents.
  if v_promo_spent > 0 and coalesce(v_sender_role, '') in ('owner', 'admin') then
    v_owner_bonus := least(v_promo_spent, 5);

    perform pg_advisory_xact_lock(hashtextextended('fameverse-cash-reward-reserve', 0));
    select reserve.available_gross_cents into v_reserve
    from public.cash_reward_reserve reserve
    where reserve.id = true
    for update;

    if coalesce(v_reserve, 0) >= v_owner_bonus and v_owner_bonus > 0 then
      update public.cash_reward_reserve
      set available_gross_cents = available_gross_cents - v_owner_bonus,
          lifetime_allocated_gross_cents = lifetime_allocated_gross_cents + v_owner_bonus,
          updated_at = now(),
          updated_by = v_sender
      where id = true
      returning available_gross_cents into v_reserve;

      insert into public.cash_reward_reserve_ledger (
        delta_gross_cents, balance_after_gross_cents, event_type,
        gift_event_id, actor_user_id, note
      ) values (
        -v_owner_bonus, v_reserve, 'owner_promo_bonus',
        v_gift_event_id, v_sender,
        'Tiny funded creator bonus for owner/admin promotional gift'
      );

      insert into public.creator_earnings_ledger (
        creator_user_id, amount_cents, state, source_type, source_key, note, available_at
      ) values (
        v_recipient, v_owner_bonus, 'available', 'owner_promo_bonus',
        'owner_promo_bonus:' || v_gift_event_id::text,
        'Fameverse promotional gift creator bonus', now()
      )
      on conflict (source_key) do nothing;
    else
      -- No reserve means no hidden liability. The gift still delivers as
      -- engagement, but Fameverse does not pretend unfunded promo coins are cash.
      v_owner_bonus := 0;
    end if;
  end if;

  insert into public.gift_funding_breakdowns (
    gift_event_id, cash_backed_coins, promo_coins, creator_earning_cents,
    creator_earning_micros, funding_rule
  ) values (
    v_gift_event_id,
    v_cash_spent,
    v_promo_spent,
    (v_creator_micros / 10000)::bigint + v_owner_bonus,
    v_creator_micros + (v_owner_bonus * 10000),
    'promo_first'
  );

  return query
  select stats.total_coins_sent,
         stats.gift_count,
         stats.level,
         v_balance,
         v_cash_spent,
         v_promo_spent,
         v_creator_micros,
         v_owner_bonus
  from public.gifter_stats stats
  where stats.user_id = v_sender;
end;
$$;

-- Legacy owner/admin QA callers remain supported, but the authoritative send
-- logic above owns balance attribution and creator-earnings rules.
create or replace function public.record_beta_gift(
  p_room_id uuid,
  p_gift_id text,
  p_quantity integer
)
returns table(total_coins_sent bigint, gift_count bigint, level integer, wallet_balance bigint)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_sender uuid := auth.uid();
  v_role text;
begin
  select role_row.role into v_role
  from public.account_roles role_row
  where role_row.user_id = v_sender;

  if coalesce(v_role, '') not in ('owner', 'admin') then
    raise exception 'beta gift sending requires owner or admin role' using errcode = '42501';
  end if;

  return query
  select result.total_coins_sent, result.gift_count, result.level, result.wallet_balance
  from public.send_fameverse_gift(p_room_id, p_gift_id, p_quantity) result;
end;
$$;

-- Owner/admin test refills remain promotional and therefore never become
-- normal creator earnings when spent.
create or replace function public.refill_beta_wallet(p_amount integer default 10000)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_role text;
  v_balance bigint;
  v_event_key text;
begin
  if v_user_id is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select role_row.role into v_role
  from public.account_roles role_row
  where role_row.user_id = v_user_id;

  if coalesce(v_role, '') not in ('owner', 'admin') then
    raise exception 'beta refill requires owner or admin role' using errcode = '42501';
  end if;
  if p_amount <> 10000 then
    raise exception 'beta refill amount must be 10000' using errcode = '22023';
  end if;

  v_event_key := 'qa-refill:' || v_user_id::text || ':' || gen_random_uuid()::text;
  v_balance := public._credit_fame_coins(
    v_user_id, 0, p_amount, 'qa_refill', v_event_key
  );

  insert into public.beta_coin_ledger(user_id, delta, balance_after, event_type)
  values(v_user_id, p_amount, v_balance, 'refill');

  return v_balance;
end;
$$;

revoke all on function public.get_fameverse_gift_catalog() from public;
revoke all on function public._apply_creator_cash_coin_share(uuid,bigint) from public;
revoke all on function public.send_fameverse_gift(uuid,text,integer) from public;
revoke all on function public.record_beta_gift(uuid,text,integer) from public;
revoke all on function public.refill_beta_wallet(integer) from public;

grant execute on function public.get_fameverse_gift_catalog() to authenticated;
grant execute on function public.send_fameverse_gift(uuid,text,integer) to authenticated;
grant execute on function public.record_beta_gift(uuid,text,integer) to authenticated;
grant execute on function public.refill_beta_wallet(integer) to authenticated;

comment on table public.fameverse_gift_catalog is
  'Authoritative Fameverse gift catalog. Lightweight gifts under 100 coins are non-cinematic.';
comment on function public.send_fameverse_gift(uuid,text,integer) is
  'Authoritative gift send: promo-first funding, cash-only 70/30 earnings, self-gift blocked.';

commit;
