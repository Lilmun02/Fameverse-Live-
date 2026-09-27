-- Fameverse cash-backed reward reserve + 70/30 creator gift share.
-- Product law: 100 Fame Coins = $1 gross gift value; creator share 70%; platform share 30%.
-- Owner/admin test coins remain free to mint, but cash-eligible staff gifts require funded reward reserve.

create table if not exists public.fameverse_economy_config (
  id boolean primary key default true check (id),
  coins_per_usd integer not null default 100 check (coins_per_usd > 0),
  creator_share_bps integer not null default 7000 check (creator_share_bps between 0 and 10000),
  platform_share_bps integer not null default 3000 check (platform_share_bps between 0 and 10000),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null,
  constraint fameverse_economy_split_check check (creator_share_bps + platform_share_bps = 10000)
);

insert into public.fameverse_economy_config (id, coins_per_usd, creator_share_bps, platform_share_bps)
values (true, 100, 7000, 3000)
on conflict (id) do nothing;

create table if not exists public.cash_reward_reserve (
  id boolean primary key default true check (id),
  available_gross_cents bigint not null default 0 check (available_gross_cents >= 0),
  lifetime_allocated_gross_cents bigint not null default 0 check (lifetime_allocated_gross_cents >= 0),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);

insert into public.cash_reward_reserve (id)
values (true)
on conflict (id) do nothing;

create table if not exists public.cash_reward_reserve_ledger (
  id uuid primary key default gen_random_uuid(),
  delta_gross_cents bigint not null,
  balance_after_gross_cents bigint not null check (balance_after_gross_cents >= 0),
  event_type text not null check (event_type in ('allocate_funds', 'cash_reward_gift', 'reward_reversal', 'owner_adjustment')),
  gift_event_id uuid references public.gift_events(id) on delete set null,
  actor_user_id uuid references public.profiles(id) on delete set null,
  note text,
  created_at timestamptz not null default now(),
  constraint cash_reward_reserve_note_length_check check (note is null or char_length(note) <= 500)
);

create index if not exists cash_reward_reserve_ledger_created_idx
  on public.cash_reward_reserve_ledger(created_at desc);

create table if not exists public.staff_cash_reward_permissions (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  cash_rewards_enabled boolean not null default false,
  max_gross_cents_per_gift bigint not null default 100 check (max_gross_cents_per_gift between 1 and 10000000),
  updated_at timestamptz not null default now(),
  updated_by uuid references public.profiles(id) on delete set null
);

create table if not exists public.creator_gift_share_accruals (
  gift_event_id uuid primary key references public.gift_events(id) on delete cascade,
  creator_user_id uuid not null references public.profiles(id) on delete cascade,
  source_type text not null check (source_type in ('operator_reward', 'paid_gift')),
  gross_coins bigint not null check (gross_coins > 0),
  gross_micros bigint not null check (gross_micros > 0),
  creator_share_bps integer not null check (creator_share_bps between 0 and 10000),
  creator_micros bigint not null check (creator_micros >= 0),
  platform_micros bigint not null check (platform_micros >= 0),
  created_at timestamptz not null default now()
);

create index if not exists creator_gift_share_creator_created_idx
  on public.creator_gift_share_accruals(creator_user_id, created_at desc);

create table if not exists public.creator_earnings_fractional (
  creator_user_id uuid primary key references public.profiles(id) on delete cascade,
  remainder_micros bigint not null default 0 check (remainder_micros between 0 and 9999),
  updated_at timestamptz not null default now()
);

alter table public.fameverse_economy_config enable row level security;
alter table public.cash_reward_reserve enable row level security;
alter table public.cash_reward_reserve_ledger enable row level security;
alter table public.staff_cash_reward_permissions enable row level security;
alter table public.creator_gift_share_accruals enable row level security;
alter table public.creator_earnings_fractional enable row level security;

drop policy if exists "economy config is readable" on public.fameverse_economy_config;
create policy "economy config is readable"
on public.fameverse_economy_config for select
to authenticated
using (true);

drop policy if exists "owner can read cash reward reserve" on public.cash_reward_reserve;
create policy "owner can read cash reward reserve"
on public.cash_reward_reserve for select
to authenticated
using (exists (
  select 1 from public.account_roles r
  where r.user_id = auth.uid() and r.role = 'owner'
));

