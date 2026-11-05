-- Policy decision records. REVIEW ONLY: do not apply to production
-- until policy text/version, enforcement points and rollout are approved.
create table if not exists public.policy_acceptances (
  user_id uuid not null references auth.users(id) on delete cascade,
  policy_version text not null check (length(trim(policy_version)) between 1 and 64),
  decision text not null check (decision in ('accepted', 'declined')),
  decided_at timestamptz not null default now(),
  primary key (user_id, policy_version)
);

alter table public.policy_acceptances enable row level security;

revoke all on public.policy_acceptances from anon;
grant select, insert, update on public.policy_acceptances to authenticated;

create policy "Account owner reads policy decision"
on public.policy_acceptances for select to authenticated
using ((select auth.uid()) = user_id);

create policy "Account owner submits policy decision"
on public.policy_acceptances for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "Account owner changes policy decision"
on public.policy_acceptances for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- Always set a server timestamp, including when a decision is changed.
create or replace function public.fv_policy_decision_timestamp()
returns trigger language plpgsql set search_path = '' as $$
begin
  new.decided_at := now();
  return new;
end;
$$;

create trigger fv_policy_decision_timestamp_before_write
before insert or update on public.policy_acceptances
for each row execute function public.fv_policy_decision_timestamp();

-- Important: this table does not by itself secure livestream or purchases.
-- Sensitive backend entrypoints must verify accepted decision/version.
