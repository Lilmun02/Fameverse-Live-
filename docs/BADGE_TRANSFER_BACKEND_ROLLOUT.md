# Bring Your Badge — manual review backend contract

**Status:** review-only specification. The request table and web review workflow are not deployed. Do not distribute the request form as functional until both exist.

Users submit source-app **badge evidence**. This is not an exchange for Fameverse levels, test coins, gifts, privileges, or identity verification. Everyone starts at Fameverse level zero. **Owner Panel Control** and the reviewer queue stay on the web.

## Proposed schema (not yet deployed)

```sql
create table public.badge_transfer_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_platform text not null check (source_platform in ('TikTok', 'Favorited', 'Epic')),
  source_level integer not null check (source_level between 1 and 100),
  proof_url text not null check (
    length(proof_url) <= 2048 and proof_url ~ '^https://[^[:space:]]+$'
  ),
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  reviewed_at timestamptz,
  reviewed_by uuid,
  review_notes text
);
create unique index badge_transfer_one_pending_per_source
  on public.badge_transfer_requests (user_id, source_platform)
  where status = 'pending';

alter table public.badge_transfer_requests enable row level security;
revoke all on public.badge_transfer_requests from anon, authenticated;
grant select on public.badge_transfer_requests to authenticated;
grant insert (user_id, source_platform, source_level, proof_url)
  on public.badge_transfer_requests to authenticated;

create policy badge_transfer_owner_read
  on public.badge_transfer_requests
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy badge_transfer_owner_submit
  on public.badge_transfer_requests
  for insert to authenticated
  with check (
    user_id = (select auth.uid()) and
    status = 'pending' and
    reviewed_at is null and reviewed_by is null and review_notes is null
  );
```

Authenticated mobile users get **no UPDATE or DELETE grant**. An owner-only web server route, verifying the owner role on the server, must review evidence and update request status. Do not publish a service-role key or trust editable user_metadata for authorization.

## Before feature approval

1. Generate and review the real migration with the Supabase CLI; confirm RLS and column privileges with two separate authenticated accounts.
2. Verify invalid platform, non-HTTPS proof, duplicate pending submissions, and forged approval/status update attempts are rejected server-side.
3. Build the authenticated reviewer queue in the web-only Owner Panel Control; verify evidence before approval.
4. Define a secure screenshot-upload flow, including Storage RLS and file limits; this branch currently accepts HTTPS evidence links only.
5. Test iPhone form submission, pending status, failed/offline requests, and a rejected resubmission end to end.
6. Confirm database review status cannot award coins, increase a Fameverse user level, or bypass First Verse.
