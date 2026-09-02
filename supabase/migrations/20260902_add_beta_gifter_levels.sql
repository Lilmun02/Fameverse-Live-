create or replace function public.compute_gifter_level(p_total_coins bigint)
returns integer
language sql
immutable
as $$
  select least(99, greatest(1, floor(sqrt(greatest(p_total_coins, 0)::numeric / 100))::integer + 1));
$$;

create table if not exists public.gifter_stats (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  total_coins_sent bigint not null default 0 check (total_coins_sent >= 0),
  gift_count bigint not null default 0 check (gift_count >= 0),
  level integer not null default 1 check (level between 1 and 99),
  updated_at timestamptz not null default now()
);

create table if not exists public.gift_events (
  id uuid primary key default gen_random_uuid(),
  room_id uuid not null references public.live_rooms(id) on delete cascade,
  sender_user_id uuid not null references public.profiles(id) on delete cascade,
  recipient_user_id uuid not null references public.profiles(id) on delete cascade,
  gift_id text not null,
  quantity integer not null check (quantity between 1 and 1000),
  coins_spent bigint not null check (coins_spent >= 0),
  created_at timestamptz not null default now()
);

create index if not exists gift_events_sender_created_idx on public.gift_events(sender_user_id, created_at desc);
create index if not exists gift_events_recipient_created_idx on public.gift_events(recipient_user_id, created_at desc);
create index if not exists gift_events_room_created_idx on public.gift_events(room_id, created_at desc);

alter table public.gifter_stats enable row level security;
alter table public.gift_events enable row level security;

drop policy if exists "gifter levels are publicly readable" on public.gifter_stats;
create policy "gifter levels are publicly readable"
on public.gifter_stats for select
to public
using (true);

drop policy if exists "users can read related beta gift events" on public.gift_events;
create policy "users can read related beta gift events"
on public.gift_events for select
to authenticated
using (auth.uid() = sender_user_id or auth.uid() = recipient_user_id);

create or replace function public.record_beta_gift(
  p_room_id uuid,
  p_gift_id text,
  p_quantity integer
)
returns table (
  total_coins_sent bigint,
  gift_count bigint,
  level integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_sender uuid := auth.uid();
  v_recipient uuid;
  v_unit_cost integer;
  v_total bigint;
begin
  if v_sender is null then raise exception 'authentication required'; end if;
  if p_quantity is null or p_quantity < 1 or p_quantity > 1000 then raise exception 'invalid gift quantity'; end if;

  v_unit_cost := case p_gift_id
    when 'welcome-to-fameverse' then 100
    when 'rose' then 1
    when 'heart' then 1
    when 'fire' then 1
    when 'star' then 1
    when 'crown' then 1
    else null
  end;

  if v_unit_cost is null then raise exception 'unknown gift'; end if;

  select host_user_id into v_recipient
  from public.live_rooms
  where id = p_room_id and status = 'live' and ended_at is null;

  if v_recipient is null then raise exception 'live room is not active'; end if;

  v_total := v_unit_cost::bigint * p_quantity::bigint;

  insert into public.gift_events (room_id, sender_user_id, recipient_user_id, gift_id, quantity, coins_spent)
  values (p_room_id, v_sender, v_recipient, p_gift_id, p_quantity, v_total);

  insert into public.gifter_stats (user_id, total_coins_sent, gift_count, level, updated_at)
  values (v_sender, v_total, p_quantity, public.compute_gifter_level(v_total), now())
  on conflict (user_id) do update set
    total_coins_sent = public.gifter_stats.total_coins_sent + excluded.total_coins_sent,
    gift_count = public.gifter_stats.gift_count + excluded.gift_count,
    level = public.compute_gifter_level(public.gifter_stats.total_coins_sent + excluded.total_coins_sent),
    updated_at = now();

  return query
  select s.total_coins_sent, s.gift_count, s.level
  from public.gifter_stats s
  where s.user_id = v_sender;
end;
$$;

revoke all on function public.record_beta_gift(uuid, text, integer) from public;
grant execute on function public.record_beta_gift(uuid, text, integer) to authenticated;
grant select on public.gifter_stats to anon, authenticated;
grant select on public.gift_events to authenticated;
