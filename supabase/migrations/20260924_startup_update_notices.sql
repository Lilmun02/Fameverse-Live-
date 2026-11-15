create table if not exists public.app_update_notices (
  id uuid primary key default gen_random_uuid(),
  channel text not null default 'internal' check (channel in ('internal', 'beta', 'production')),
  update_type text not null default 'backend' check (update_type in ('backend', 'app', 'maintenance', 'feature')),
  title text not null,
  summary text not null default '',
  version_label text,
  build_number integer,
  changelog text[] not null default '{}',
  active boolean not null default false,
  requires_acknowledgement boolean not null default true,
  published_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  unique (channel, version_label, update_type)
);

alter table public.app_update_notices enable row level security;

drop policy if exists "active update notices are readable" on public.app_update_notices;
create policy "active update notices are readable"
on public.app_update_notices
for select
to anon, authenticated
using (active = true);

grant select on public.app_update_notices to anon, authenticated;

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
)
values (
  'internal',
  'backend',
  'Fameverse services updated',
  'Build 16 services are synced and ready for internal testing.',
  '0.2.0',
  16,
  array[
    'Fame Coin purchase sandbox is ready for internal QA',
    'Creator Studio payout sandbox is available for owner testing',
    'Profile experience refreshed',
    'Live sessions now keep the display awake while active'
  ]::text[],
  true,
  true,
  now()
)
on conflict (channel, version_label, update_type)
do update set
  title = excluded.title,
  summary = excluded.summary,
  build_number = excluded.build_number,
  changelog = excluded.changelog,
  active = excluded.active,
  requires_acknowledgement = excluded.requires_acknowledgement,
  published_at = excluded.published_at;
