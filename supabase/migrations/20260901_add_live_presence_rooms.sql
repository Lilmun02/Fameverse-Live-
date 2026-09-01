create table public.live_rooms (
  id uuid primary key default gen_random_uuid(),
  host_user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  status text not null default 'live',
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  heartbeat_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint live_rooms_title_length check (char_length(btrim(title)) between 1 and 120),
  constraint live_rooms_status_check check (status in ('live', 'ended')),
  constraint live_rooms_end_state_check check (
    (status = 'live' and ended_at is null)
    or (status = 'ended' and ended_at is not null)
  )
);

create unique index live_rooms_one_active_per_host
  on public.live_rooms (host_user_id)
  where status = 'live';

create index live_rooms_active_heartbeat_idx
  on public.live_rooms (status, heartbeat_at desc);

alter table public.live_rooms enable row level security;

create policy "authenticated users can read active live rooms or own history"
on public.live_rooms
for select
to authenticated
using (status = 'live' or auth.uid() = host_user_id);

create policy "hosts can create own live room"
on public.live_rooms
for insert
to authenticated
with check (
  auth.uid() = host_user_id
  and status = 'live'
  and ended_at is null
);

create policy "hosts can update own live room"
on public.live_rooms
for update
to authenticated
using (auth.uid() = host_user_id)
with check (auth.uid() = host_user_id);
