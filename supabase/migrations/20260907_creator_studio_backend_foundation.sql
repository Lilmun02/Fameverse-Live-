-- Fameverse Creator Studio backend foundation.
-- Persistent Live drafts/history + gift activity + beta 3-mod server limit.

alter table public.live_rooms
  add column if not exists goal text not null default '',
  add column if not exists wishlist_gift_ids text[] not null default '{}'::text[];

do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'live_rooms_goal_length_check'
  ) then
    alter table public.live_rooms
      add constraint live_rooms_goal_length_check
      check (char_length(goal) <= 280);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'live_rooms_wishlist_limit_check'
  ) then
    alter table public.live_rooms
      add constraint live_rooms_wishlist_limit_check
      check (cardinality(wishlist_gift_ids) <= 10);
  end if;
end $$;

create table if not exists public.creator_live_drafts (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  title text not null default '',
  goal text not null default '',
  wishlist_gift_ids text[] not null default '{}'::text[],
  updated_at timestamptz not null default now(),
  constraint creator_live_drafts_title_length_check check (char_length(title) <= 120),
  constraint creator_live_drafts_goal_length_check check (char_length(goal) <= 280),
  constraint creator_live_drafts_wishlist_limit_check check (cardinality(wishlist_gift_ids) <= 10)
);

alter table public.creator_live_drafts enable row level security;

drop policy if exists "creators can read own live draft" on public.creator_live_drafts;
create policy "creators can read own live draft"
on public.creator_live_drafts for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "creators can create own live draft" on public.creator_live_drafts;
create policy "creators can create own live draft"
on public.creator_live_drafts for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "creators can update own live draft" on public.creator_live_drafts;
create policy "creators can update own live draft"
on public.creator_live_drafts for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);

drop policy if exists "creators can delete own live draft" on public.creator_live_drafts;
create policy "creators can delete own live draft"
on public.creator_live_drafts for delete
to authenticated
using (auth.uid() = user_id);

create table if not exists public.creator_moderators (
  creator_user_id uuid not null references public.profiles(id) on delete cascade,
  moderator_user_id uuid not null references public.profiles(id) on delete cascade,
  assigned_at timestamptz not null default now(),
  primary key (creator_user_id, moderator_user_id),
  constraint creator_moderators_not_self_check check (creator_user_id <> moderator_user_id)
);

create index if not exists creator_moderators_moderator_idx
  on public.creator_moderators(moderator_user_id, assigned_at desc);

alter table public.creator_moderators enable row level security;

drop policy if exists "creator moderator assignments are visible to participants" on public.creator_moderators;
create policy "creator moderator assignments are visible to participants"
on public.creator_moderators for select
to authenticated
using (auth.uid() = creator_user_id or auth.uid() = moderator_user_id);

create or replace function public.set_creator_moderator(
  p_moderator_user_id uuid,
  p_enabled boolean
)
returns table (
  active_count integer,
  is_moderator boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_creator uuid := auth.uid();
  v_count integer;
begin
  if v_creator is null then
    raise exception 'authentication required' using errcode = '42501';
  end if;

  if p_moderator_user_id is null or p_moderator_user_id = v_creator then
    raise exception 'invalid moderator account' using errcode = '22023';
  end if;

  if not exists (select 1 from public.profiles where id = p_moderator_user_id) then
    raise exception 'moderator account not found' using errcode = 'P0002';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(v_creator::text, 0));

  if coalesce(p_enabled, false) then
    if not exists (
      select 1 from public.creator_moderators
      where creator_user_id = v_creator
        and moderator_user_id = p_moderator_user_id
    ) then
      select count(*)::integer into v_count
      from public.creator_moderators
      where creator_user_id = v_creator;

      if v_count >= 3 then
        raise exception 'beta moderator limit is 3' using errcode = 'P0001';
      end if;

      insert into public.creator_moderators (creator_user_id, moderator_user_id)
      values (v_creator, p_moderator_user_id);
    end if;
  else
    delete from public.creator_moderators
    where creator_user_id = v_creator
      and moderator_user_id = p_moderator_user_id;
  end if;

  select count(*)::integer into v_count
  from public.creator_moderators
  where creator_user_id = v_creator;

  return query
  select
    v_count,
    exists (
      select 1 from public.creator_moderators
      where creator_user_id = v_creator
        and moderator_user_id = p_moderator_user_id
    );
end;
$$;

create or replace function public.get_creator_live_history(p_limit integer default 20)
returns table (
  room_id uuid,
  title text,
  goal text,
  wishlist_gift_ids text[],
  status text,
  started_at timestamptz,
  ended_at timestamptz,
  raw_taps bigint,
  gift_count bigint,
  gift_coins bigint
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    room.id as room_id,
    room.title,
    room.goal,
    room.wishlist_gift_ids,
    room.status,
    room.started_at,
    room.ended_at,
    coalesce(taps.raw_taps, 0)::bigint as raw_taps,
    coalesce(gifts.gift_count, 0)::bigint as gift_count,
    coalesce(gifts.gift_coins, 0)::bigint as gift_coins
  from public.live_rooms room
  left join public.live_tap_totals taps on taps.room_id = room.id
  left join lateral (
    select
      coalesce(sum(event.quantity), 0)::bigint as gift_count,
      coalesce(sum(event.coins_spent), 0)::bigint as gift_coins
    from public.gift_events event
    where event.room_id = room.id
      and event.recipient_user_id = auth.uid()
  ) gifts on true
  where room.host_user_id = auth.uid()
  order by room.started_at desc
  limit least(greatest(coalesce(p_limit, 20), 1), 100);
$$;

create or replace function public.get_creator_gift_activity(p_limit integer default 50)
returns table (
  gift_event_id uuid,
  room_id uuid,
  sender_user_id uuid,
  sender_display_name text,
  gift_id text,
  quantity integer,
  coins_spent bigint,
  created_at timestamptz
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    event.id as gift_event_id,
    event.room_id,
    event.sender_user_id,
    coalesce(profile.display_name, profile.username, 'Fameverse User') as sender_display_name,
    event.gift_id,
    event.quantity,
    event.coins_spent,
    event.created_at
  from public.gift_events event
  left join public.profiles profile on profile.id = event.sender_user_id
  where event.recipient_user_id = auth.uid()
  order by event.created_at desc
  limit least(greatest(coalesce(p_limit, 50), 1), 200);
$$;

revoke all privileges on table public.creator_live_drafts from anon;
revoke all privileges on table public.creator_moderators from anon, authenticated;
grant select, insert, update, delete on table public.creator_live_drafts to authenticated;
grant select on table public.creator_moderators to authenticated;

revoke all on function public.set_creator_moderator(uuid, boolean) from public;
grant execute on function public.set_creator_moderator(uuid, boolean) to authenticated;
revoke all on function public.get_creator_live_history(integer) from public;
grant execute on function public.get_creator_live_history(integer) to authenticated;
revoke all on function public.get_creator_gift_activity(integer) from public;
grant execute on function public.get_creator_gift_activity(integer) to authenticated;
