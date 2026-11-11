-- Build 47 policy decisions + per-account 7-day notice and 3-day grace.
-- Exact 10-day window starts on the first authenticated notice record.
-- This migration does not touch purchases, payouts, existing awards, or users.
create table if not exists public.policy_acceptances (
  user_id uuid not null references auth.users(id) on delete cascade,
  policy_version text not null
    check (length(trim(policy_version)) between 1 and 64),
  decision text not null default 'unsigned'
    check (decision in ('unsigned', 'accepted', 'declined')),
  notice_started_at timestamptz not null default now(),
  decided_at timestamptz,
  primary key (user_id, policy_version)
);

alter table public.policy_acceptances enable row level security;
revoke all on public.policy_acceptances from public, anon, authenticated;
grant select, insert, update on public.policy_acceptances to authenticated;

create policy "Account owner reads policy decision"
on public.policy_acceptances for select to authenticated
using ((select auth.uid()) = user_id);

create policy "Account owner starts policy notice"
on public.policy_acceptances for insert to authenticated
with check ((select auth.uid()) = user_id);

create policy "Account owner submits policy decision"
on public.policy_acceptances for update to authenticated
using ((select auth.uid()) = user_id)
with check ((select auth.uid()) = user_id);

-- Never trust client-submitted clock timestamps or an attempt to reset
-- the irreversible first-notice date. Owner support can review accounts.
create or replace function public.fv_policy_decision_timestamp()
returns trigger language plpgsql set search_path = '' as $$
begin
  if tg_op = 'INSERT' then
    new.notice_started_at := now();
  else
    new.notice_started_at := old.notice_started_at;
    if old.decision in ('accepted', 'declined')
       and new.decision = 'unsigned' then
      raise exception 'Policy decision cannot be reset by the app';
    end if;
    if old.decision = 'unsigned' and new.decision = 'accepted'
       and now() >= old.notice_started_at + interval '10 days' then
      raise exception 'Policy deadline passed: contact Fameverse support Monday-Friday';
    end if;
  end if;
  if new.decision = 'unsigned' then
    new.decided_at := null;
  else
    new.decided_at := now();
  end if;
  return new;
end;
$$;

revoke all on function public.fv_policy_decision_timestamp()
  from public, anon, authenticated;

create trigger fv_policy_decision_timestamp_before_write
before insert or update on public.policy_acceptances
for each row execute function public.fv_policy_decision_timestamp();

-- Security-invoker RPC: returns only the authenticated caller's own
-- row. Server time, not the device clock, determines restriction phase.
create or replace function public.get_my_fameverse_policy_status(
  p_policy_version text
)
returns table (
  user_id uuid,
  policy_version text,
  decision text,
  notice_started_at timestamptz,
  grace_starts_at timestamptz,
  notice_ends_at timestamptz,
  server_now timestamptz,
  can_use_restricted boolean,
  requires_support boolean,
  phase text
)
language sql stable security invoker set search_path = '' as $$
  select
    p.user_id,
    p.policy_version,
    p.decision,
    p.notice_started_at,
    p.notice_started_at + interval '7 days',
    p.notice_started_at + interval '10 days',
    now(),
    (
      p.decision = 'accepted'
      or (
        p.decision = 'unsigned'
        and now() < p.notice_started_at + interval '10 days'
      )
    ),
    (
      p.decision = 'unsigned'
      and now() >= p.notice_started_at + interval '10 days'
    ),
    case
      when p.decision = 'accepted' then 'accepted'
      when p.decision = 'declined' then 'declined'
      when now() >= p.notice_started_at + interval '10 days'
        then 'expired'
      when now() >= p.notice_started_at + interval '7 days'
        then 'grace'
      else 'notice'
    end
  from public.policy_acceptances as p
  where p.user_id = (select auth.uid())
    and p.policy_version = p_policy_version;
$$;

revoke all on function public.get_my_fameverse_policy_status(text)
  from public, anon, authenticated;
grant execute on function public.get_my_fameverse_policy_status(text)
  to authenticated;

-- Deliberate limitation: existing Live/Stripe server entrypoints are
-- unchanged. They must check policy access at the backend before claiming
-- that a malicious/repackaged client cannot bypass restricted features.
