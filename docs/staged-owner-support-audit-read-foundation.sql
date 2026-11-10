-- REVIEW-ONLY PROPOSAL. This file deliberately lives in docs/, not migrations/.
-- NEVER APPLY TO FAMEVERSE PRODUCTION WITHOUT THE CEO'S EXPLICIT DDL/RLS APPROVAL.
-- Before activation: create an isolated Supabase branch, review cost, run
-- supabase migration new, move the reviewed SQL into that generated migration,
-- and verify owner, non-owner and anonymous session behavior.
--
-- This foundation links existing web support intake to protected owner case
-- and permanent audit records. No purchase/checkout, wallet, gift, payout,
-- coin ledger, or payment table is changed.

begin;

create table if not exists public.owner_cases (
  id uuid primary key default gen_random_uuid(),
  source_feedback_id uuid unique references public.beta_feedback(id) on delete set null,
  subject_user_id uuid references public.profiles(id) on delete set null,
  case_type text not null check (case_type in
    ('support','moderation','policy','appeal','gift_integrity','payout_review','badge_request','security','other')),
  status text not null default 'open' check (status in
    ('open','under_review','awaiting_member','resolved','closed')),
  summary text not null check (char_length(trim(summary)) between 3 and 500),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.owner_audit_events (
  id uuid primary key default gen_random_uuid(),
  actor_user_id uuid not null references auth.users(id),
  case_id uuid references public.owner_cases(id) on delete set null,
  section text not null check (char_length(trim(section)) between 2 and 64),
  operation text not null check (char_length(trim(operation)) between 2 and 64),
  target_type text check (char_length(trim(target_type)) between 2 and 64),
  target_id uuid,
  reason text not null check (char_length(trim(reason)) between 12 and 600),
  outcome text not null check (outcome in ('applied','rejected','reversed')),
  idempotency_key uuid unique,
  created_at timestamptz not null default now()
);

create index if not exists owner_cases_status_created_idx
  on public.owner_cases(status, created_at desc);
create index if not exists owner_cases_subject_created_idx
  on public.owner_cases(subject_user_id, created_at desc);
create index if not exists owner_audit_events_created_idx
  on public.owner_audit_events(created_at desc);
create index if not exists owner_audit_events_case_idx
  on public.owner_audit_events(case_id, created_at desc);

alter table public.owner_cases enable row level security;
alter table public.owner_audit_events enable row level security;

-- Public/anonymous callers get no access; authenticated clients get SELECT
-- only, and row filtering independently checks authoritative account_roles.
revoke all on public.owner_cases from public, anon, authenticated;
revoke all on public.owner_audit_events from public, anon, authenticated;
grant select on public.owner_cases to authenticated;
grant select on public.owner_audit_events to authenticated;

drop policy if exists "Owner-only case read" on public.owner_cases;
create policy "Owner-only case read"
  on public.owner_cases for select to authenticated
  using (exists (
    select 1 from public.account_roles r
    where r.user_id = (select auth.uid()) and r.role = 'owner'
  ));

drop policy if exists "Owner-only persistent audit read" on public.owner_audit_events;
create policy "Owner-only persistent audit read"
  on public.owner_audit_events for select to authenticated
  using (exists (
    select 1 from public.account_roles r
    where r.user_id = (select auth.uid()) and r.role = 'owner'
  ));

-- Existing beta_feedback contains user-submitted web support messages.
-- Members retain their own existing SELECT rights. This additional owner
-- policy allows only authenticated owners to read actual web support intake.
drop policy if exists "Owner reads web support intake" on public.beta_feedback;
create policy "Owner reads web support intake"
  on public.beta_feedback for select to authenticated
  using (
    current_screen = 'web_support'
    and exists (
      select 1 from public.account_roles r
      where r.user_id = (select auth.uid()) and r.role = 'owner'
    )
  );

-- No client insert, update or delete on owner_cases/owner_audit_events.
-- Administrative writes need a separately reviewed, atomic, audited,
-- server-authorized implementation. Client preview_actions remain no-op.
commit;
