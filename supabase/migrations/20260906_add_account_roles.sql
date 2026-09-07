create table if not exists public.account_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('owner', 'admin')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.account_roles enable row level security;

drop policy if exists "account roles are publicly readable" on public.account_roles;
create policy "account roles are publicly readable"
on public.account_roles
for select
using (true);

revoke insert, update, delete on table public.account_roles from anon, authenticated;
grant select on table public.account_roles to anon, authenticated;
grant all on table public.account_roles to service_role;
