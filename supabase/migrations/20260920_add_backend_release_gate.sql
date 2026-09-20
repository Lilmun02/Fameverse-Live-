create table if not exists public.app_release_state (
  channel text primary key,
  backend_revision bigint not null default 1 check (backend_revision >= 1),
  release_label text not null default 'backend',
  updated_at timestamptz not null default now()
);

insert into public.app_release_state (channel, backend_revision, release_label)
values ('pwa', 1, 'backend-release-gate')
on conflict (channel) do nothing;

alter table public.app_release_state enable row level security;

drop policy if exists "public can read app release state" on public.app_release_state;
create policy "public can read app release state"
on public.app_release_state for select
to anon, authenticated
using (true);

revoke all privileges on table public.app_release_state from anon, authenticated;
grant select on public.app_release_state to anon, authenticated;