drop policy if exists "owner can read cash reward ledger" on public.cash_reward_reserve_ledger;
create policy "owner can read cash reward ledger"
on public.cash_reward_reserve_ledger for select
to authenticated
using (exists (
  select 1 from public.account_roles r
  where r.user_id = auth.uid() and r.role = 'owner'
));

drop policy if exists "staff can read own cash reward permission" on public.staff_cash_reward_permissions;
create policy "staff can read own cash reward permission"
on public.staff_cash_reward_permissions for select
to authenticated
using (
  user_id = auth.uid()
  or exists (
    select 1 from public.account_roles r
    where r.user_id = auth.uid() and r.role = 'owner'
  )
);

drop policy if exists "creator can read own gift share accruals" on public.creator_gift_share_accruals;
create policy "creator can read own gift share accruals"
on public.creator_gift_share_accruals for select
to authenticated
using (
  creator_user_id = auth.uid()
  or exists (
    select 1 from public.account_roles r
    where r.user_id = auth.uid() and r.role = 'owner'
  )
);

drop policy if exists "creator can read own fractional earnings" on public.creator_earnings_fractional;
create policy "creator can read own fractional earnings"
on public.creator_earnings_fractional for select
to authenticated
using (
  creator_user_id = auth.uid()
  or exists (
    select 1 from public.account_roles r
    where r.user_id = auth.uid() and r.role = 'owner'
  )
);

revoke all privileges on public.fameverse_economy_config from anon, authenticated;
revoke all privileges on public.cash_reward_reserve from anon, authenticated;
revoke all privileges on public.cash_reward_reserve_ledger from anon, authenticated;
revoke all privileges on public.staff_cash_reward_permissions from anon, authenticated;
revoke all privileges on public.creator_gift_share_accruals from anon, authenticated;
revoke all privileges on public.creator_earnings_fractional from anon, authenticated;

grant select on public.fameverse_economy_config to authenticated;
grant select on public.cash_reward_reserve to authenticated;
grant select on public.cash_reward_reserve_ledger to authenticated;
grant select on public.staff_cash_reward_permissions to authenticated;
grant select on public.creator_gift_share_accruals to authenticated;
grant select on public.creator_earnings_fractional to authenticated;

create or replace function public.owner_allocate_reward_reserve(
  p_amount_cents bigint,
  p_note text default null
)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner uuid := auth.uid();
  v_balance bigint;
begin
  if not exists (
    select 1 from public.account_roles r
    where r.user_id = v_owner and r.role = 'owner'
  ) then
    raise exception 'owner access required' using errcode = '42501';
  end if;

  if p_amount_cents is null or p_amount_cents <= 0 then
    raise exception 'reward reserve amount must be positive' using errcode = '22023';
  end if;

  if p_note is not null and char_length(p_note) > 500 then
    raise exception 'reward reserve note too long' using errcode = '22023';
  end if;

  perform pg_advisory_xact_lock(hashtextextended('fameverse-cash-reward-reserve', 0));

  update public.cash_reward_reserve
  set available_gross_cents = available_gross_cents + p_amount_cents,
      updated_at = now(),
      updated_by = v_owner
  where id = true
  returning available_gross_cents into v_balance;

  insert into public.cash_reward_reserve_ledger (
    delta_gross_cents,
    balance_after_gross_cents,
    event_type,
    actor_user_id,
    note
  ) values (
    p_amount_cents,
    v_balance,
    'allocate_funds',
    v_owner,
    nullif(trim(coalesce(p_note, '')), '')
  );

  return v_balance;
end;
$$;

