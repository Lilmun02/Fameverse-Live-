# Native Inbox backend — gated rollout

**Status:** review-only specification. No production migration has been applied. The native screen on this branch intentionally fails visibly when the backend is missing; do not distribute it as complete.

The Inbox is private to the signed-in user. It is separate from notification permission prompts, which are on hold.

## Proposed schema (not yet deployed)

```sql
create table public.user_inbox_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (length(title) between 1 and 160),
  body text not null default '' check (length(body) <= 2000),
  created_at timestamptz not null default now()
);
create index user_inbox_items_owner_recent
  on public.user_inbox_items (user_id, created_at desc);

alter table public.user_inbox_items enable row level security;
revoke all on public.user_inbox_items from anon, authenticated;
grant select on public.user_inbox_items to authenticated;

create policy inbox_owner_read
  on public.user_inbox_items
  for select to authenticated
  using (user_id = (select auth.uid()));
```

Never grant clients INSERT, UPDATE, or DELETE on other people's inbox records. Service-side delivery requires a separately reviewed sender/trigger and may never expose a service-role key to the mobile app.

## Before feature approval

1. Review and generate a proper Supabase CLI migration; do not execute this document as an ad hoc production change.
2. Verify the Data API grant and RLS with two authenticated accounts, including denial of cross-account SELECT and INSERT.
3. Exercise native empty, populated, refresh, account-switch and offline states on physical iOS.
4. Wire only user-authorized inbox content. An empty database is not a working notification delivery system.
5. Keep the web-only Owner Panel Control and held notification permissions out of this mobile change.
