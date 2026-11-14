-- Build 47 policy gate: protect live hosting from direct Data API calls.
-- Authorized scope: only policy access checks on existing live_rooms RLS.
-- Keep existing ownership, live status and room-end cleanup semantics.
-- Compatibility: accounts with NO notice row still use existing permissions
-- until Build 47 displays/registers their individual 7+3-day notice.
create or replace function public.fv_policy_allows_restricted()
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select (select auth.uid()) is not null
    and (
      not exists (
        select 1
        from public.policy_acceptances as p
        where p.user_id = (select auth.uid())
          and p.policy_version = '2026-10'
      )
      or exists (
        select 1
        from public.policy_acceptances as p
        where p.user_id = (select auth.uid())
          and p.policy_version = '2026-10'
          and (
            p.decision = 'accepted'
            or (
              p.decision = 'unsigned'
              and now() < p.notice_started_at + interval '10 days'
            )
          )
      )
    );
$$;

revoke all on function public.fv_policy_allows_restricted()
from public, anon, authenticated;
grant execute on function public.fv_policy_allows_restricted()
to authenticated;

alter policy "hosts can create own live room"
on public.live_rooms
to authenticated
with check (
  (select auth.uid()) = host_user_id
  and status = 'live'
  and ended_at is null
  and (select public.fv_policy_allows_restricted())
);

alter policy "hosts can update own live room"
on public.live_rooms
to authenticated
using ((select auth.uid()) = host_user_id)
with check (
  (select auth.uid()) = host_user_id
  and (
    status <> 'live'
    or (select public.fv_policy_allows_restricted())
  )
);

-- Re-run verification after applying:
-- 1) accepted -> true immediately; declined -> false immediately;
-- 2) unsigned + notice < 10 days -> true; expired -> false;
-- 3) no notice -> true for backward compatibility;
-- 4) status=ended updates permitted to let hosts leave rooms.
-- This does not touch Stripe/Apple IAP/creator payout code.