create or replace function public.owner_set_staff_cash_reward(
  p_user_id uuid,
  p_enabled boolean,
  p_max_gross_cents_per_gift bigint default 100
)
returns table (
  user_id uuid,
  cash_rewards_enabled boolean,
  max_gross_cents_per_gift bigint
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner uuid := auth.uid();
  v_role text;
begin
  if not exists (
    select 1 from public.account_roles r
    where r.user_id = v_owner and r.role = 'owner'
  ) then
    raise exception 'owner access required' using errcode = '42501';
  end if;

  select r.role into v_role
  from public.account_roles r
  where r.user_id = p_user_id;

  if coalesce(v_role, '') not in ('owner', 'admin') then
    raise exception 'cash reward permission requires owner or admin role' using errcode = '22023';
  end if;

  if p_max_gross_cents_per_gift is null or p_max_gross_cents_per_gift < 1 then
    raise exception 'invalid cash reward gift cap' using errcode = '22023';
  end if;

  insert into public.staff_cash_reward_permissions (
    user_id, cash_rewards_enabled, max_gross_cents_per_gift, updated_at, updated_by
  ) values (
    p_user_id, coalesce(p_enabled, false), p_max_gross_cents_per_gift, now(), v_owner
  )
  on conflict (user_id) do update set
    cash_rewards_enabled = excluded.cash_rewards_enabled,
    max_gross_cents_per_gift = excluded.max_gross_cents_per_gift,
    updated_at = now(),
    updated_by = v_owner;

  return query
  select p.user_id, p.cash_rewards_enabled, p.max_gross_cents_per_gift
  from public.staff_cash_reward_permissions p
  where p.user_id = p_user_id;
end;
$$;

create or replace function public.get_my_cash_reward_permission()
returns table (
  cash_rewards_enabled boolean,
  max_gross_cents_per_gift bigint
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    coalesce(p.cash_rewards_enabled, false),
    coalesce(p.max_gross_cents_per_gift, 100)::bigint
  from (select 1) seed
  left join public.staff_cash_reward_permissions p on p.user_id = auth.uid();
$$;

create or replace function public.get_owner_reward_control_summary()
returns table (
  reserve_gross_cents bigint,
  lifetime_allocated_gross_cents bigint,
  coins_per_usd integer,
  creator_share_bps integer,
  platform_share_bps integer
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
  if not exists (
    select 1 from public.account_roles r
    where r.user_id = auth.uid() and r.role = 'owner'
  ) then
    raise exception 'owner access required' using errcode = '42501';
  end if;

  return query
  select
    reserve.available_gross_cents,
    reserve.lifetime_allocated_gross_cents,
    cfg.coins_per_usd,
    cfg.creator_share_bps,
    cfg.platform_share_bps
  from public.cash_reward_reserve reserve
  cross join public.fameverse_economy_config cfg
  where reserve.id = true and cfg.id = true;
end;
$$;

create or replace function public._apply_creator_gift_share(
  p_gift_event_id uuid,
  p_source_type text
)
returns bigint
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_creator uuid;
  v_coins bigint;
  v_creator_bps integer;
  v_platform_bps integer;
  v_gross_micros bigint;
  v_creator_micros bigint;
  v_platform_micros bigint;
  v_remainder bigint;
  v_total_micros bigint;
  v_post_cents bigint;
begin
  if p_source_type not in ('operator_reward', 'paid_gift') then
    raise exception 'invalid gift earnings source' using errcode = '22023';
  end if;

  if exists (
    select 1 from public.creator_gift_share_accruals a
    where a.gift_event_id = p_gift_event_id
  ) then
    select a.creator_micros into v_creator_micros
    from public.creator_gift_share_accruals a
    where a.gift_event_id = p_gift_event_id;
    return v_creator_micros;
  end if;

  select g.recipient_user_id, g.coins_spent
    into v_creator, v_coins
  from public.gift_events g
  where g.id = p_gift_event_id;

  if v_creator is null or coalesce(v_coins, 0) <= 0 then
    raise exception 'gift event unavailable for earnings' using errcode = 'P0002';
  end if;

  select cfg.creator_share_bps, cfg.platform_share_bps
    into v_creator_bps, v_platform_bps
  from public.fameverse_economy_config cfg
  where cfg.id = true;

  -- 100 coins = $1, so one coin = one US cent = 10,000 USD micros.
  v_gross_micros := v_coins * 10000;
  v_creator_micros := (v_gross_micros * v_creator_bps) / 10000;
  v_platform_micros := v_gross_micros - v_creator_micros;

  insert into public.creator_gift_share_accruals (
    gift_event_id,
    creator_user_id,
    source_type,
    gross_coins,
    gross_micros,
    creator_share_bps,
    creator_micros,
    platform_micros
  ) values (
    p_gift_event_id,
    v_creator,
    p_source_type,
    v_coins,
    v_gross_micros,
    v_creator_bps,
    v_creator_micros,
    v_platform_micros
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
      creator_user_id,
      amount_cents,
      state,
      source_type,
      source_key,
      note,
      available_at
    ) values (
      v_creator,
      v_post_cents,
      'available',
      'gift_share',
      'gift_share:' || p_gift_event_id::text,
      case when p_source_type = 'operator_reward'
        then 'Cash-backed Fameverse owner/admin reward gift'
        else 'Creator share from paid Fameverse gift'
      end,
      now()
    );
  end if;

  return v_creator_micros;
end;
$$;

create or replace function public.record_beta_gift(
  p_room_id uuid,
  p_gift_id text,
  p_quantity integer
)
returns table (
  total_coins_sent bigint,
  gift_count bigint,
  level integer,
  wallet_balance bigint
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
  v_cash_enabled boolean := false;
  v_cash_cap bigint := 100;
  v_reserve bigint;
begin
  if v_sender is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  select r.role into v_sender_role
  from public.account_roles r
  where r.user_id = v_sender;

  -- Current beta law: only owner/admin accounts can expose and use the gift box.
  if coalesce(v_sender_role, '') not in ('owner', 'admin') then
    raise exception 'beta gift sending requires owner or admin role' using errcode = '42501';
  end if;

  if p_quantity is null or p_quantity < 1 or p_quantity > 100000 then
    raise exception 'invalid gift quantity' using errcode = '22023';
  end if;

  v_unit_cost := case p_gift_id
    when 'welcome-to-fameverse' then 100
    when 'ember-dragon' then 1000
    when 'celestial-phoenix' then 1000
    when 'pocket-comet' then 1000
    when 'rose' then 1
    when 'heart' then 1
    when 'fire' then 1
    when 'star' then 1
    when 'crown' then 1
    else null
  end;

  if v_unit_cost is null then
    raise exception 'unknown gift' using errcode = '22023';
  end if;

  select host_user_id into v_recipient
  from public.live_rooms
  where id = p_room_id
    and status = 'live'
    and ended_at is null;

  if v_recipient is null then
    raise exception 'live room is not active' using errcode = 'P0002';
  end if;

  if v_sender = v_recipient then
    raise exception 'self gifting is not allowed' using errcode = '42501';
  end if;

  v_total := v_unit_cost::bigint * p_quantity::bigint;

  select p.cash_rewards_enabled, p.max_gross_cents_per_gift
    into v_cash_enabled, v_cash_cap
  from public.staff_cash_reward_permissions p
  where p.user_id = v_sender;

  v_cash_enabled := coalesce(v_cash_enabled, false);
  v_cash_cap := coalesce(v_cash_cap, 100);

  if v_cash_enabled then
    if v_total > v_cash_cap then
      raise exception 'cash reward exceeds owner-approved gift cap' using errcode = '22023';
    end if;

    perform pg_advisory_xact_lock(hashtextextended('fameverse-cash-reward-reserve', 0));
    select available_gross_cents into v_reserve
    from public.cash_reward_reserve
    where id = true
    for update;

    if coalesce(v_reserve, 0) < v_total then
      raise exception 'cash reward reserve is too low for this gift' using errcode = '22003';
    end if;
  end if;

  select balance into v_balance
  from public.beta_coin_wallets
  where user_id = v_sender
  for update;

  if not found then
    raise exception 'beta wallet unavailable' using errcode = 'P0001';
  end if;

  if v_balance < v_total then
    raise exception 'insufficient beta coin balance' using errcode = 'P0001';
  end if;

  insert into public.gift_events (
    room_id,
    sender_user_id,
    recipient_user_id,
    gift_id,
    quantity,
    coins_spent
  ) values (
    p_room_id,
    v_sender,
    v_recipient,
    p_gift_id,
    p_quantity,
    v_total
  ) returning id into v_gift_event_id;

  update public.beta_coin_wallets
  set balance = balance - v_total,
      updated_at = now()
  where user_id = v_sender
  returning balance into v_balance;

  insert into public.beta_coin_ledger (
    user_id, delta, balance_after, event_type, gift_event_id
  ) values (
    v_sender, -v_total, v_balance, 'gift_send', v_gift_event_id
  );

  insert into public.gifter_stats (
    user_id, total_coins_sent, gift_count, level, updated_at
  ) values (
    v_sender,
    v_total,
    p_quantity,
    public.compute_gifter_level(v_total),
    now()
  )
  on conflict (user_id) do update set
    total_coins_sent = public.gifter_stats.total_coins_sent + excluded.total_coins_sent,
    gift_count = public.gifter_stats.gift_count + excluded.gift_count,
    level = public.compute_gifter_level(public.gifter_stats.total_coins_sent + excluded.total_coins_sent),
    updated_at = now();

  if v_cash_enabled then
    update public.cash_reward_reserve
    set available_gross_cents = available_gross_cents - v_total,
        lifetime_allocated_gross_cents = lifetime_allocated_gross_cents + v_total,
        updated_at = now(),
        updated_by = v_sender
    where id = true
    returning available_gross_cents into v_reserve;

    insert into public.cash_reward_reserve_ledger (
      delta_gross_cents,
      balance_after_gross_cents,
      event_type,
      gift_event_id,
      actor_user_id,
      note
    ) values (
      -v_total,
      v_reserve,
      'cash_reward_gift',
      v_gift_event_id,
      v_sender,
      'Cash-backed operator reward gift'
    );

    perform public._apply_creator_gift_share(v_gift_event_id, 'operator_reward');
  end if;

  return query
  select stats.total_coins_sent,
         stats.gift_count,
         stats.level,
         v_balance
  from public.gifter_stats stats
  where stats.user_id = v_sender;
end;
$$;

create or replace function public.owner_publish_update_notice(
  p_update_type text,
  p_title text,
  p_summary text,
  p_changelog text[] default '{}'::text[],
  p_requires_acknowledgement boolean default true
)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_owner uuid := auth.uid();
  v_notice_id uuid;
  v_type text := lower(trim(coalesce(p_update_type, 'backend')));
begin
  if not exists (
    select 1 from public.account_roles r
    where r.user_id = v_owner and r.role = 'owner'
  ) then
    raise exception 'owner access required' using errcode = '42501';
  end if;

  if v_type not in ('backend', 'app', 'maintenance', 'feature') then
    raise exception 'invalid update notice type' using errcode = '22023';
  end if;

  if char_length(trim(coalesce(p_title, ''))) < 1 then
    raise exception 'announcement title required' using errcode = '22023';
  end if;

  update public.app_update_notices
  set active = false
  where channel = 'internal' and active = true;

  insert into public.app_update_notices (
    channel,
    update_type,
    title,
    summary,
    version_label,
    build_number,
    changelog,
    active,
    requires_acknowledgement,
    published_at
  ) values (
    'internal',
    v_type,
    trim(p_title),
    coalesce(p_summary, ''),
    null,
    null,
    coalesce(p_changelog, '{}'::text[]),
    true,
    coalesce(p_requires_acknowledgement, true),
    now()
  ) returning id into v_notice_id;

  return v_notice_id;
end;
$$;

revoke all on function public.owner_allocate_reward_reserve(bigint, text) from public;
grant execute on function public.owner_allocate_reward_reserve(bigint, text) to authenticated;
revoke all on function public.owner_set_staff_cash_reward(uuid, boolean, bigint) from public;
grant execute on function public.owner_set_staff_cash_reward(uuid, boolean, bigint) to authenticated;
revoke all on function public.get_my_cash_reward_permission() from public;
grant execute on function public.get_my_cash_reward_permission() to authenticated;
revoke all on function public.get_owner_reward_control_summary() from public;
grant execute on function public.get_owner_reward_control_summary() to authenticated;
revoke all on function public._apply_creator_gift_share(uuid, text) from public;
revoke all on function public.record_beta_gift(uuid, text, integer) from public;
grant execute on function public.record_beta_gift(uuid, text, integer) to authenticated;
revoke all on function public.owner_publish_update_notice(text, text, text, text[], boolean) from public;
grant execute on function public.owner_publish_update_notice(text, text, text, text[], boolean) to authenticated;
